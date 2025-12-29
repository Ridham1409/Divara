import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'home_screen.dart'; 

class SubCategoryScreen extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;

  const SubCategoryScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color headerColor = isDark ? Colors.grey[900]! : Colors.white;
    Color stripColor = isDark ? Colors.grey[800]! : const Color(0xFFF3E5E5);
    Color primaryColor = DivaraTheme.primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER (CLEANED) ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              color: headerColor,
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DivaraTheme.gold, width: 2))),
                      Icon(Icons.person_outline, size: 30, color: primaryColor),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi Dear!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 2),
                        const Text("+91 xxxxxxxxxx", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. BACK STRIP ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              color: stripColor,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: primaryColor),
                  ),
                  const SizedBox(width: 15),
                  Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),

            // --- 3. LIST ---
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    color: isDark ? Colors.black : const Color(0xFFF9F9F9),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      title: Text(item['title']!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: item['sub'] != null && item['sub']!.isNotEmpty ? Text(item['sub']!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProductListingScreen(title: item['title']!))),
                    ),
                  );
                },
              ),
            ),
            
            // --- 4. EXPLORE BTN ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: isDark ? Colors.black : Colors.white,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProductListingScreen(title: title))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Explore All $title", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 5), Icon(Icons.chevron_right, color: primaryColor, size: 18)]),
              ),
            )
          ],
        ),
      ),
    );
  }
}