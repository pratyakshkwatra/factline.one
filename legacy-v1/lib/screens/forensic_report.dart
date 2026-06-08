import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:factline/api/models/post.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ForensicReportScreen extends StatelessWidget {
  final Post post;
  const ForensicReportScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final rawData = post.analysisRaw?.data ?? {};
    final scrapedIntel = rawData['scraped_intel'] as List? ?? [];
    final evidenceChain = post.evidenceChain;

    return Scaffold(
      backgroundColor: const Color(0xff090909),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FactlineInter(
          "DEEP FORENSIC REPORT",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Color(0xffD90429),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.router.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            _buildSectionTitle("INTELLIGENCE EVIDENCE CHAIN"),
            const SizedBox(height: 20),
            ...evidenceChain.asMap().entries.map(
              (e) => _buildEvidenceStep(e.key + 1, e.value),
            ),
            const SizedBox(height: 40),
            _buildSectionTitle("HISTORICAL GROUNDING"),
            const SizedBox(height: 20),
            _buildHistoricalContext(),
            const SizedBox(height: 40),
            _buildSectionTitle("CLAIM_BY_CLAIM_AUDIT"),
            const SizedBox(height: 20),
            if (post.claims.isEmpty)
              _buildEmptyState(
                "No specific claims were extracted for this audit.",
              )
            else
              ...post.claims.map((claim) => _buildClaimAuditCard(claim)),
            const SizedBox(height: 40),
            _buildSectionTitle("SCRAPED SOURCES & SOCIAL INTEL"),
            const SizedBox(height: 20),
            if (scrapedIntel.isEmpty)
              _buildEmptyState(
                "No external sources were indexed during this audit.",
              )
            else
              ...scrapedIntel.map((intel) => _buildIntelCard(intel)),
            const SizedBox(height: 40),
            _buildSectionTitle("RAW ANALYTIC TELEMETRY"),
            const SizedBox(height: 20),
            _buildRawDataViewer(rawData),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FactlineMerriweather(
          post.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _badge(
              "CONFIDENCE: ${post.confidenceScore ?? 0}%",
              Colors.blueAccent,
            ),
            const SizedBox(width: 12),
            _badge(
              "VERDICT: ${post.credibilityScore != null && post.credibilityScore! < 40 ? "HIGH RISK" : "VETTED"}",
              post.credibilityScore != null && post.credibilityScore! < 40
                  ? const Color(0xffD90429)
                  : Colors.greenAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: const Color(0xffD90429)),
        const SizedBox(width: 12),
        FactlineInter(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xffD90429).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xffD90429).withValues(alpha: 0.2),
              ),
            ),
            child: FactlineInter(
              step.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xffD90429),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FactlineInter(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelCard(dynamic intel) {
    final String url = intel['url'] ?? "";
    final String title = intel['title'] ?? "Unknown Source";
    final String snippet = intel['snippet'] ?? "";
    final String platform = intel['platform'] ?? "NEWS";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              _platformIcon(platform),
              const SizedBox(width: 8),
              _badge(platform, _platformColor(platform)),
              const Spacer(),
              if (url.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Colors.white38,
                  ),
                  onPressed: () => launchUrl(Uri.parse(url)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FactlineInter(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FactlineInter(
            snippet,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white38,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 12),
            FactlineInter(
              url,
              style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _platformIcon(String platform) {
    IconData icon;
    switch (platform) {
      case 'TWITTER':
        icon = Icons.alternate_email;
        break;
      case 'REDDIT':
        icon = Icons.reddit;
        break;
      case 'OFFICIAL':
        icon = Icons.account_balance;
        break;
      default:
        icon = Icons.newspaper;
    }
    return Icon(icon, color: Colors.white24, size: 14);
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'TWITTER':
        return Colors.blue;
      case 'REDDIT':
        return Colors.orange;
      case 'OFFICIAL':
        return Colors.greenAccent;
      default:
        return Colors.white24;
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FactlineInter(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: FactlineInter(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildRawDataViewer(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SelectableText(
        _formatJson(data),
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          color: Colors.greenAccent.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildHistoricalContext() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_edu, color: Colors.blueAccent, size: 24),
          const SizedBox(height: 16),
          FactlineInter(
            post.historicalContext ??
                "No broad historical grounding found for this report. Analysis focused on real-time forensics.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimAuditCard(Claim claim) {
    Color verdictColor;
    switch (claim.verdict?.toUpperCase()) {
      case 'VERIFIED':
        verdictColor = Colors.greenAccent;
        break;
      case 'REFUTED':
        verdictColor = const Color(0xffD90429);
        break;
      case 'CONTROVERSIAL':
        verdictColor = Colors.orangeAccent;
        break;
      default:
        verdictColor = Colors.white24;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              _badge(claim.verdict ?? "UNCERTAIN", verdictColor),
              const Spacer(),
              _badge(
                "CONFIDENCE: ${claim.confidence ?? "LOW"}",
                Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FactlineInter(
            claim.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FactlineInter(
            "FORENSIC REASONING",
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          FactlineInter(
            claim.reason ?? "Analysis in progress.",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          if (claim.historicalContext != null) ...[
            const SizedBox(height: 16),
            FactlineInter(
              "HISTORICAL CONTEXT",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.blueAccent.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            FactlineInter(
              claim.historicalContext!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueAccent.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
