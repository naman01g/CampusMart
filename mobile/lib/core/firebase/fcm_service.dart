import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Stream for notification tap events (chatId to navigate to).
final notificationTapStream = StreamController<String>.broadcast();

/// The id of the conversation the user is currently viewing, or null if they
/// are not inside a chat. Used to suppress notifications for the exact chat
/// the user is actively looking at (they already see the new message inline).
String? activeConversationId;

/// Marks the conversation the user is currently viewing. While [chatId] is
/// set, incoming push notifications for that exact conversation are suppressed.
void setActiveConversation(String chatId) {
  activeConversationId = chatId;
  debugPrint('[FCM] Active conversation set: $chatId');
}

/// Clears the active-conversation marker when the user leaves the chat.
void clearActiveConversation() {
  activeConversationId = null;
  debugPrint('[FCM] Active conversation cleared');
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const String _chatChannelId = 'campusmart_chat';
const String _chatChannelName = 'CampusMart Chat';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  /// The most recent FCM token this app instance persisted, so it can be
  /// removed when Firebase rotates the token (prevents stale accumulation).
  String? _lastStoredToken;

  /// Initializes FCM: requests permission, gets token, sets up listeners.
  Future<void> initialize() async {
    // 1. Create notification channel and initialize local notifications
    await _initLocalNotifications();

    // 2. Request notification permission
    await _requestPermission();

    // 3. Get and store initial FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] token registered');
      await _storeToken(token);
      _lastStoredToken = token;
    } else {
      debugPrint('[FCM] WARNING: Initial token is null');
    }

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // 5. Handle foreground messages - show as local notification
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 7. Handle initial message if app was opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handles Firebase token rotation: removes the previous token for this
  /// device so stale tokens do not accumulate, then stores the new token.
  Future<void> _handleTokenRefresh(String newToken) async {
    final oldToken = _lastStoredToken;
    if (oldToken != null && oldToken != newToken) {
      await removeTokenFromCurrentUser(oldToken);
      debugPrint('[FCM] token removed (old)');
    }
    debugPrint('[FCM] token refreshed');
    await _storeToken(newToken);
    _lastStoredToken = newToken;
  }

  /// Creates the Android notification channel and initializes local notifications.
  Future<void> _initLocalNotifications() async {
    // Android notification channel
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _chatChannelId,
        _chatChannelName,
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('[FCM] Notification channel created: $_chatChannelId');
    }

    // Initialize the local notifications plugin
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle foreground notification tap
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('[FCM] Foreground notification tapped: $payload');
          notificationTapStream.add(payload);
        }
      },
    );

    debugPrint('[FCM] Local notifications initialized');
  }

  Future<void> _requestPermission() async {
    // Request Android 13+ runtime permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPermission = await Permission.notification.request();
      debugPrint(
        '[FCM] Android POST_NOTIFICATIONS permission: $androidPermission',
      );
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] FCM permission status: ${settings.authorizationStatus}');
  }

  /// Handles messages received while the app is in the foreground.
  /// The OS does NOT show system notifications for foreground messages,
  /// so we must show a local notification manually.
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[FCM] Foreground message received: ${message.notification?.title}',
    );
    debugPrint('[FCM] Message data: ${message.data}');

    final notification = message.notification;
    if (notification == null) return;

    final chatId = message.data['chatId'] ?? '';

    // Suppress the notification when the user is actively viewing this exact
    // conversation - the new message is already visible in their chat, so a
    // fresh system notification would be redundant and annoying.
    if (chatId.isNotEmpty && chatId == activeConversationId) {
      debugPrint(
        '[FCM] Suppressed notification for active conversation: $chatId',
      );
      return;
    }

    // Show a local notification for foreground messages
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chatChannelId,
          _chatChannelName,
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFCC8B26),
        ),
      ),
      payload: chatId,
    );

    debugPrint('[FCM] Foreground notification displayed locally');
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Background notification tapped');
    _handleNotificationTap(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId != null && chatId.toString().isNotEmpty) {
      notificationTapStream.add(chatId.toString());
    }
  }

  /// Stores the FCM token in the current user's Firestore document.
  ///
  /// Uses `arrayUnion` so an exact duplicate is never added; a user may have
  /// multiple devices, so other valid device tokens are preserved.
  Future<void> _storeToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] No authenticated user, skipping token storage');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _lastStoredToken = token;
      debugPrint('[FCM] token registered');
    } catch (e) {
      debugPrint('[FCM] Failed to store token (non-blocking): $e');
    }
  }

  /// Fetches the current FCM token and stores it against the authenticated
  /// user. Called once a user session is established, so the token is always
  /// associated with the correct UID regardless of when the app started.
  Future<void> storeTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] No authenticated user, skipping token persistence');
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to persist token for user ${user.uid}: $e');
    }
  }

  /// Removes a specific FCM token for the current user (e.g. on token
  /// rotation or invalidation). Other device tokens are preserved.
  Future<void> removeTokenFromCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (_lastStoredToken == token) {
        _lastStoredToken = null;
      }
      debugPrint('[FCM] token removed');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token (non-blocking): $e');
    }
  }

  /// Clears all FCM tokens for the current user (e.g., on logout).
  Future<void> clearAllTokens() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] All tokens cleared');
    } catch (e) {
      debugPrint('[FCM] Failed to clear tokens: $e');
    }
  }

  /// Gets the current FCM token without storing it.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribes to a topic (optional, for broadcast notifications).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void dispose() {}
}
