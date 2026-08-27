import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/firebase/firebase_config.dart';
import 'package:campusmart_mobile/core/firebase/fcm_service.dart';
import 'package:campusmart_mobile/core/theme/app_theme.dart';
import 'package:campusmart_mobile/core/router/app_router.dart';
import 'package:campusmart_mobile/features/updates/presentation/providers/update_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final fcmService = FcmService();
  await fcmService.initialize();

  // Listen for notification taps and navigate to chat
  notificationTapStream.stream.listen((chatId) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      debugPrint('[FCM] Navigating to chat: $chatId');
      GoRouter.of(ctx).push('/chat/$chatId');
    } else {
      debugPrint('[FCM] Navigator context null, cannot navigate to chat');
    }
  });

  runApp(const ProviderScope(child: CampusMartApp()));
}

class CampusMartApp extends ConsumerStatefulWidget {
  const CampusMartApp({super.key});

  @override
  ConsumerState<CampusMartApp> createState() => _CampusMartAppState();
}

class _CampusMartAppState extends ConsumerState<CampusMartApp> {
  @override
  void initState() {
    super.initState();
    // After the first frame the global navigator is available, so kick off the
    // one-shot in-app update check. Failures are swallowed internally.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateControllerProvider).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CampusMart',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
