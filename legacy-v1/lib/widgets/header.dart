import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomHeader extends StatefulWidget {
  final String title;
  final Function(BuildContext context)? onViewAllTap;
  const CustomHeader({
    super.key,
    required this.title,
    required this.onViewAllTap,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FactlineInter(
            widget.title,
            style: GoogleFonts.merriweather(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.black,
            ),
          ),
          if (widget.onViewAllTap != null)
            GestureDetector(
              onTap: () {
                widget.onViewAllTap!(context);
              },
              child: FactlineInter(
                "View All",
                style: GoogleFonts.merriweather(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
