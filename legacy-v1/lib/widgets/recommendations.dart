import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/api/post.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CustomRecommendations extends StatefulWidget {
  final User user;
  final bool restrictedView;
  final AuthService authService;
  const CustomRecommendations({
    super.key,
    required this.user,
    required this.restrictedView,
    required this.authService,
  });

  @override
  State<CustomRecommendations> createState() => _CustomRecommendationsState();
}

class _CustomRecommendationsState extends State<CustomRecommendations> {
  Future<List<Post>> getNewsArticles() async {
    return await PostAPI().getRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.restrictedView ? 16 : 0),
      child: FutureBuilder(
        future: getNewsArticles(),
        builder: (context, snapshot) {
          // Loading skeleton
          if (!snapshot.hasData) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xff1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Shimmer(
                    color: const Color(0xff222222),
                    child: Container(color: Colors.transparent),
                  ),
                );
              },
            );
          }

          final List<Post> posts = snapshot.data!;

          if (posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: FactlineInter(
                  "No stories available",
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: min(posts.length, 5),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final Post post = posts[index];
              final int score = post.credibilityScore ?? 50;
              final Color scoreColor = score > 70
                  ? Colors.greenAccent
                  : score > 40
                  ? Colors.orangeAccent
                  : const Color(0xffD90429);

              return GestureDetector(
                onTap: () async {
                  await PostAPI().viewPost(post.id);
                  setState(() {});
                  if (context.mounted) {
                    await context.router.push(
                      NewsFullRoute(
                        post: post,
                        authService: widget.authService,
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: category tag + delete for editors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (post.tags.isNotEmpty)
                            FactlineInter(
                              post.tags.first.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xffD90429),
                                letterSpacing: 1.2,
                              ),
                            ),
                          if (widget.user.role == Role.editor)
                            GestureDetector(
                              onTap: () async {
                                await PostAPI().deletePost(post.id);
                                setState(() {});
                              },
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white24,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Headline
                      FactlineInter(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      if (post.summaryEasy != null) ...[
                        const SizedBox(height: 8),
                        FactlineInter(
                          post.summaryEasy!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white38,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Footer row
                      Row(
                        children: [
                          // Upvote
                          GestureDetector(
                            onTap: () async {
                              await PostAPI().upvotePost(post.id);
                              setState(() {});
                            },
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: post.isUpvoted
                                  ? const Color(0xffD90429)
                                  : Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 4),
                          FactlineInter(
                            NumberFormat.compact().format(
                              post.upvoteDownvoteCount,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Views
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 4),
                          FactlineInter(
                            NumberFormat.compact().format(post.viewCount),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white24,
                            ),
                          ),
                          const Spacer(),
                          // Credibility pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: scoreColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: FactlineInter(
                              "$score% verified",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
