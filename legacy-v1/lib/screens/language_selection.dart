import 'package:auto_route/auto_route.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LanguageSelectionScreen extends StatefulWidget {
  final AuthService authService;

  const LanguageSelectionScreen({super.key, required this.authService});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _currentLanguage;
  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Gujarati',
    'Bengali',
    'Punjabi',
    'Malayalam',
    'Urdu',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Chinese',
    'Arabic',
    'Turkish',
  ];

  final Map<String, String> _languageDisplay = {
    'English': 'English (Universal Truth-Signal)',
    'Hindi': 'Hindi (हिन्दी)',
    'Marathi': 'Marathi (मराठी)',
    'Tamil': 'Tamil (தமிழ்)',
    'Telugu': 'Telugu (తెలుగు)',
    'Kannada': 'Kannada (ಕನ್ನಡ)',
    'Gujarati': 'Gujarati (ગુજરાતી)',
    'Bengali': 'Bengali (বাংলা)',
    'Punjabi': 'Punjabi (ਪੰਜਾਬੀ)',
    'Malayalam': 'Malayalam (മലയാളം)',
    'Urdu': 'Urdu (اردو)',
    'Spanish': 'Spanish (Español)',
    'French': 'French (Français)',
    'German': 'German (Deutsch)',
    'Italian': 'Italian (Italiano)',
    'Portuguese': 'Portuguese (Português)',
    'Russian': 'Russian (Русский)',
    'Japanese': 'Japanese (日本語)',
    'Chinese': 'Chinese (中文)',
    'Arabic': 'Arabic (العربية)',
    'Turkish': 'Turkish (Türkçe)',
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.authService.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.router.back(),
        ),
        title: FactlineMerriweather(
          "Intelligence Language",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.separated(
          itemCount: _languages.length,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final key = _languages[index];
            final name = _languageDisplay[key] ?? key;
            final isSelected = _currentLanguage == key;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xffD90429).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xffD90429)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.language_rounded,
                  color: isSelected ? const Color(0xffD90429) : Colors.white24,
                ),
                title: FactlineInter(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xffD90429),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white10,
                      ),
                onTap: () {
                  widget.authService.selectedLanguage = key;
                  if (context.mounted) {
                    context.router.back();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
