import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'admin_add_product_screen.dart';

import 'notifications_screen.dart';
import 'admin_notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  // 🔥🔥🔥 અહી તમારા બધા Admin Emails લખી દો 🔥🔥🔥
  final List<String> adminEmails = [
    "ridhambhavnagariya@gmail.com",
    "vrindapatel7503@gmail.com",
  ];

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // 🔥 Fetch Last Shipping Address from Orders
  void _showShippingAddress() async {
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(1)
          .get();

      if (mounted) Navigator.pop(context); // Close Loader

      String address = "No address found from previous orders.";
      if (query.docs.isNotEmpty) {
        address = query.docs.first.data()['address'] ?? address;
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Shipping Address"),
            content: Text(address),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error fetching address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. PROFILE PICTURE & NAME
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DivaraTheme.gold, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (user?.photoURL != null)
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: (user?.photoURL == null)
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.displayName ?? "Guest User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    user?.phoneNumber ?? user?.email ?? "Login to see details",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. MENU OPTIONS
            // 🔥 My Orders Removed (Moved to Drawer)
            _profileOption(
              icon: Icons.favorite_border,
              title: "Wishlist",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const WishlistScreen()),
              ),
            ),
            _profileOption(
              icon: Icons.location_on_outlined,
              title: "Shipping Address",
              onTap: _showShippingAddress,
            ),
            _profileOption(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () async {
                final Uri url = Uri.parse("https://wa.me/916354854343");
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not open WhatsApp")),
                  );
                }
              },
            ),
            const Divider(),

            // 🔥 SECURITY LOGIC: અહીં ચેક થશે કે યુઝર લિસ્ટમાં છે કે નહીં
            if (user?.email != null && adminEmails.contains(user!.email))
              _profileOption(
                icon: Icons.admin_panel_settings,
                title: "Admin Page",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminAddProductScreen(),
                    ),
                  );
                },
              ),
            if (user?.email != null && adminEmails.contains(user!.email))
              _profileOption(
                icon: Icons.notification_add,
                title: "Send Notifications",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // 3. LOGOUT BUTTON
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(
              height: 120,
            ), // 🔥 FIX: Bottom bar overlap mate space vadhati
          ],
        ),
      ),
    );
  }

  Widget _profileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: DivaraTheme.gold),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
