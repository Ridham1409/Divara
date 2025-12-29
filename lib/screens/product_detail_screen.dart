import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'full_screen_image_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import '../services/guest_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _giftMsgController = TextEditingController();

  late AnimationController _blinkController;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;

  bool _isGiftWrapped = false;
  String _deliveryMessage = "";
  Color _deliveryColor = Colors.grey;
  bool isWishlisted = false;
  double _sheetPosition = 0.5;
  int _activePage = 0;
  int _quantity = 1; // 🔥 Quantity State

  // 🔥 Access Reviews Collection
  CollectionReference get _reviewsRef => FirebaseFirestore.instance
      .collection('products')
      .doc(widget.product['id'] ?? widget.product['name'])
      .collection('reviews');

  // 🔥 Firebase Multiple Images Logic
  List<String> get _productImages {
    if (widget.product['images'] != null && widget.product['images'] is List) {
      return List<String>.from(widget.product['images']);
    }
    if (widget.product['image'] != null &&
        widget.product['image'].toString().isNotEmpty) {
      return [widget.product['image']];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _blinkController.repeat(reverse: true);

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );

    // 🔥 Check Wishlist Status
    _checkWishlistStatus();

    // 🔥 Increment Views
    _incrementViews();
  }

  void _incrementViews() {
    try {
      FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product['id'] ?? widget.product['name'])
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      debugPrint("Error incrementing views: $e");
    }
  }

  void _checkWishlistStatus() async {
    bool isLiked = false;
    if (isUserLoggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('wishlist')
          .doc(widget.product['id'] ?? widget.product['name'])
          .get();
      isLiked = doc.exists;
    } else {
      isLiked = await GuestService.isWishlisted(
        widget.product['id'] ?? widget.product['name'],
      );
    }

    if (mounted && isLiked) {
      setState(() {
        isWishlisted = true;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sheetController.dispose();
    _pincodeController.dispose();
    _giftMsgController.dispose();
    _blinkController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist() async {
    setState(() {
      isWishlisted = !isWishlisted;
    });

    if (isUserLoggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('wishlist')
          .doc(widget.product['id'] ?? widget.product['name']);

      if (isWishlisted) {
        _heartAnimController.forward(from: 0.0);
        await wishlistRef.set(widget.product);
      } else {
        await wishlistRef.delete();
      }
    } else {
      // Guest Logic
      await GuestService.toggleWishlist(widget.product);
      if (isWishlisted) {
        _heartAnimController.forward(from: 0.0);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWishlisted
                ? "${widget.product['name']} added to Wishlist! ❤️"
                : "Removed from Wishlist",
          ),
          backgroundColor: isWishlisted ? Colors.pink : Colors.black87,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareProduct() async {
    String message =
        "Check out this amazing ${widget.product['name']} on Divara! Price: ₹${widget.product['price']}";
    final Uri url = Uri.parse(
      "https://wa.me/?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      debugPrint('Could not launch WhatsApp');
  }

  void _checkPincode() {
    String pin = _pincodeController.text.trim();
    if (pin.length == 6 && int.tryParse(pin) != null) {
      setState(() {
        _deliveryMessage = "Delivery Available to $pin 🚚";
        _deliveryColor = Colors.green;
      });
      FocusScope.of(context).unfocus();
    } else {
      setState(() {
        _deliveryMessage = "Invalid Pincode ❌";
        _deliveryColor = Colors.red;
      });
    }
  }

  void _showReviewForm() {
    if (!isUserLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Login to write a review!")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => LoginScreen(product: widget.product)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double userRating = 0;
        final TextEditingController commentCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Write a Review",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Rate this product:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () =>
                            setModalState(() => userRating = index + 1.0),
                        icon: Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: DivaraTheme.gold,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Your Experience...",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DivaraTheme.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (userRating > 0) {
                          User? user = FirebaseAuth.instance.currentUser;
                          await _reviewsRef.add({
                            "name": user?.displayName ?? "User",
                            "rating": userRating,
                            "date": DateTime.now().toString(),
                            "comment": commentCtrl.text,
                            "uid": user?.uid,
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Review Submitted!")),
                          );
                        }
                      },
                      child: const Text(
                        "SUBMIT REVIEW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color goldColor = DivaraTheme.gold;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color textColor = isDark ? Colors.white : Colors.black;
    double screenHeight = MediaQuery.of(context).size.height;

    int price = int.tryParse(widget.product['price'].toString()) ?? 0;
    int mrp = int.tryParse(widget.product['mrp'].toString()) ?? price;
    int discount = (mrp > price) ? (((mrp - price) / mrp) * 100).round() : 0;

    // 🔥 Firebase Data Variables
    String weight = widget.product['weight'] ?? "N/A";
    String size = widget.product['size'] ?? "Standard";
    String purity = widget.product['purity'] ?? "22K Gold Plated";
    String material = widget.product['material'] ?? "Brass";
    String description =
        widget.product['description'] ?? "No description available.";

    double imageHeight = screenHeight * 0.55;
    if (_sheetPosition < 0.5) {
      double progress = ((0.5 - _sheetPosition) / (0.5 - 0.15)).clamp(0.0, 1.0);
      imageHeight = screenHeight * (0.55 + (0.45 * progress));
    }
    if (imageHeight < 0) imageHeight = 0;

    bool hideButtons = _sheetPosition > 0.8;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. IMAGE SLIDER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: RepaintBoundary(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (_sheetController.isAttached) {
                    if (details.primaryVelocity! < 0) {
                      _sheetController.animateTo(
                        1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    } else if (details.primaryVelocity! > 0) {
                      _sheetController.animateTo(
                        0.15,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _productImages.length,
                  onPageChanged: (page) => setState(() => _activePage = page),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: GestureDetector(
                        // 🔥 TAP TO OPEN FULL SCREEN
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewer(
                                images: _productImages,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: _productImages[index],
                          fit: BoxFit.contain, // 🔥 Full Image Visible
                          memCacheWidth: 1000,
                          placeholder: (context, url) =>
                              Container(color: Colors.transparent),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. DOT INDICATORS (Replaced Thumbnails)
          if (_productImages.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: (_sheetPosition * screenHeight) + 20,
              child: AnimatedOpacity(
                opacity: hideButtons ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_productImages.length, (index) {
                    bool isSelected = _activePage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? goldColor
                            : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),

          // 3. DRAGGABLE SHEET
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _sheetPosition = notification.extent;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.5,
              minChildSize: 0.15,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.15, 0.5, 1.0],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_sheetPosition > 0.9 ? 0 : 30),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: goldColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "BESTSELLER",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: goldColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.remove_red_eye,
                                size: 14,
                                color: Colors.grey,
                              ),
                              Text(
                                " ${widget.product['views'] ?? 1} people viewing",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Text(
                            widget.product['name'] ?? "",
                            style: DivaraTheme.brandTitleStyle.copyWith(
                              fontSize: 26,
                              letterSpacing: 0.5,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹$price",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (discount > 0)
                                Text(
                                  "₹$mrp",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              if (discount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "$discount% OFF",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          if (widget.product['stock'] != null)
                            FadeTransition(
                              opacity: _blinkController,
                              child: Row(
                                children: [
                                  Icon(
                                    widget.product['stock'] > 0
                                        ? Icons.local_fire_department
                                        : Icons.warning,
                                    color: widget.product['stock'] > 0
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.product['stock'] > 0
                                        ? "Hurry! Only ${widget.product['stock']} units left"
                                        : "Out of Stock",
                                    style: TextStyle(
                                      color: widget.product['stock'] > 0
                                          ? Colors.red
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: _infoBox(
                                  context,
                                  Icons.scale,
                                  "Gross Weight",
                                  weight,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoBox(
                                  context,
                                  Icons.straighten,
                                  "Size / Dim.",
                                  size,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // 🔥 Merged Details & Description
                          _animatedExpansionTile(
                            context,
                            title: "Product Details",
                            icon: Icons.diamond_outlined,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 10),
                                _detailRow("Weight", weight),
                                _detailRow("Size", size),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🔥 QUANTITY SELECTOR
                          Row(
                            children: [
                              Text(
                                "Quantity:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () {
                                        if (_quantity > 1)
                                          setState(() => _quantity--);
                                      },
                                    ),
                                    Text(
                                      "$_quantity",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () {
                                        if (_quantity < 5)
                                          setState(() => _quantity++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          const Text(
                            "Delivery Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _pincodeController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: const InputDecoration(
                                      hintText: "Enter Pincode",
                                      border: InputBorder.none,
                                      counterText: "",
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _checkPincode,
                                  child: Text(
                                    "CHECK",
                                    style: TextStyle(
                                      color: goldColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_deliveryMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 5),
                              child: Text(
                                _deliveryMessage,
                                style: TextStyle(
                                  color: _deliveryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: goldColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.card_giftcard,
                                        color: goldColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Wrap as a Gift?",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                          const Text(
                                            "Add a special message for ₹29",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isGiftWrapped,
                                      activeThumbColor: goldColor,
                                      onChanged: (v) =>
                                          setState(() => _isGiftWrapped = v),
                                    ),
                                  ],
                                ),
                                if (_isGiftWrapped) ...[
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _giftMsgController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      hintText: "Enter Gift Message...",
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white10
                                          : Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                          const Divider(), const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Customer Reviews",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextButton(
                                onPressed: _showReviewForm,
                                child: Text(
                                  "+ Write Review",
                                  style: TextStyle(color: goldColor),
                                ),
                              ),
                            ],
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: _reviewsRef
                                .orderBy('date', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              var reviews = snapshot.hasData
                                  ? snapshot.data!.docs
                                  : [];
                              double averageRating = 0.0;
                              if (reviews.isNotEmpty) {
                                double totalRating = 0.0;
                                for (var doc in reviews) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  // Safely handle rating as int or double
                                  var r = data['rating'];
                                  double ratingVal = 0.0;
                                  if (r is int) {
                                    ratingVal = r.toDouble();
                                  } else if (r is double) {
                                    ratingVal = r;
                                  }
                                  totalRating += ratingVal;
                                }
                                averageRating = totalRating / reviews.length;
                              }

                              return Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          averageRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: List.generate(
                                                5,
                                                (index) => Icon(
                                                  index < averageRating.round()
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 18,
                                                  color: goldColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "Based on ${reviews.length} reviews",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (reviews.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          "No Reviews Yet. Be the first to review!",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: reviews.length,
                                      separatorBuilder: (c, i) =>
                                          const SizedBox(height: 15),
                                      itemBuilder: (context, index) {
                                        var data =
                                            reviews[index].data()
                                                as Map<String, dynamic>;
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    child: Text(
                                                      (data['name'] ?? "U")
                                                          .toString()
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    data['name'] ?? "User",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    (data['date'] ?? "")
                                                        .toString()
                                                        .split(" ")[0],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < (data['rating'] ?? 0)
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 14,
                                                    color: goldColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                data['comment'] ?? "",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 300),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (isUserLoggedIn) {
                        User? user = FirebaseAuth.instance.currentUser;
                        final cartRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('cart')
                            .doc(
                              widget.product['id'] ?? widget.product['name'],
                            );

                        // Check if already in cart to update quantity or add new
                        DocumentSnapshot doc = await cartRef.get();
                        if (doc.exists) {
                          int currentQty = doc['quantity'] ?? 0;
                          await cartRef.update({
                            'quantity': currentQty + _quantity,
                          });
                        } else {
                          await cartRef.set({
                            ...widget.product,
                            'quantity': _quantity,
                            'added_at': DateTime.now().toString(),
                          });
                        }
                      } else {
                        // Guest Logic
                        Map<String, dynamic> productToAdd = {
                          ...widget.product,
                          'quantity':
                              _quantity, // In future, use actual quantity logic if available
                        };
                        await GuestService.addToCart(productToAdd);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${widget.product['name']} added to Cart! 🛒",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: goldColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_shopping_cart, color: goldColor),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isUserLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  product: widget.product,
                                  isGiftWrapped: _isGiftWrapped,
                                  giftMessage: _giftMsgController.text,
                                  quantity: _quantity,
                                ),
                              ),
                            );
                          } else {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoginScreen(product: widget.product),
                              ),
                            );
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "BUY ON WHATSAPP",
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: hideButtons,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hideButtons ? 0.0 : 1.0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circularBtn(
                          icon: Icons.arrow_back,
                          color: Colors.white,
                          onTap: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            _circularBtn(
                              icon: Icons.share,
                              color: Colors.white,
                              onTap: _shareProduct,
                            ),
                            const SizedBox(width: 15),
                            // 🔥 Real-time Wishlist Sync
                            StreamBuilder<DocumentSnapshot>(
                              stream: isUserLoggedIn
                                  ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .collection('wishlist')
                                        .doc(
                                          widget.product['id'] ??
                                              widget.product['name'],
                                        )
                                        .snapshots()
                                  : null,
                              builder: (context, snapshot) {
                                bool liked =
                                    isWishlisted; // Default to local state (Guest)
                                if (snapshot.hasData) {
                                  liked = snapshot.data!.exists;
                                }

                                return GestureDetector(
                                  onTap: () async {
                                    // Optimistic Update for Guest, Firestore handles User
                                    if (!isUserLoggedIn) {
                                      await _toggleWishlist();
                                    } else {
                                      // Logged In: Toggle Firestore directly
                                      User? user =
                                          FirebaseAuth.instance.currentUser;
                                      final wishlistRef = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(user!.uid)
                                          .collection('wishlist')
                                          .doc(
                                            widget.product['id'] ??
                                                widget.product['name'],
                                          );

                                      if (liked) {
                                        await wishlistRef.delete();
                                      } else {
                                        _heartAnimController.forward(from: 0.0);
                                        await wishlistRef.set(widget.product);
                                      }
                                    }
                                  },
                                  child: ScaleTransition(
                                    scale: _heartScaleAnimation,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Icon(
                                        liked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: liked
                                            ? Colors.red
                                            : Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DivaraTheme.gold),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _animatedExpansionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          iconColor: DivaraTheme.gold,
          collapsedIconColor: Colors.grey,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _circularBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
