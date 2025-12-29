import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 આ ઈમ્પોર્ટ કર
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // FlutterNativeSplash.remove(); // Removed

    // 1. Setup Logo Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // 2. Navigation Logic
    Timer(const Duration(milliseconds: 2500), () {
      User? user = FirebaseAuth.instance.currentUser;
      Widget nextScreen =
          const HomeScreen(); // Logic remains same (Home for both)

      if (user != null) {
        print("User is already logged in: ${user.phoneNumber}");
      } else {
        print("User is Guest");
      }

      // 3. Smooth Fade Transition
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  Future<void> _initServices() async {
    try {
      // Initialize Notification Service
      await NotificationService().initialize();

      // Initialize Remote Config
      await RemoteConfigService().init();

      debugPrint("Services Initialized Successfully ✅");
    } catch (e) {
      debugPrint("Service Initialization Failed: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBDDD4),
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: FadeTransition(
            opacity: _controller,
            child: Image.asset('assets/images/logo2.png', width: 250),
          ),
        ),
      ),
    );
  }
}
