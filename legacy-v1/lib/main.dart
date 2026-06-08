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
  await FMTCObjectBoxBackend().initialise(maxDatabaseSize: 100000000);
  await FMTCStore('mapStore').manage.create();
  await FMTCStore('factline_hq').manage.create();

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
