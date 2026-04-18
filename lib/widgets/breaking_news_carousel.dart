import 'package:factline/api/post.dart';
import 'package:factline/widgets/carousel.dart';
import 'package:flutter/material.dart';
import 'package:factline/api/models/post.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BreakingNewsCarousel extends StatelessWidget {
  final Function(Post post) onClick;
  const BreakingNewsCarousel({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    const shimmerColor = Color(0xff1A1A1A);

    return FutureBuilder<List<Post>>(
      future: PostAPI().getBreakingNews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            children: [
              SizedBox(
                height: 148,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Shimmer(
                          color: shimmerColor,
                          child: Container(color: Colors.white10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return CustomCarousel(posts: snapshot.data!, onClick: onClick);
      },
    );
  }
}
