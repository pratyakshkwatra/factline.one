import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/widgets/recommendations.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:factline/services/auth.dart';

@RoutePage()
class RecommendationsFullScreen extends StatefulWidget {
  final User user;
  final AuthService authService;
  const RecommendationsFullScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<RecommendationsFullScreen> createState() =>
      _RecommendationsFullScreenState();
}

class _RecommendationsFullScreenState extends State<RecommendationsFullScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FactlineInter(
                      "Intelligence Briefing",
                      style: GoogleFonts.merriweather(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomRecommendations(
                  user: widget.user,
                  restrictedView: false,
                  authService: widget.authService,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
