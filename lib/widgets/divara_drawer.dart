import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'divara_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../screens/profile_screen.dart';
import '../screens/subcategory_screen.dart';
import '../screens/login_screen.dart'; // 🔥 IMPORT ADDED
import '../screens/my_orders_screen.dart'; // 🔥 IMPORT ADDED

class DivaraDrawer extends StatelessWidget {
  const DivaraDrawer({super.key});

  void _openWhatsApp(BuildContext context) async {
    String phone = "919876543210";
    String message = "Hello Divara Support, I have a query regarding...";
    final Uri url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔥 User Data
    User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName?.split(' ')[0] ?? "Guest";

    final Map<String, String> menuStatus = {
      "Men": "Available Soon",
      "Kids": "Available Soon",
    };
    final List<Map<String, String>> allJewelleryList = [
      {"title": "Earrings", "sub": "All Earrings, Studs & Tops, Drops &"},
      {"title": "Pendants", "sub": "Casual Wear, Party Wear, Work Wear"},
      {"title": "Finger Rings", "sub": "Engagement Rings, Diamond Rings,"},
      {"title": "Neckwear", "sub": "Mangalsutras, Chains, Necklaces"},
      {"title": "Arm Wear", "sub": "Bangles, Bracelets, Kada"},
      {"title": "Nose Pins", "sub": ""},
      {"title": "Pendants and Earring Sets", "sub": ""},
      {"title": "Gold Coins", "sub": ""},
    ];
    final List<Map<String, String>> collectionsList = [
      {"title": "The Spotlight Edit", "sub": ""},
      {"title": "Enchanted Trails", "sub": ""},
      {"title": "Modern Polki", "sub": ""},
      {"title": "Glamdays", "sub": ""},
      {"title": "String It", "sub": ""},
      {"title": "Dharohar", "sub": ""},
      {"title": "Kakatiya", "sub": ""},
      {"title": "Joy Of Dressing", "sub": ""},
      {"title": "Engagement Rings", "sub": ""},
      {"title": "Pretty In Pink", "sub": ""},
      {"title": "Stunning Every Ear", "sub": ""},
      {"title": "Aveer", "sub": ""},
      {"title": "Dor", "sub": ""},
    ];

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C1E1E), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFFFF8F0), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DivaraTheme.gold, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (user?.photoURL != null)
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: (user?.photoURL == null)
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: DivaraTheme.primaryColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $displayName",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : DivaraTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 🔥🔥🔥 LOGIN / SIGNUP LINK ADDED HERE 🔥🔥🔥
                      if (user == null)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close Drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const DivaraHeader(showTagline: true),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: isDark
                                    ? Colors.white70
                                    : DivaraTheme.primaryColor,
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          user.email ?? "",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- MENU LIST ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildSectionLabel("Account"),
                _drawerItem(
                  context,
                  Icons.person_outline,
                  "My Profile",
                  tagText: "NEW",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const ProfileScreen()),
                    );
                  },
                ),
                _drawerItem(
                  context,
                  Icons.history,
                  "Order History",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const MyOrdersScreen()),
                    );
                  },
                ),
                const Divider(indent: 20, endIndent: 20),

                _buildSectionLabel("Shop By Category"),
                _drawerItem(
                  context,
                  Icons.diamond_outlined,
                  "All Jewellery",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => SubCategoryScreen(
                          title: "All Jewellery",
                          items: allJewelleryList,
                        ),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  context,
                  Icons.category_outlined,
                  "Collections",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => SubCategoryScreen(
                          title: "Collections",
                          items: collectionsList,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(indent: 20, endIndent: 20),

                _buildSectionLabel("Shop For"),
                _drawerItem(
                  context,
                  Icons.male,
                  "Men",
                  tagText: menuStatus['Men'],
                ),
                _drawerItem(
                  context,
                  Icons.child_care,
                  "Kids",
                  tagText: menuStatus['Kids'],
                ),
                const Divider(indent: 20, endIndent: 20),

                _buildSectionLabel("More"),
                _drawerItem(
                  context,
                  Icons.support_agent,
                  "Get In Touch",
                  onTap: () {
                    Navigator.pop(context);
                    _openWhatsApp(context);
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? tagText,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color tagBgColor = Colors.grey;
    Color tagTextColor = Colors.white;
    if (tagText == "Available") {
      tagBgColor = Colors.green.withOpacity(0.1);
      tagTextColor = Colors.green;
    } else if (tagText == "Available Soon") {
      tagBgColor = Colors.orange.withOpacity(0.1);
      tagTextColor = Colors.orange[800]!;
    } else if (tagText == "NEW") {
      tagBgColor = DivaraTheme.primaryColor;
      tagTextColor = Colors.white;
    }

    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: textColor ?? (isDark ? Colors.white70 : Colors.black54),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (tagText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(4),
                border: tagText != "NEW"
                    ? Border.all(color: tagTextColor, width: 0.5)
                    : null,
              ),
              child: Text(
                tagText,
                style: TextStyle(
                  fontSize: 9,
                  color: tagTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap ?? () {},
    );
  }
}
