import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 🔥 Ads માટે

import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

// 🔥 Remote Config Service
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults(<String, dynamic>{
      'welcome_message': 'Welcome to DIVARA',
      'is_sale_on': false,
    });

    await _remoteConfig.fetchAndActivate();
  }

  String getWelcomeMessage() => _remoteConfig.getString('welcome_message');
  bool getSaleStatus() => _remoteConfig.getBool('is_sale_on');
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Notifications Setup (Handler only)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // Removed

  // 1. Firebase Initialize
  await Firebase.initializeApp();

  // 2. Google Mobile Ads Initialize 🔥
  MobileAds.instance.initialize();

  // 3. Crashlytics Error Handlers
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const DivaraApp());
}

class DivaraApp extends StatelessWidget {
  const DivaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIVARA',
      themeMode: ThemeMode.light,
      theme: DivaraTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
