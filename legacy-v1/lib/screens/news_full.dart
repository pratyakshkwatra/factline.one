import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/api/post.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/api/api_client.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:factline/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@RoutePage()
class NewsFullScreen extends StatefulWidget {
  final Post post;
  final AuthService authService;
  const NewsFullScreen({
    super.key,
    required this.post,
    required this.authService,
  });

  @override
  State<NewsFullScreen> createState() => _NewsFullScreenState();
}

class _NewsFullScreenState extends State<NewsFullScreen> {
  late Post _currentPost;
  String? _selectedAlt = "Neutral";
  final PostAPI _postAPI = PostAPI();
  String? _translatedTitle;
  String? _translatedSummary;
  bool _isTranslating = false;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initLinguisticConFactlineInter();
    if (_currentPost.analysisStatus != AnalysisStatus.completed &&
        _currentPost.analysisStatus != AnalysisStatus.failed) {
      _initWebSocket();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _initWebSocket() {
    final apiBaseUrl = ApiClient().dio.options.baseUrl;
    final wsBaseUrl = apiBaseUrl.replaceFirst('http', 'ws');
    final wsUrl = "$wsBaseUrl/ws/posts/${_currentPost.id}";

    debugPrint("Connecting to WebSocket: $wsUrl");
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (mounted) {
          setState(() {
            _currentPost = _currentPost.copyWith(
              analysisStatus: _stringToAnalysisStatus(data['analysis_status']),
              analysisProgress: (data['analysis_progress'] as num).toDouble(),
              statusMessage: data['status_message'],
            );
          });

          if (_currentPost.analysisStatus == AnalysisStatus.completed) {
            _channel?.sink.close();
            _refreshPostData();
          }
        }
      },
      onError: (error) {
        debugPrint("WebSocket Error: $error");
      },
      onDone: () {
        debugPrint("WebSocket Connection Closed");
      },
    );
  }

  AnalysisStatus _stringToAnalysisStatus(String? status) {
    if (status == null) return AnalysisStatus.pending;
    final cleanStatus = status.split('.').last.toUpperCase();
    switch (cleanStatus) {
      case 'PENDING':
        return AnalysisStatus.pending;
      case 'INGESTING':
        return AnalysisStatus.ingesting;
      case 'REFINING':
        return AnalysisStatus.refining;
      case 'VERIFYING':
        return AnalysisStatus.verifying;
      case 'GROUNDING':
        return AnalysisStatus.grounding;
      case 'FINALIZING':
        return AnalysisStatus.finalizing;
      case 'COMPLETED':
        return AnalysisStatus.completed;
      case 'FAILED':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.pending;
    }
  }

  String _getLangCode(String name) {
    switch (name) {
      case 'Hindi':
        return 'hi';
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      default:
        return 'en';
    }
  }

  Future<void> _initLinguisticConFactlineInter() async {
    final lang = widget.authService.selectedLanguage;
    final code = _getLangCode(lang);
    if (code != 'en') {
      _translateContent(code);
    }
  }

  Future<void> _refreshPostData() async {
    try {
      final freshPost = await _postAPI.getPostDetail(_currentPost.id);
      if (mounted && freshPost != null) {
        setState(() {
          _currentPost = freshPost;
          _initLinguisticConFactlineInter();
        });
      }
    } catch (e) {
      debugPrint("Final Refresh Failed: $e");
    }
  }

  Future<void> _translateContent(String langCode) async {
    if (!mounted) return;
    setState(() => _isTranslating = true);

    final tTitle = await TranslationService().translateAsync(
      _currentPost.title,
    );
    final tSummary = await TranslationService().translateAsync(
      _currentPost.shortTitle ?? _currentPost.summaryEasy ?? "",
    );

    if (mounted) {
      setState(() {
        _translatedTitle = tTitle;
        _translatedSummary = tSummary;
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(_currentPost),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainAnalysisHeader(_currentPost),
                      const SizedBox(height: 32),
                      if (_currentPost.mediaType == "IMAGE") ...[
                        _buildVisualForensics(_currentPost),
                        const SizedBox(height: 32),
                      ],
                      _buildGroundingConFactlineInter(_currentPost),
                      const SizedBox(height: 32),
                      _buildEvidenceChain(_currentPost),
                      const SizedBox(height: 32),
                      _buildMitigationWorkflow(_currentPost),
                      const SizedBox(height: 32),
                      _buildAltHeadlines(_currentPost),
                      const SizedBox(height: 32),
                      _buildClaims(_currentPost),
                      const SizedBox(height: 32),
                      _buildOriginalContent(_currentPost),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_currentPost.analysisStatus != AnalysisStatus.completed &&
              _currentPost.analysisStatus != AnalysisStatus.failed)
            _buildForensicProgressHUD(),
        ],
      ),
    );
  }

  Widget _buildForensicProgressHUD() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ScanningHUDAnimation(),
          const SizedBox(height: 60),
          _buildTimelineStep(
            "INGESTION",
            "CRAWLING & CONTENT EXTRACTION",
            _currentPost.analysisStatus == AnalysisStatus.ingesting ||
                _isDone(AnalysisStatus.ingesting),
          ),
          _buildTimelineDivider(_isDone(AnalysisStatus.ingesting)),
          if (_currentPost.mediaType == "IMAGE") ...[
            _buildTimelineStep(
              "NEURAL FORENSICS",
              "NEUROMORPHIC ARTIFACT SCANNING",
              _currentPost.statusMessage == "SCANNING_NEURAL_ARTIFACTS" ||
                  _currentPost.statusMessage == "AUDITING_VISUAL_METADATA" ||
                  _isDone(AnalysisStatus.ingesting),
            ),
            _buildTimelineDivider(_isDone(AnalysisStatus.ingesting)),
          ],
          _buildTimelineStep(
            "REFINEMENT",
            "GEMINI FORENSIC EDITOR REFINING",
            _currentPost.analysisStatus == AnalysisStatus.refining ||
                _isDone(AnalysisStatus.refining),
          ),
          _buildTimelineDivider(_isDone(AnalysisStatus.refining)),
          _buildTimelineStep(
            "VERIFICATION",
            "SEMANTIC CLUSTER & NLP AUDIT",
            _currentPost.analysisStatus == AnalysisStatus.verifying ||
                _isDone(AnalysisStatus.verifying),
          ),
          _buildTimelineDivider(_isDone(AnalysisStatus.verifying)),
          _buildTimelineStep(
            "GROUNDING",
            "TRUTH BASE CROSS-REFERENCING",
            _currentPost.analysisStatus == AnalysisStatus.grounding ||
                _isDone(AnalysisStatus.grounding),
          ),
          _buildTimelineDivider(_isDone(AnalysisStatus.grounding)),
          _buildTimelineStep(
            "FINALIZING",
            "SYNTHESIZING FORENSIC VERDICT",
            _currentPost.analysisStatus == AnalysisStatus.finalizing ||
                _isDone(AnalysisStatus.finalizing),
          ),
          const SizedBox(height: 60),
          FactlineInter(
            _formatStatus(_currentPost.statusMessage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xffD90429),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          FactlineInter(
            "${_currentPost.analysisProgress.toInt()}%",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return "";
    return status
        .split('_')
        .map((word) {
          if (word.isEmpty) return "";
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  bool _isDone(AnalysisStatus status) {
    final list = [
      AnalysisStatus.pending,
      AnalysisStatus.ingesting,
      AnalysisStatus.refining,
      AnalysisStatus.verifying,
      AnalysisStatus.grounding,
      AnalysisStatus.finalizing,
      AnalysisStatus.completed,
    ];
    return list.indexOf(_currentPost.analysisStatus) > list.indexOf(status);
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isActive) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xffD90429) : Colors.white10,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xffD90429).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FactlineInter(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : Colors.white10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              FactlineInter(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white38 : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isDone) {
    return Container(
      margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
      height: 20,
      width: 2,
      decoration: BoxDecoration(
        color: isDone ? const Color(0xffD90429) : Colors.white10,
      ),
    );
  }

  Widget _buildSliverAppBar(Post post) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: const Color(0xff0F0F0F),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.router.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (post.mediaUrl != null && post.mediaType == "IMAGE")
              Image.network(post.mediaUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffD90429), Color(0xff8D031A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  _getMediaIcon(post.mediaType),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            if (post.mediaType != "TEXT") _WaveformOverlay(),
            _buildForensicOverlay(post),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xff0F0F0F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            _buildC2PABadge(post),
          ],
        ),
      ),
    );
  }

  Widget _buildC2PABadge(Post post) {
    bool isSigned = post.c2paStatus?.contains("Verified") ?? false;
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSigned
              ? Colors.blueAccent.withValues(alpha: 0.8)
              : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              isSigned
                  ? Icons.verified_user
                  : Icons.no_encryption_gmailerrorred,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 8),
            FactlineInter(
              isSigned ? "C2PA SIGNED" : "UNAUTHENTICATED",
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceChain(Post post) {
    if (post.evidenceChain.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Logic & Evidence Chain"),
        const SizedBox(height: 16),
        ...post.evidenceChain.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FactlineInter(
                  "${e.key + 1}.",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xffD90429),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FactlineInter(
                    e.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroundingConFactlineInter(Post post) {
    if (post.groundingContext == null) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xffD90429).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffD90429).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: Color(0xffD90429),
                size: 18,
              ),
              const SizedBox(width: 12),
              FactlineInter(
                "VERIFIED VECTOR MATCH (QDRANT)",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xffD90429),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FactlineMerriweather(
            post.groundingContext!['text'] ?? "",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FactlineInter(
            post.groundingContext!['explanation'] ?? "",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Colors.greenAccent,
                size: 14,
              ),
              const SizedBox(width: 8),
              FactlineInter(
                "${"Truth Source".tr.toUpperCase()}: ${post.groundingContext!['source'] ?? 'Verified Database'}",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForensicOverlay(Post post) {
    if (post.forensicArtifacts.isEmpty) return const SizedBox();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _ScanningLine(height: constraints.maxHeight),
            ...post.forensicArtifacts.map(
              (f) => Positioned(
                left: f.x * constraints.maxWidth - 20,
                top: f.y * constraints.maxHeight - 20,
                child: _ForensicTarget(label: f.label),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getMediaIcon(String type) {
    switch (type) {
      case "IMAGE":
        return Icons.image;
      case "VIDEO":
        return Icons.video_library;
      case "AUDIO":
        return Icons.audiotrack;
      default:
        return Icons.article;
    }
  }

  Widget _buildMainAnalysisHeader(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBadge(post.language.toUpperCase(), const Color(0xffD90429)),
            const SizedBox(width: 12),
            _buildBadge(
              "${post.credibilityScore ?? 0}% TRUST SCORE",
              _getTrustColor(post.credibilityScore ?? 0),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FactlineMerriweather(
          _translatedTitle ?? post.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        FactlineInter(
          _translatedSummary ??
              post.shortTitle ??
              post.summaryEasy ??
              "Generating report...",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white60,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        if (post.confidenceScore != null && post.confidenceScore! < 60)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.orangeAccent,
                  size: 18,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: FactlineInter(
                    "EMERGING INTEL: This event has limited verifiable data. Verification is still in scouting phase.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => context.router.push(ForensicReportRoute(post: post)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xffD90429),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffD90429).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  FactlineInter(
                    "VIEW DETAILED FORENSIC AUDIT",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualForensics(Post post) {
    final vf = post.visualForensics;
    if (vf == null) return const SizedBox();

    final report = vf['neuromorphic_report'] as Map<String, dynamic>?;
    if (report == null) return const SizedBox();

    final prob = report['manipulation_probability'] ?? 0;
    final findings = report['findings'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FactlineInter(
                "VISUAL FORENSIC AUDIT",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xffD90429),
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (prob as int) > 40
                      ? const Color(0xffD90429).withValues(alpha: 0.1)
                      : Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FactlineInter(
                  "$prob% MANIPULATION",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: prob > 40
                        ? const Color(0xffD90429)
                        : Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FactlineInter(
            report['metadata_integrity'] ?? "Metadata Audit Pending",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...findings.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FactlineInter(
                      f.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitigationWorkflow(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Deep Forensic Assessment"),
        const SizedBox(height: 16),
        _workflowCard(
          "EDITORIAL CONTEXT",
          post.counterNarrative ?? "Synthesizing data...",
          const Color(0xffD90429),
          Icons.menu_book_rounded,
        ),
        const SizedBox(height: 12),
        _workflowCard(
          "ML DIAGNOSTICS (FACTLINE-VIT)",
          post.inconsistencyHighlights ?? "Identifying conflicts...",
          const Color(0xff457B9D),
          Icons.science_outlined,
        ),
      ],
    );
  }

  Widget _workflowCard(
    String label,
    String content,
    Color accent,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 12),
              FactlineInter(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FactlineInter(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAltHeadlines(Post post) {
    final altOptions = {
      "Neutral": post.altHeadlineNeutral,
      "Sensational": post.altHeadlineSensational,
      "Calm": post.altHeadlineCalm,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Narrative Re-framing"),
        const SizedBox(height: 16),
        Row(
          children: altOptions.keys.map((key) {
            final isSelected = _selectedAlt == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: FactlineInter(
                  key,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xffD90429),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                onSelected: (val) => setState(() => _selectedAlt = key),
              ),
            );
          }).toList(),
        ),
        if (_selectedAlt != null && altOptions[_selectedAlt] != null) ...[
          const SizedBox(height: 16),
          FactlineInter(
            altOptions[_selectedAlt]!,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClaims(Post post) {
    if (post.claims.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Factual Review"),
        const SizedBox(height: 16),
        ...post.claims.map((claim) => _buildClaimCard(claim)),
      ],
    );
  }

  Widget _buildClaimCard(Claim claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        title: FactlineInter(
          claim.text,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white24,
        childrenPadding: const EdgeInsets.all(20),
        children: [
          _claimStat(
            "RELIABILITY SCORE",
            "${claim.credibilityScore ?? 0}%",
            _getTrustColor(claim.credibilityScore ?? 0),
          ),
          const SizedBox(height: 16),
          _claimDetail(
            "Analytic Findings",
            claim.reason ?? "Cross-referencing...",
          ),
        ],
      ),
    );
  }

  Widget _claimStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FactlineInter(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.1,
          ),
        ),
        FactlineInter(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _claimDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FactlineInter(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xff457B9D),
            ),
          ),
          const SizedBox(height: 4),
          FactlineInter(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalContent(Post post) {
    if (post.body == null || post.body!.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Article Content"),
        const SizedBox(height: 16),
        FactlineInter(
          post.body!,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white24,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: FactlineInter(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: const Color(0xffD90429)),
        const SizedBox(width: 12),
        FactlineInter(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Color _getTrustColor(int score) {
    if (score >= 80) return const Color(0xff457B9D);
    if (score >= 50) return Colors.orangeAccent;
    return const Color(0xffD90429);
  }
}

class _WaveformOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            30,
            (i) => Container(
              width: 2,
              height: (i % 5 + 1) * 10.0,
              decoration: BoxDecoration(
                color: const Color(0xffD90429).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final double height;
  const _ScanningLine({required this.height});
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          top: _ctrl.value * widget.height,
          left: 0,
          right: 0,
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffD90429).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xffD90429),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ForensicTarget extends StatelessWidget {
  final String label;
  const _ForensicTarget({required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffD90429), width: 1.5),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.center_focus_strong,
                  color: Color(0xffD90429),
                  size: 16,
                ),
              ),
              _Corner(top: 0, left: 0),
              _Corner(top: 0, right: 0),
              _Corner(bottom: 0, left: 0),
              _Corner(bottom: 0, right: 0),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: const Color(0xffD90429),
          child: FactlineInter(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  const _Corner({this.top, this.left, this.right, this.bottom});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(width: 4, height: 4, color: const Color(0xffD90429)),
    );
  }
}

class _ScanningHUDAnimation extends StatefulWidget {
  @override
  State<_ScanningHUDAnimation> createState() => _ScanningHUDAnimationState();
}

class _ScanningHUDAnimationState extends State<_ScanningHUDAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _ForensicScannerPainter(_ctrl.value),
        );
      },
    );
  }
}

class _ForensicScannerPainter extends CustomPainter {
  final double progress;
  _ForensicScannerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xffD90429).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, size.width / 2, paint);

    final highlightPaint = Paint()
      ..color = const Color(0xffD90429)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    canvas.drawArc(rect, progress * 2 * 3.14159, 1.0, false, highlightPaint);
    canvas.drawArc(
      rect,
      (progress * 2 * 3.14159) + 3.14159,
      1.0,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
