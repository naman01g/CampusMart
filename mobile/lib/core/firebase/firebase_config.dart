import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Values from google-services.json
  static const String projectId = 'campusart';
  static const String storageBucket = 'campusart.firebasestorage.app';
  static const String messagingSenderId = '846171075121';
  static const String androidAppId =
      '1:846171075121:android:4975e7d47bf2714359db10';
  static const String androidApiKey = 'AIzaSyApJzg_ULvJ5xjQGv7Na0skRU2y5abp27s';

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  // iOS and Web options - need to be configured when those apps are registered
  // For now, use Android options as fallback (will only be used if running on those platforms without proper config)
  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(options: webOptions);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(options: androidOptions);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp(options: iosOptions);
    } else {
      await Firebase.initializeApp();
    }
  }
}
