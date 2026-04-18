import 'package:auto_route/auto_route.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/screens/dossier.dart';
import 'package:factline/screens/game_ques.dart';
import 'package:factline/screens/home.dart';
import 'package:factline/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:factline/screens/map.dart';
import 'package:factline/screens/settings.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  final User user;
  const HomeScreen({
    super.key,
    required this.authService,
    required this.secureStorage,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xff0F0F0F),
      bottomNavigationBar: CrystalNavigationBar(
        currentIndex: _currentIndex,
        indicatorColor: Colors.transparent,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        borderWidth: 2,
        enableFloatingNavBar: true,
        enablePaddingAnimation: true,
        outlineBorderColor: Colors.white10,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
        onTap: (val) {
          setState(() {
            _currentIndex = val;
          });
        },
        items: [
          CrystalNavigationBarItem(
            icon: Icons.home_rounded,
            unselectedIcon: Icons.home_outlined,
            selectedColor: const Color(0xffD90429),
          ),
          CrystalNavigationBarItem(
            icon: Icons.folder_copy_rounded,
            unselectedIcon: Icons.folder_copy_outlined,
            selectedColor: const Color(0xffD90429),
          ),
          CrystalNavigationBarItem(
            icon: Icons.grid_view_rounded,
            unselectedIcon: Icons.grid_view_outlined,
            selectedColor: const Color(0xffD90429),
          ),
          CrystalNavigationBarItem(
            icon: Icons.map_rounded,
            unselectedIcon: Icons.map_outlined,
            selectedColor: const Color(0xffD90429),
          ),
          CrystalNavigationBarItem(
            icon: Icons.settings_rounded,
            unselectedIcon: Icons.settings_outlined,
            selectedColor: const Color(0xffD90429),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTab(
              authService: widget.authService,
              secureStorage: widget.secureStorage,
              user: widget.user,
            ),
            DossierTab(authService: widget.authService),
            GameQuesTab(
              authService: widget.authService,
              secureStorage: widget.secureStorage,
              user: widget.user,
            ),
            MapScreen(
              authService: widget.authService,
              user: widget.user,
            ),
            SettingsTab(
              authService: widget.authService,
              secureStorage: widget.secureStorage,
              user: widget.user,
            ),
          ],
        ),
      ),
    );
  }
}
