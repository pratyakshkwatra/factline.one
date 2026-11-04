import 'dart:ui';
import 'package:factline/api/auth.dart';
import 'package:factline/router/router.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress uncaught asynchronous font network lookup exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    final err = error.toString();
    if (err.contains('fonts.gstatic.com') || err.contains('Failed to load font')) {
      debugPrint("Handled font lookup notice: $error");
      return true;
    }
    return false;
  };

  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('fonts.gstatic.com') ||
        details.exceptionAsString().contains('Failed to load font')) {
      debugPrint("Handled font framework error: ${details.exception}");
      return;
    }
    FlutterError.presentError(details);
  };
  try {
    await FMTCObjectBoxBackend().initialise(maxDatabaseSize: 100000000);
    await FMTCStore('mapStore').manage.create();
    try {
      await FMTCStore('factline_dark_v2').manage.delete();
      await FMTCStore('factline_hq').manage.delete();
    } catch (_) {}
    await FMTCStore('factline_esri_v1').manage.create();
  } catch (e) {
    debugPrint("Map tile caching initialization notice: $e");
  }

  final authAPI = AuthAPI();
  final secureStorage = const FlutterSecureStorage();
  final authService = AuthService(authAPI, secureStorage);
  await authService.init();
  await TranslationService().init();

  runApp(MyApp(authService: authService, secureStorage: secureStorage));
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;

  const MyApp({
    super.key,
    required this.authService,
    required this.secureStorage,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.authService.languageNotifier,
      builder: (context, language, child) {
        return MaterialApp.router(
          key: ValueKey(language),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xff0F0F0F),
            primaryColor: const Color(0xffD90429),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xffD90429),
              secondary: Color(0xffEF233C),
              surface: Color(0xff1A1A1A),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          routerConfig: _appRouter.config(),
        );
      },
    );
  }
}
