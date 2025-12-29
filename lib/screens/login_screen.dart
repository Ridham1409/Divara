import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const LoginScreen({super.key, this.product});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 🔥 SLIDER VARIABLES
  int _currentPage = 0;
  late Timer _timer;
  final PageController _pageController = PageController(initialPage: 0);

  // 🔥 અહી લિસ્ટ ખાલી છે એટલે જૂના ફોટા ના આવે
  List<String> _sliderImages = [];

  @override
  void initState() {
    super.initState();
    _fetchSliderImages();
  }

  void _fetchSliderImages() {
    print("Fetching Images from Firebase..."); // Debugging માટે

    FirebaseFirestore.instance
        .collection('slider_images')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              print("No Images Found in Database!"); // જો ડેટાબેઝ ખાલી હોય તો
            }

            if (mounted) {
              setState(() {
                _sliderImages = snapshot.docs.map((doc) {
                  print("Found Image: ${doc['image']}"); // લિંક પ્રિન્ટ થશે
                  return doc['image'].toString();
                }).toList();
              });

              if (_sliderImages.isNotEmpty) {
                _startAutoSlide();
              }
            }
          },
          onError: (e) {
            print("Firebase Error: $e"); // જો એરર હોય તો દેખાશે
          },
        );
  }

  void _startAutoSlide() {
    try {
      _timer.cancel();
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _sliderImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    try {
      _timer.cancel();
    } catch (_) {}
    _pageController.dispose();
    super.dispose();
  }

  void _handlePostLogin() {
    if (widget.product != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (c) => CheckoutScreen(product: widget.product!),
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _handlePostLogin();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign In Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size; // Removed

    return Scaffold(
      body: Stack(
        children: [
          // 1. FULL SCREEN SLIDER BACKGROUND
          if (_sliderImages.isNotEmpty)
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _sliderImages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: _sliderImages[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.black),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.black),
                  );
                },
              ),
            )
          else
            Container(color: const Color(0xFF9C8270)), // Fallback color
          // 2. DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 3. CONTENT
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // LOGO & TEXT
                Hero(
                  tag: 'logo',
                  child: Image.asset('assets/images/logo2.png', height: 100),
                ),
                const SizedBox(height: 10),
                Text(
                  "DIVAin your oRA ✨",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),

                // GLASSMORPHISM CARD
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to access your exclusive collection",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // GOOGLE SIGN IN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                ),
                          label: Text(
                            _isLoading
                                ? " Signing In..."
                                : "Continue with Google",
                            style: GoogleFonts.lato(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // GUEST BUTTON
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const HomeScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Skip & Continue as Guest",
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Secure Login via Firebase",
                        style: GoogleFonts.lato(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
