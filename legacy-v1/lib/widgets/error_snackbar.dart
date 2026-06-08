import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showErrorSnackbar(String message, BuildContext context) {
  final snackBar = SnackBar(
    content: FactlineInter(
      message,
      style: GoogleFonts.merriweather(color: Colors.white),
    ),
    backgroundColor: Colors.redAccent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
