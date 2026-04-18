import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomCarousel extends StatefulWidget {
  final List<Post> posts;
  final Function(Post) onClick;

  const CustomCarousel({super.key, required this.posts, required this.onClick});

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          controller: _controller,
          itemCount: widget.posts.length,
          itemBuilder: (context, index, realIndex) {
            final post = widget.posts[index];
            final imageUrl =
                (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
                ? post.mediaUrl!
                : "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80"; // High-quality news backup

            return GestureDetector(
              onTap: () async {
                widget.onClick(post);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xff1A1A1A),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xff1A1A1A),
                              const Color(0xff2D2D2D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.newspaper_rounded,
                              color: Colors.white10,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            FactlineInter(
                              "MEDIA_UNAVAILABLE",
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.95),
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (post.credibilityScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffD90429),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FactlineInter(
                                "CONFIDENCE: ${post.credibilityScore}%",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          FactlineInter(
                            post.shortTitle ?? post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.merriweather(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 160,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 8),
            onPageChanged: (index, reason) => setState(() => _current = index),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.posts.asMap().entries.map((entry) {
            final bool isActive = entry.key == _current;
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: isActive ? 24 : 8,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive ? const Color(0xffD90429) : Colors.white24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
