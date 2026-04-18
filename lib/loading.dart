import 'package:auto_route/auto_route.dart';
import 'package:factline/api/auth.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@RoutePage()
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

AuthAPI _authAPI = AuthAPI();
FlutterSecureStorage _secureStorage = FlutterSecureStorage();

class _LoadingScreenState extends State<LoadingScreen> {
  late final AuthService _authService;
  @override
  void initState() {
    _authService = AuthService(_authAPI, _secureStorage);
    checkAndLoad();

    super.initState();
  }

  Future<void> checkAndLoad() async {
    User? user = await _authService.initializeSession();
    if (user != null) {
      if (mounted) {
        context.router.push(
          HomeRoute(
            authService: _authService,
            secureStorage: _secureStorage,
            user: user,
          ),
        );
      }
    } else {
      if (mounted) {
        context.router.push(
          LoginRoute(authService: _authService, secureStorage: _secureStorage),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 8,
              color: Colors.black,
              strokeCap: StrokeCap.round,
            ),
          ],
        ),
      ),
    );
  }
}
