import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/api/post.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:factline/services/auth.dart';

class DossierTab extends StatefulWidget {
  final AuthService authService;
  const DossierTab({super.key, required this.authService});

  @override
  State<DossierTab> createState() => _DossierTabState();
}

class _DossierTabState extends State<DossierTab> {
  late final PostAPI _postAPI;
  List<Post>? _posts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _postAPI = PostAPI();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    final posts = await _postAPI.getMyPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff0F0F0F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FactlineMerriweather(
                  "Forensic Dossier",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FactlineInter(
                  "Archive of your intelligence submissions",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white38,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xffD90429)),
                  )
                : _posts == null || _posts!.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchMyPosts,
                    color: const Color(0xffD90429),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _posts!.length,
                      itemBuilder: (context, index) {
                        final post = _posts![index];
                        return _buildDossierItem(post);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: Colors.white10,
          ),
          const SizedBox(height: 16),
          FactlineInter(
            "NO RECORDS FOUND",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          FactlineInter(
            "Your submitted forensic news will appear here.",
            style: const TextStyle(fontSize: 12, color: Colors.white10),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierItem(Post post) {
    final isVetted = post.analysisStatus.name == "COMPLETED";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.router.push(
          NewsFullRoute(post: post, authService: widget.authService),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isVetted
                      ? const Color(0xff457B9D).withValues(alpha: 0.1)
                      : const Color(0xffD90429).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isVetted
                      ? Icons.verified_outlined
                      : Icons.pending_actions_rounded,
                  color: isVetted
                      ? const Color(0xff457B9D)
                      : const Color(0xffD90429),
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FactlineMerriweather(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusBadge(post.analysisStatus.name),
                        const SizedBox(width: 12),
                        FactlineInter(
                          "${post.credibilityScore ?? 0}% CONFIDENCE",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == "COMPLETED"
        ? const Color(0xff457B9D)
        : const Color(0xffD90429);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FactlineInter(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
