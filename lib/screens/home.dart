import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/api/post.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/screens/game_ques.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/breaking_news_carousel.dart';
import 'package:factline/widgets/recommendations.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeTab extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  final User user;
  const HomeTab({
    super.key,
    required this.authService,
    required this.secureStorage,
    required this.user,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xff0F0F0F)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FactlineMerriweather(
                        "Factline Daily",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      FactlineInter(
                        "Your Trusted Verification Hub",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white38,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _actionIcon(
                        Icons.sports_esports_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: const Color(0xff0F0F0F),
                              body: SafeArea(
                                child: GameQuesTab(
                                  authService: widget.authService,
                                  secureStorage: widget.secureStorage,
                                  user: widget.user,
                                  isModal: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _actionIcon(
                        Icons.leaderboard_rounded,
                        () => context.router.push(
                          LeaderboardRoute(authService: widget.authService),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _actionIcon(
                        Icons.add_rounded,
                        () => context.router.push(
                          AddPostRoute(
                            authService: widget.authService,
                            secureStorage: widget.secureStorage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            _sectionTitle("Intelligence Feed"),
            const SizedBox(height: 16),
            BreakingNewsCarousel(
              onClick: (post) async {
                await PostAPI().viewPost(post.id);
                setState(() {});
                if (context.mounted) {
                  await context.router.push(
                    NewsFullRoute(post: post, authService: widget.authService),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: const Color(0xff0F0F0F),
                      body: SafeArea(
                        child: GameQuesTab(
                          authService: widget.authService,
                          secureStorage: widget.secureStorage,
                          user: widget.user,
                          isModal: true,
                        ),
                      ),
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xffD90429).withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xffD90429).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffD90429),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FactlineMerriweather(
                              "Truth vs Deepfake Challenge",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FactlineInter(
                              "Test your instincts against AI-doctored news stories.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FactlineMerriweather(
                    "Top Recommendations",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.router.push(
                      RecommendationsFullRoute(
                        user: widget.user,
                        authService: widget.authService,
                      ),
                    ),
                    child: FactlineInter(
                      "VIEW ALL",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xffD90429),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CustomRecommendations(
              user: widget.user,
              restrictedView: true,
              authService: widget.authService,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xffD90429),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          FactlineInter(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white38,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
