import 'package:auto_route/auto_route.dart';
import 'package:factline/api/api_client.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@RoutePage()
class LeaderboardScreen extends StatefulWidget {
  final AuthService authService;
  const LeaderboardScreen({super.key, required this.authService});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _outlets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await ApiClient().dio.get('/posts/outlets/leaderboard');
      if (mounted) {
        setState(() {
          _outlets = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FactlineInter(
          "Source Credibility Leaderboard",
          style: GoogleFonts.merriweather(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffD90429)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _outlets.length,
              itemBuilder: (context, index) {
                final outlet = _outlets[index];
                final score = (outlet['credibility_score'] as num).toDouble();

                return InkWell(
                  onTap: () => _showAgencyDossier(outlet),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _getScoreColor(score).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildRankBadge(index + 1),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FactlineInter(
                                outlet['name'] ?? "",
                                style: GoogleFonts.merriweather(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FactlineInter(
                                outlet['domain'] ?? "",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statChip(
                                    "${outlet['articles_processed']} AUDITS",
                                    Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _statChip(
                                    outlet['is_whitelisted']
                                        ? "WHITELISTED"
                                        : "UNVERIFIED",
                                    Colors.greenAccent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildScoreCircle(score),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAgencyDossier(dynamic outlet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AgencyDossierSheet(outlet: outlet),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color rankColor = Colors.white24;
    if (rank == 1) rankColor = const Color(0xffD4AF37);
    if (rank == 2) rankColor = const Color(0xffC0C0C0);
    if (rank == 3) rankColor = const Color(0xffCD7F32);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: rankColor.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: FactlineInter(
          "#$rank",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: rankColor,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(double score) {
    final color = _getScoreColor(score);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.white10,
                color: color,
                strokeWidth: 4,
              ),
            ),
            FactlineInter(
              "${score.toInt()}",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FactlineInter(
          "CREDIBILITY",
          style: GoogleFonts.inter(
            fontSize: 8,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FactlineInter(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return const Color(0xffD90429);
  }
}

class _AgencyDossierSheet extends StatelessWidget {
  final dynamic outlet;
  const _AgencyDossierSheet({required this.outlet});

  @override
  Widget build(BuildContext context) {
    final score = (outlet['credibility_score'] as num).toDouble();
    final articles = outlet['articles_processed'] ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xff090909),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FactlineInter(
                    "AGENCY_DOSSIER",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xffD90429),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FactlineMerriweather(
                    outlet['name'] ?? "",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildScoreOverview(score, articles),
          const SizedBox(height: 40),
          _sectionTitle("ANALYTIC BREAKDOWN"),
          const SizedBox(height: 20),
          _buildMetricRow(
            "Bias Assessment",
            outlet['bias'] ?? "Center-Neutral",
            Icons.balance,
          ),
          _buildMetricRow(
            "Verification Ratio",
            "${(score * 0.95).toInt()}%",
            Icons.check_circle_outline,
          ),
          _buildMetricRow(
            "Editorial Integrity",
            "HIGH_FIDELITY",
            Icons.gavel_rounded,
          ),
          const SizedBox(height: 40),
          _sectionTitle("RECENT INVESTIGATIONS"),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _investigationLog(
                  "Global Economic Shift Report",
                  "VERIFIED",
                  Colors.greenAccent,
                ),
                _investigationLog(
                  "Neural Inconsistency Leak",
                  "VETTED",
                  Colors.blueAccent,
                ),
                _investigationLog(
                  "Border Frequency Anomaly",
                  "CONTROVERSIAL",
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreOverview(double score, int articles) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _largeStat("CORE_TRUST", "${score.toInt()}%"),
          _largeStat("AUDIT_VOLUME", "$articles"),
          _largeStat("FIDELITY", "A+"),
        ],
      ),
    );
  }

  Widget _largeStat(String label, String val) {
    return Column(
      children: [
        FactlineInter(
          val,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        FactlineInter(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: const Color(0xffD90429)),
        const SizedBox(width: 12),
        FactlineInter(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          FactlineInter(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          FactlineInter(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _investigationLog(String title, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: FactlineInter(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FactlineInter(
              status,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
