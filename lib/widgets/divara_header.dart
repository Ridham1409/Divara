import 'package:flutter/material.dart';

class DivaraHeader extends StatelessWidget {
  final bool showTagline;
  final bool isDark;

  const DivaraHeader({super.key, this.showTagline = true, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔥 SAFE AREA FIX (Top Padding)
        SizedBox(height: MediaQuery.of(context).padding.top + 10),

        Text(
          "DIVARA",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF4A3B32),
            fontFamily: 'Serif',
            letterSpacing: 5.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            "DIVAin your oRA ✨",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
