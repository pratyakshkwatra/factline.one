import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:factline/api/game.dart';
import 'package:factline/api/models/game.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';

@RoutePage()
class GamePlayScreen extends StatefulWidget {
  final GameArticle article;

  const GamePlayScreen({super.key, required this.article});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  late GameArticle _currentArticle;
  bool? userGuess;
  bool revealed = false;
  int _score = 0;
  int _streak = 0;
  bool _isLoadingNext = false;
  bool _autoContinueEnabled = true;

  // Scanning animation controller for the intelligence briefing card
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  // Reveal verdict animation controller
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Auto-continue countdown timer
  Timer? _countdownTimer;
  int _countdownSeconds = 4;
  late AnimationController _countdownAnimController;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;

    // Scan beam animation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    // Reveal animations
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeIn),
    );

    // Countdown animation (4 seconds)
    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scannerController.dispose();
    _revealController.dispose();
    _countdownAnimController.dispose();
    super.dispose();
  }

  void _onAnswer(bool guess) {
    if (revealed) return;
    setState(() {
      userGuess = guess;
      revealed = true;
    });

    final isCorrect = (userGuess == _currentArticle.isFake);
    if (isCorrect) {
      _score += 50;
      _streak += 1;
    } else {
      _streak = 0;
    }

    _revealController.forward(from: 0.0);

    if (_autoContinueEnabled) {
      _startAutoContinueCountdown();
    }
  }

  void _startAutoContinueCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 4;
    _countdownAnimController.forward(from: 0.0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds -= 1;
        } else {
          timer.cancel();
          _loadNextCase();
        }
      });
    });
  }

  void _cancelAutoContinue() {
    _countdownTimer?.cancel();
    _countdownAnimController.stop();
    setState(() {
      _autoContinueEnabled = false;
    });
  }

  Future<void> _loadNextCase() async {
    _countdownTimer?.cancel();
    if (_isLoadingNext) return;

    setState(() {
      _isLoadingNext = true;
    });

    try {
      final nextArticle = await GameAPI().generateGameArticle(
        GameQuery(country: "us"),
      );
      if (!mounted) return;
      setState(() {
        _currentArticle = nextArticle;
        revealed = false;
        userGuess = null;
        _isLoadingNext = false;
        _countdownSeconds = 4;
      });
      _revealController.reset();
      _countdownAnimController.reset();
      if (_scannerController.isAnimating == false) {
        _scannerController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNext = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xffD90429),
            content: FactlineInter("Notice: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = revealed && (userGuess == _currentArticle.isFake);

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.router.pop(),
        ),
        title: Row(
          children: [
            const FactlineMerriweather(
              "Truth or Deepfake",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Score & Streak badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 4),
                  FactlineInter(
                    "$_score XP",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_streak > 1) ...[
                    const SizedBox(width: 8),
                    FactlineInter(
                      "🔥 $_streak",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable briefing content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Briefing Card with Radar Scan Animation
                    AnimatedBuilder(
                      animation: _scannerAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.035),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: revealed
                                      ? (isCorrect
                                          ? Colors.greenAccent.withValues(alpha: 0.5)
                                          : Colors.redAccent.withValues(alpha: 0.5))
                                      : Colors.white12,
                                  width: revealed ? 1.8 : 1.0,
                                ),
                                boxShadow: revealed
                                    ? [
                                        BoxShadow(
                                          color: isCorrect
                                              ? Colors.greenAccent.withValues(alpha: 0.15)
                                              : Colors.redAccent.withValues(alpha: 0.15),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffD90429).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: revealed
                                                    ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
                                                    : const Color(0xffD90429),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const FactlineInter(
                                              "INTELLIGENCE REPORT",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xffD90429),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const FactlineInter(
                                        "LIVE SIMULATION",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white30,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  FactlineMerriweather(
                                    _currentArticle.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FactlineInter(
                                    _currentArticle.body,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      height: 1.65,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Scanning Hologram Beam (active when unrevealed)
                            if (!revealed)
                              Positioned(
                                top: _scannerAnimation.value * 280,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xffD90429).withValues(alpha: 0.8),
                                        Colors.white.withValues(alpha: 0.9),
                                        const Color(0xffD90429).withValues(alpha: 0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffD90429).withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Verdict reveal animated panel
                    if (revealed)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.shade900.withValues(alpha: 0.25)
                                  : Colors.red.shade900.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 10),
                                    FactlineInter(
                                      isCorrect
                                          ? "CORRECT ASSESSMENT (+50 XP)"
                                          : "ANALYSIS FAILED",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FactlineInter(
                                  "Your Choice: ${userGuess! ? "Fabricated / Fake" : "Verified / Authentic"}\nGround Truth: ${_currentArticle.isFake ? "Doctored Misinformation" : "Legitimate Authentic News"}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                if (_autoContinueEnabled) ...[
                                  const SizedBox(height: 14),
                                  // Animated linear countdown bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: AnimatedBuilder(
                                      animation: _countdownAnimController,
                                      builder: (context, _) {
                                        return LinearProgressIndicator(
                                          value: 1.0 - _countdownAnimController.value,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isCorrect ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                          minHeight: 4,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      FactlineInter(
                                        "Next case in $_countdownSeconds seconds...",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _cancelAutoContinue,
                                        child: const FactlineInter(
                                          "PAUSE",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action controller
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: !revealed
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.verified_rounded, size: 20),
                            label: const FactlineInter(
                              "REAL",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            onPressed: () => _onAnswer(false),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD90429),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.warning_amber_rounded, size: 20),
                            label: const FactlineInter(
                              "FAKE",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            onPressed: () => _onAnswer(true),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD90429),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: _isLoadingNext
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.skip_next_rounded, size: 22),
                            label: FactlineInter(
                              _isLoadingNext ? "GENERATING..." : "NEXT CASE NOW",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            onPressed: _isLoadingNext ? null : _loadNextCase,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
