import 'package:auto_route/auto_route.dart';
import 'package:country_flags/country_flags.dart';
import 'package:factline/api/game.dart';
import 'package:factline/api/models/game.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GameQuesTab extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  final User user;

  const GameQuesTab({
    super.key,
    required this.authService,
    required this.secureStorage,
    required this.user,
  });

  @override
  State<GameQuesTab> createState() => _GameQuesTabState();
}

class _GameQuesTabState extends State<GameQuesTab> {
  int currentStep = 0;
  String? selectedCountryId;

  final List<Map<String, String>> countries = [
    {"name": "Australia", "id": "au"},
    {"name": "Brazil", "id": "br"},
    {"name": "Canada", "id": "ca"},
    {"name": "China", "id": "cn"},
    {"name": "Egypt", "id": "eg"},
    {"name": "France", "id": "fr"},
    {"name": "Germany", "id": "de"},
    {"name": "Greece", "id": "gr"},
    {"name": "Hong Kong", "id": "hk"},
    {"name": "India", "id": "in"},
    {"name": "Ireland", "id": "ie"},
    {"name": "Italy", "id": "it"},
    {"name": "Japan", "id": "jp"},
    {"name": "Netherlands", "id": "nl"},
    {"name": "Norway", "id": "no"},
    {"name": "Peru", "id": "pe"},
    {"name": "Philippines", "id": "ph"},
    {"name": "Portugal", "id": "pt"},
    {"name": "Romania", "id": "ro"},
    {"name": "Russian Federation", "id": "ru"},
    {"name": "Singapore", "id": "sg"},
    {"name": "Sweden", "id": "se"},
    {"name": "Switzerland", "id": "ch"},
    {"name": "Taiwan", "id": "tw"},
    {"name": "Ukraine", "id": "ua"},
    {"name": "United Kingdom", "id": "gb"},
    {"name": "United States", "id": "us"},
  ];

  @override
  Widget build(BuildContext context) {
    String title = "";
    if (currentStep == 0) title = "Select Your Country";
    if (currentStep == 1) title = "Ready to Play?";

    return Container(
      color: const Color(0xff0F0F0F),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (currentStep > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentStep = currentStep - 1;
                      });
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 8),
                if (currentStep != 1)
                  FactlineMerriweather(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (currentStep == 0) ...[
              Expanded(
                child: ListView.separated(
                  itemCount: countries.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final isSelected = selectedCountryId == country["id"];

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xffD90429).withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xffD90429)
                              : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CountryFlag.fromCountryCode(
                            country["id"]!,
                            height: 28,
                            width: 40,
                            shape: const RoundedRectangle(8),
                          ),
                        ),
                        title: FactlineInter(
                          country["name"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isSelected
                              ? const Color(0xffD90429)
                              : Colors.white24,
                        ),
                        onTap: () {
                          setState(() {
                            selectedCountryId = country["id"];
                            currentStep = 1;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else if (currentStep == 1) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xffD90429,
                          ).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xffD90429,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          color: Color(0xffD90429),
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FactlineMerriweather(
                        "Forensic Profile Ready",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FactlineInter(
                        "Evaluate the source signals for deepfake anomalies.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD90429),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (selectedCountryId == null) return;

                          try {
                            final gameApi = GameAPI();
                            final query = GameQuery(
                              country: selectedCountryId!,
                            );

                            final article = await gameApi.generateGameArticle(
                              query,
                            );

                            if (!context.mounted) return;
                            context.router.push(
                              GamePlayRoute(article: article),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xffD90429),
                                content: FactlineInter("Network Error: $e"),
                              ),
                            );
                          }
                        },
                        child: FactlineInter(
                          "BEGIN ASSESSMENT",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
