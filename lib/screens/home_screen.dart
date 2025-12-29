import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'product_detail_screen.dart';
import '../widgets/divara_drawer.dart';
import '../widgets/divara_header.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/guest_service.dart';
import 'notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_screen.dart';
import 'package:geolocator/geolocator.dart'; // 🔥 Fix: Moved to top

// 🔥 PREMIUM COLORS
const Color kPrimaryColor = Color(0xFF9C8270);
const Color kAccentColor = Color(0xFFE9DCD3);
const Color kBackgroundColor = Color(0xFFFDFBF9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<_HomeContentState> _homeContentKey =
      GlobalKey<_HomeContentState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(key: _homeContentKey),
      const ProductListingScreen(title: "All Categories"),
      const ProfileScreen(),
      const WishlistScreen(),
      const CartScreen(),
    ];

    // 🔥 Request Location Permission after 1 second
    Timer(const Duration(seconds: 1), () {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackgroundColor,
      extendBody: true,
      drawer: const DivaraDrawer(),
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: const Text(
                "DIVARA",
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Serif',
                ),
              ),
              centerTitle: true,
              backgroundColor: kBackgroundColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: kPrimaryColor),
            ),
      body: _pages[_selectedIndex],

      // 🔥 UPDATED SPLIT BOTTOM BAR WITH AD
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 Banner Ad (જો લોડ થયું હોય તો)
          if (_selectedIndex == 0 &&
              _homeContentKey.currentState?._isAdLoaded == true &&
              _homeContentKey.currentState?._bannerAd != null)
            Container(
              height: 50,
              color: Colors.white,
              alignment: Alignment.center,
              child: AdWidget(ad: _homeContentKey.currentState!._bannerAd!),
            ),

          // Navigation Bar
          Container(
            height: 60,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                // 1. MAIN NAVIGATION (Thodok Bhego - Compact)
                Expanded(
                  child: Container(
                    height: 60, // 🔥 FIX: Explicit height to match Right Bar
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(
                            233,
                            220,
                            211,
                            1,
                          ).withOpacity(1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: const Color.fromRGBO(
                            233,
                            220,
                            211,
                            1,
                          ).withOpacity(1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildCustomNavItem(
                                Icons.home,
                                Icons.home_outlined,
                                0,
                              ),
                              _buildCustomNavItem(
                                Icons.grid_view_rounded,
                                Icons.grid_view_outlined,
                                1,
                              ),
                              _buildCustomNavItem(
                                Icons.person,
                                Icons.person_outline,
                                2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // 2. SEPARATE ACTION BAR (Wishlist & Cart)
                Container(
                  height: 60, // 🔥 Height matches the main bar
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(
                      233,
                      220,
                      211,
                      1,
                    ).withOpacity(1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(
                          233,
                          220,
                          211,
                          1,
                        ).withOpacity(1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // WISHLIST (Index 3)
                      GestureDetector(
                        onTap: () => _onItemTapped(3),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseAuth.instance.currentUser != null
                              ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('wishlist')
                                    .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            int count = 0;
                            if (FirebaseAuth.instance.currentUser != null) {
                              if (snapshot.hasData)
                                count = snapshot.data!.docs.length;
                            } else {
                              // Guest Mode Wishlist Count (FutureBuilder would be better but simple poll here)
                              // For now, Guest ignores real-time badge updates in this limited implementations or
                              // we accept it shows 0 until refreshed.
                              // To fix, we can rely on a global state, but for now let's fix the User "0" issue firmly.
                              // Actually, let's try to fetch guest list length synchronously if possible or ignore.
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: EdgeInsets.zero,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _selectedIndex == 3
                                        ? kPrimaryColor.withOpacity(0.1)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _selectedIndex == 3
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: kPrimaryColor,
                                    size: 24,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "$count",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 5),

                      // CART (Index 4)
                      GestureDetector(
                        onTap: () => _onItemTapped(4),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseAuth.instance.currentUser != null
                              ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('cart')
                                    .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            int count = 0;
                            if (FirebaseAuth.instance.currentUser != null) {
                              if (snapshot.hasData)
                                count = snapshot.data!.docs.length;
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: EdgeInsets.zero,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _selectedIndex == 4
                                        ? kPrimaryColor.withOpacity(0.1)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _selectedIndex == 4
                                        ? Icons.shopping_bag
                                        : Icons.shopping_bag_outlined,
                                    color: kPrimaryColor,
                                    size: 24,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "$count",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withOpacity(0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          size: 24,
          color: isSelected ? kPrimaryColor : kPrimaryColor.withOpacity(0.6),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 🔥 Ads માટેના વેરીએબલ્સ
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // --- સ્લાઈડર માટેના વેરીએબલ્સ ---
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;
  List<DocumentSnapshot> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // 🔥 એડ લોડ કરવાનું ફંક્શન
    _fetchBanners(); // ⚡ ડેટાબેઝમાંથી બેનર લેવાનું શરૂ
  }

  // 🔥 Banner Ad લોડ કરવાનું ફંક્શન
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1239078847658553/7189295032',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  // 🔥 Firebase માંથી બેનર લાવવાનું ફંક્શન
  void _fetchBanners() {
    FirebaseFirestore.instance
        .collection('home_banners') // ✅ તમારું નવું કલેક્શન
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _banners = snapshot.docs;
            });
            if (_banners.isNotEmpty) {
              _startAutoSlide(); // બેનર મળે એટલે સ્લાઈડર શરૂ કરો
            }
          }
        });
  }

  // 🔥 Automatic Sliding Logic (Every 3 Seconds)
  // 🔥 Automatic Sliding Logic (Dynamic Duration)
  void _startAutoSlide() {
    _timer?.cancel(); // Cancel active timer

    if (_banners.isEmpty) return;

    // 1. Get Duration for Current Banner
    var bannerData = _banners[_currentPage].data() as Map<String, dynamic>;
    int durationSeconds =
        bannerData['duration'] ?? 10; // Default 10s if not set
    if (durationSeconds < 3) durationSeconds = 3; // Minimum safety

    // 2. Schedule Next Slide
    _timer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) {
        if (_currentPage < _banners.length - 1) {
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

        // 3. Restart Timer for Next Slide
        _startAutoSlide();
      }
    });
  }

  // 🔥 Instagram Launcher
  Future<void> _launchInstagram(String? customUrl) async {
    final String urlStr =
        customUrl ??
        "https://www.instagram.com/its_divara?igsh=MTI5Z29uMWdsMGt3NA==";
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _bannerAd?.dispose(); // 🔥 Ad ડિસ્પોઝ કરવું
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // 🔥 Swipe Right to Open Drawer
        if (details.primaryVelocity! > 0) {
          Scaffold.of(context).openDrawer();
        }
      },
      child: CustomScrollView(
        controller: ScrollController(), // Optional: if you need to track scroll
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. TOP CONTENT (Header, Banners, Categories)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CUSTOM HEADER
                FadeInSlide(
                  delay: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 0,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. CENTER TITLE - REPLACED WITH CONSTANT WIDGET
                            const DivaraHeader(),

                            // 2. LEFT & RIGHT BUTTONS
                            Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left Menu Button
                                  GestureDetector(
                                    onTap: () =>
                                        Scaffold.of(context).openDrawer(),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: kPrimaryColor.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.menu,
                                        color: kPrimaryColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),

                                  // Right Notification Button
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            const NotificationsScreen(),
                                      ),
                                    ),
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream:
                                          (FirebaseAuth.instance.currentUser !=
                                              null)
                                          ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid,
                                                )
                                                .collection('notifications')
                                                .where(
                                                  'isRead',
                                                  isEqualTo: false,
                                                )
                                                .snapshots()
                                          : null,
                                      builder: (context, snapshot) {
                                        int unreadCount = 0;
                                        if (snapshot.hasData) {
                                          unreadCount =
                                              snapshot.data!.docs.length;
                                        }

                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: kPrimaryColor
                                                        .withOpacity(0.1),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .notifications_active_outlined,
                                                color: kPrimaryColor,
                                                size: 22,
                                              ),
                                            ),
                                            if (unreadCount > 0)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Text(
                                                    unreadCount > 9
                                                        ? "9+"
                                                        : "$unreadCount",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const SearchScreen(),
                            ),
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(1),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Search rings, necklaces...",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(Icons.tune, color: kPrimaryColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2. HERO BANNER SLIDER
                if (_banners.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _banners.length,
                      onPageChanged: (index) {
                        _currentPage = index;
                        _startAutoSlide();
                      },
                      itemBuilder: (context, index) {
                        var bannerData =
                            _banners[index].data() as Map<String, dynamic>;
                        return FadeInSlide(
                          delay: 0,
                          child: GestureDetector(
                            onTap: (index == _banners.length - 1)
                                ? () => _launchInstagram(bannerData['link'])
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4A3B32,
                                    ).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: CachedNetworkImage(
                                  imageUrl: bannerData['image'] ?? "",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 30),

                // 3. CATEGORIES
                FadeInSlide(delay: 0.4, child: _buildTopCategories(context)),

                const SizedBox(height: 30),

                // 4. HEADER FOR PRODUCTS
                FadeInSlide(
                  delay: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Popular Jewelry",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Serif',
                            color: Color(0xFF4A3B32),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const ProductListingScreen(
                                title: "All Categories",
                              ),
                            ),
                          ),
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 13,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),

          // 5. SLIVER GRID FOR PRODUCTS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              // Wishlist Logic
              return StreamBuilder<QuerySnapshot>(
                stream: (FirebaseAuth.instance.currentUser != null)
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('wishlist')
                          .snapshots()
                    : null,
                builder: (context, wishlistSnap) {
                  Set<String> wishlistedIds = {};
                  if (wishlistSnap.hasData) {
                    for (var doc in wishlistSnap.data!.docs) {
                      wishlistedIds.add(doc.id);
                    }
                  }

                  var products = snapshot.data?.docs ?? [];

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        var data =
                            products[index].data() as Map<String, dynamic>;
                        data['id'] = products[index].id;

                        bool isLiked = wishlistedIds.contains(
                          data['id'] ?? data['name'],
                        );

                        return ProductCard(
                          product: data,
                          initialWishlistStatus: isLiked,
                        );
                      }, childCount: products.length),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Fallback or Empty State
          return const SizedBox.shrink();
        }

        var categories = snapshot.data!.docs;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var data = categories[index].data() as Map<String, dynamic>;
              String name = data['name'] ?? "Category";
              String image =
                  data['image'] ?? ""; // Ensure 'image' field in Firestore

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ProductListingScreen(title: name),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kPrimaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: kAccentColor.withOpacity(0.3),
                          backgroundImage: image.isNotEmpty
                              ? CachedNetworkImageProvider(image)
                              : null,
                          child: image.isEmpty
                              ? const Icon(Icons.category, color: kPrimaryColor)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A3B32),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool initialWishlistStatus;

  const ProductCard({
    super.key,
    required this.product,
    this.initialWishlistStatus = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool isWishlisted;

  @override
  void initState() {
    super.initState();
    isWishlisted = widget.initialWishlistStatus;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialWishlistStatus != oldWidget.initialWishlistStatus) {
      isWishlisted = widget.initialWishlistStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl =
        (widget.product['images'] != null &&
            (widget.product['images'] as List).isNotEmpty)
        ? (widget.product['images'] as List).first
        : (widget.product['image'] ?? "");

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: widget.product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 400, // 🔥 Optimization
                      placeholder: (c, u) =>
                          Container(color: kAccentColor.withOpacity(0.3)),
                      errorWidget: (c, u, e) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),

                  // ACTIVE HEART BUTTON - Optimized (No StreamBuilder per card)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please Login to Wishlist"),
                            ),
                          );
                          return;
                        }

                        // Optimistic Update
                        setState(() {
                          isWishlisted = !isWishlisted;
                        });

                        final wishlistRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('wishlist')
                            .doc(
                              widget.product['id'] ?? widget.product['name'],
                            );

                        try {
                          if (!isWishlisted) {
                            // Was liked, now unliked (we already toggled state)
                            await wishlistRef.delete();
                          } else {
                            // Was unliked, now liked
                            await wishlistRef.set(widget.product);
                          }
                        } catch (e) {
                          // Revert on failure
                          setState(() {
                            isWishlisted = !isWishlisted;
                          });
                          debugPrint("Wishlist Error: $e");
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? Colors.red : kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'] ?? "Jewelry",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF4A3B32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${widget.product['price'] ?? 0}",
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeInSlide extends StatelessWidget {
  final Widget child;
  final double delay;
  const FadeInSlide({super.key, required this.child, this.delay = 0});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      builder: (context, double val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - val)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ProductListingScreen extends StatelessWidget {
  final String title;
  const ProductListingScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: kPrimaryColor)),
        backgroundColor: kBackgroundColor,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: title == "All Categories"
            ? FirebaseFirestore.instance.collection('products').snapshots()
            : FirebaseFirestore.instance
                  .collection('products')
                  .where('category', isEqualTo: title)
                  .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("No Products Found"));

          // 🔥 Fetch Wishlist for Sync
          return StreamBuilder<QuerySnapshot>(
            stream: (FirebaseAuth.instance.currentUser != null)
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('wishlist')
                      .snapshots()
                : null,
            builder: (context, wishlistSnap) {
              Set<String> wishlistedIds = {};
              if (wishlistSnap.hasData) {
                for (var doc in wishlistSnap.data!.docs) {
                  wishlistedIds.add(doc.id);
                }
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                itemCount: snapshot.data!.docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var product = Map<String, dynamic>.from(
                    doc.data() as Map<String, dynamic>,
                  );
                  product['id'] = doc.id;

                  bool isLiked = wishlistedIds.contains(
                    product['id'] ?? product['name'],
                  );

                  return ProductCard(
                    product: product,
                    initialWishlistStatus: isLiked,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackgroundColor,
    appBar: AppBar(
      title: Text(title, style: const TextStyle(color: kPrimaryColor)),
      backgroundColor: kBackgroundColor,
      iconTheme: const IconThemeData(color: kPrimaryColor),
    ),
    body: Center(child: Text("$title - Coming Soon!")),
  );
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> guestCart = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user == null) {
      _loadGuestCart();
    }
  }

  void _loadGuestCart() async {
    setState(() => isLoading = true);
    var cart = await GuestService.getCart();
    setState(() {
      guestCart = cart;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      // LOGGED IN USER - FIRESTORE STREAM
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          var items = (snapshot.hasData) ? snapshot.data!.docs : [];
          return _buildCartList(items, isGuest: false);
        },
      );
    } else {
      // GUEST USER - LOCAL STORAGE
      if (isLoading)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return _buildCartList(guestCart, isGuest: true);
    }
  }

  Widget _buildCartList(List<dynamic> items, {required bool isGuest}) {
    // 🎨 Theme Colors (Modern Palette)
    final Color modernBlack = const Color(0xFF2D2D2D);
    final Color modernGrey = const Color(0xFFF5F5F5);

    double subtotal = 0;
    for (var item in items) {
      if (isGuest) {
        subtotal += (item['price'] ?? 0) * (item['quantity'] ?? 1);
      } else {
        var data = item.data() as Map<String, dynamic>;
        subtotal += (data['price'] ?? 0) * (data['quantity'] ?? 1);
      }
    }
    double shipping = subtotal > 0 ? 50 : 0; // Example flat rate
    double total = subtotal + shipping;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "My Cart",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF5F5F5),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔥 LIST OF ITEMS
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Your Cart is Empty",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4A3B32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Add some beautiful items to your collection",
                          style: GoogleFonts.lato(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      var data = isGuest
                          ? items[index]
                          : (items[index] as DocumentSnapshot).data()
                                as Map<String, dynamic>;
                      String id = isGuest
                          ? (data['id'] ?? data['name'])
                          : (items[index] as DocumentSnapshot).id;

                      return Dismissible(
                        key: Key(id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        onDismissed: (direction) async {
                          if (isGuest) {
                            await GuestService.removeFromCart(id);
                            _loadGuestCart();
                          } else {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .collection('cart')
                                .doc(id)
                                .delete();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${data['name']} removed"),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 🖼️ Image
                              Container(
                                width: 90,
                                height: 90,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: modernGrey,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: data['image'] ?? "",
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),

                              // 📄 Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['name'] ?? "Product",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.lato(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: modernBlack,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Size: ${data['selectedSize'] ?? 'Std'}",
                                      style: GoogleFonts.lato(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹${data['price']}",
                                          style: GoogleFonts.lato(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: modernBlack,
                                          ),
                                        ),
                                        // ➕ Quantity
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: modernGrey,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "Qty: ${data['quantity'] ?? 1}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 🔥 BOTTOM SUMMARY
          Container(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Promo Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: modernGrey,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Promo code",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _summaryRow("Subtotal", "₹$subtotal"),
                const SizedBox(height: 10),
                _summaryRow("Shipping", "₹$shipping"),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _summaryRow("Total", "₹$total", isTotal: true),
                const SizedBox(height: 25),

                // CHECKOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (items.isEmpty) return;

                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const LoginScreen(),
                          ),
                        );
                      } else {
                        // Dummy checkout
                        var cartOrder = {
                          'name': 'Cart Order (${items.length} items)',
                          'price': total.toInt(),
                          'image': items.isNotEmpty
                              ? (isGuest
                                    ? items[0]['image']
                                    : items[0]['image'])
                              : "",
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CheckoutScreen(product: cartOrder),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: const Color(0xFFFF6B00).withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Checkout",
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white12,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            color: isTotal ? Colors.black : Colors.grey[600],
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            color: isTotal ? Colors.black : Colors.black87,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper to get item count
  int get itemCount => user != null ? 1 : guestCart.length; // Approximate
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> guestWishlist = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user == null) {
      _loadGuestWishlist();
    }
  }

  void _loadGuestWishlist() async {
    setState(() => isLoading = true);
    var items = await GuestService.getWishlist();
    setState(() {
      guestWishlist = items;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('wishlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return _emptyWishlist();
          var items = snapshot.data!.docs
              .map((e) => e.data() as Map<String, dynamic>)
              .toList();
          return _buildWishlistGrid(items);
        },
      );
    } else {
      if (isLoading)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (guestWishlist.isEmpty) return _emptyWishlist();
      return _buildWishlistGrid(guestWishlist, isGuest: true);
    }
  }

  Widget _emptyWishlist() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Wishlist",
          style: TextStyle(color: kPrimaryColor),
        ),
        backgroundColor: kBackgroundColor,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: Center(
        child: Text(
          "Wishlist is Empty",
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildWishlistGrid(List<dynamic> items, {bool isGuest = false}) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Wishlist",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBackgroundColor,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          var data = items[index] as Map<String, dynamic>;
          return ProductCard(product: data, initialWishlistStatus: true);
        },
      ),
    );
  }
}
