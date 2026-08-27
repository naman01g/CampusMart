import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _workerBaseUrl =
      'https://campusmart-notifications.onenightprep-payment.workers.dev';
  static const String _sendEndpoint = '/send-notification';

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  /// Gets a fresh Firebase ID token for the authenticated user.
  ///
  /// This token is verified by the Cloudflare Worker, so the client never
  /// ships a shared secret. The Worker derives the authenticated UID from the
  /// verified token rather than trusting a client-supplied value.
  Future<String> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to obtain Firebase ID token');
    }
    return idToken;
  }

  /// Sends a push notification via the Cloudflare Worker.
  /// This is fire-and-forget - failures don't block the chat message.
  Future<void> sendChatNotification({
    required String recipientId,
    required String chatId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    required String productTitle,
    required String recipientRole,
  }) async {
    // Don't send notification to self
    if (senderId == recipientId) return;

    try {
      final idToken = await _getIdToken();

      final payload = {
        'recipientId': recipientId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'messagePreview': messagePreview,
        'productTitle': productTitle,
        'recipientRole': recipientRole,
      };

      debugPrint(
        '[Notification] Sending push to recipient ${recipientId.substring(0, recipientId.length > 6 ? 6 : recipientId.length)}...',
      );

      final response = await http
          .post(
            Uri.parse('$_workerBaseUrl$_sendEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint(
            '[Notification] Push sent successfully (count: ${data['sentCount']})',
          );
        } else {
          debugPrint('[Notification] Push failed: ${data['error']}');
        }
      } else if (response.statusCode == 401) {
        debugPrint(
          '[Notification] Worker auth failed (401) - Firebase ID token rejected',
        );
      } else if (response.statusCode == 404) {
        debugPrint(
          '[Notification] No FCM tokens for recipient or recipient not found (404)',
        );
      } else {
        debugPrint(
          '[Notification] Worker error: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Non-blocking: log but don't throw
      debugPrint('[Notification] Failed to send push (non-blocking): $e');
    }
  }

  /// Checks if the worker is healthy.
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_workerBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
