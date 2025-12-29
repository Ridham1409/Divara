import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart'; // 🔥 Import Added
import '../utils/theme.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isGiftWrapped;
  final String giftMessage;
  final int quantity;

  const CheckoutScreen({
    super.key,
    required this.product,
    this.isGiftWrapped = false,
    this.giftMessage = "",
    this.quantity = 1,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  // Payment Option
  String _paymentMethod = "Cash on Delivery (COD)"; // Default

  // 🔥 Location Logic & Order Placement
  void _placeOrderOnWhatsApp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Confirm Order?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to place this order on WhatsApp?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                _processOrder(); // Proceed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DivaraTheme.primaryColor,
              ),
              child: const Text(
                "YES, PROCEED",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _processOrder() async {
    String phone = "916354854343"; // Your Number

    String giftStatus = widget.isGiftWrapped ? "✅ Yes (Wrap it!)" : "❌ No";
    String giftMsg = widget.giftMessage.isNotEmpty ? widget.giftMessage : "N/A";

    double price = double.tryParse(widget.product['price'].toString()) ?? 0;
    double total = price * widget.quantity;

    // 1. Analyze Location from Address
    String fullAddress =
        "${_addressCtrl.text}, ${_cityCtrl.text}, ${_pinCtrl.text}";
    bool isBhavnagar =
        _cityCtrl.text.toLowerCase().contains("bhavnagar") ||
        _pinCtrl.text.contains("364001");
    bool isGujarat = fullAddress.toLowerCase().contains("gujarat");
    // Fallback check for Gujarat pincodes
    if (!isGujarat &&
        (_pinCtrl.text.startsWith("36") ||
            _pinCtrl.text.startsWith("37") ||
            _pinCtrl.text.startsWith("38") ||
            _pinCtrl.text.startsWith("39"))) {
      isGujarat = true;
    }

    String delayedTitle = "";
    String delayedBody = "";

    if (isBhavnagar) {
      delayedTitle = "Ready for Pickup! 🛍️";
      delayedBody =
          "Your order is ready for pickup at our Bhavnagar store! Please collect it from 'Shree Hari' 44, Nilkanth society, Sardarnagar. 🛍️";
    } else if (isGujarat) {
      delayedTitle = "Shipping Update 🚚";
      delayedBody =
          "Order confirmed for ${_cityCtrl.text}! Delivery in 2-3 days. 🚚";
    } else {
      delayedTitle = "Shipping Update 🚚";
      delayedBody =
          "Order confirmed for ${_cityCtrl.text}! Delivery in 4-5 days. 🚚";
    }

    // 2. WhatsApp Message Creation
    String message =
        """
👋 *New Order Request!*

📦 *Product Details:*
Name: ${widget.product['name']}
Price: ₹${widget.product['price']}
Quantity: ${widget.quantity}
*Total Price: ₹$total*

👤 *Customer Details:*
Name: ${_nameCtrl.text}
Mobile: ${_mobileCtrl.text}
Email: ${_emailCtrl.text.isEmpty ? "Not Provided" : _emailCtrl.text}

🏠 *Delivery Address:*
${_addressCtrl.text},
City: ${_cityCtrl.text} - ${_pinCtrl.text}

🎁 *Gift Wrapping:* $giftStatus
✉️ *Gift Message:* $giftMsg

💳 *Payment Mode:* $_paymentMethod

🖼️ *Product Image:*
${widget.product['image']}
    """;

    // 3. 🔥 SAVE ORDER & SEND IMMEDIATE NOTIFICATION
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // A. Save Order
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .add({
              'productName': widget.product['name'],
              'productImage': widget.product['image'],
              'price': price,
              'quantity': widget.quantity,
              'totalPrice': total,
              'customerName': _nameCtrl.text,
              'mobile': _mobileCtrl.text,
              'address':
                  "${_addressCtrl.text}, ${_cityCtrl.text} - ${_pinCtrl.text}",
              'status': "Order Placed", // Initial Status
              'orderDate': FieldValue.serverTimestamp(),
              'isGiftWrapped': widget.isGiftWrapped,
              'giftMessage': giftMsg,
              'paymentMethod': _paymentMethod,
            });

        // B. Immediate Notification (Generic)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
              'title': "Order Placed Successfully ✅",
              'body':
                  "Your order for ${widget.product['name']} has been placed.",
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'order',
            });

        // C. 🔥 DELAYED NOTIFICATION (Simulated)
        // Shows in App (Firestore) AND System Tray (Notification Bar)
        Future.delayed(const Duration(seconds: 5), () async {
          // 1. Add to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .add({
                'title': delayedTitle,
                'body': delayedBody,
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
                'type': 'order',
              });

          // 2. 🔥 Show in System Notification Bar
          await NotificationService().showNotification(
            delayedTitle,
            delayedBody,
          );
        });

        // D. Show Immediate System Notification
        await NotificationService().showNotification(
          "Order Placed Successfully ✅",
          "Your order for ${widget.product['name']} has been placed.",
        );
      } catch (e) {
        debugPrint("Error saving order: $e");
      }
    }

    // 4. Launch WhatsApp
    final Uri url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color primaryColor = DivaraTheme.primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: primaryColor),
        elevation: 0,
        backgroundColor: bgColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. PRODUCT SUMMARY CARD ---
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.product['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${widget.product['price']}",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Qty: ${widget.quantity}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- 2. PERSONAL DETAILS ---
                    const Text(
                      "Customer Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField("Full Name", _nameCtrl, Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Mobile Number",
                      _mobileCtrl,
                      Icons.phone,
                      isNumber: true,
                      isMobile: true,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Email ID (Optional)",
                      _emailCtrl,
                      Icons.email,
                      isEmail: true,
                      required: false,
                    ),

                    const SizedBox(height: 25),

                    // --- 3. ADDRESS DETAILS ---
                    const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      "Full Address (House No, Street)",
                      _addressCtrl,
                      Icons.home,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "City",
                            _cityCtrl,
                            Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Pincode",
                            _pinCtrl,
                            Icons.pin_drop,
                            isNumber: true,
                            isPincode: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 4. PAYMENT METHOD ---
                    const Text(
                      "Payment Method",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile(
                            activeColor: primaryColor,
                            title: const Text("Cash on Delivery (COD)"),
                            value: "Cash on Delivery (COD)",
                            groupValue: _paymentMethod,
                            onChanged: (val) =>
                                setState(() => _paymentMethod = val.toString()),
                          ),
                          RadioListTile(
                            activeColor: primaryColor,
                            title: const Text("Pay on WhatsApp (UPI/Bank)"),
                            value: "Online Payment (Discuss on WhatsApp)",
                            groupValue: _paymentMethod,
                            onChanged: (val) =>
                                setState(() => _paymentMethod = val.toString()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // --- 5. BOTTOM BUTTON ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _placeOrderOnWhatsApp(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      color: isDark ? Colors.black : Colors.white,
                    ), // WhatsApp Icon Fix
                    const SizedBox(width: 10),
                    Text(
                      "CONFIRM ORDER ON WHATSAPP",
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ Updated TextField with Validation Logic
  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isNumber = false,
    bool isEmail = false,
    bool isMobile = false,
    bool isPincode = false,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return "$label is required";
        }
        if (isMobile && value != null && value.length != 10) {
          return "Enter a valid 10-digit number";
        }
        if (isPincode && value != null && value.length != 6) {
          return "Enter a valid 6-digit Pincode";
        }
        if (isEmail && value != null && value.isNotEmpty) {
          bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
          ).hasMatch(value);
          if (!emailValid) return "Enter a valid email address";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
    );
  }
}
