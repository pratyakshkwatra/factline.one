import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTag extends StatelessWidget {
  const CustomTag({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.tag, color: Colors.white, size: 16),
          SizedBox(width: 2),
          FactlineInter(
            tag,
            style: GoogleFonts.merriweather(
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade300,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 2),
        ],
      ),
    );
  }
}
