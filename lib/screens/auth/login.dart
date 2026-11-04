import 'package:auto_route/auto_route.dart';
import 'package:factline/api/exceptions.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/error_snackbar.dart';
import 'package:factline/widgets/textfield.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  const LoginScreen({
    super.key,
    required this.authService,
    required this.secureStorage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      User? user = await widget.authService.login(_email.text, _password.text);
      if (mounted) {
        if (user != null) {
          context.router.push(
            HomeRoute(
              authService: widget.authService,
              secureStorage: widget.secureStorage,
              user: user,
            ),
          );
        }
      }
    } on APIException catch (e) {
      if (mounted) {
        final prefix = e.code != null ? "${e.code}: " : "";
        showErrorSnackbar("$prefix${e.message}", context);
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackbar("Unexpected error: $error", context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xffD90429);

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FactlineMerriweather(
                    'Welcome back',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FactlineInter(
                    'Sign in to your Factline account',
                    style: const TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                  const SizedBox(height: 48),
                  RoundedInputField(
                    controller: _email,
                    hintText: 'Email Address',
                    icon: Icons.alternate_email_rounded,
                    isPassword: false,
                  ),
                  const SizedBox(height: 16),
                  RoundedInputField(
                    controller: _password,
                    hintText: 'Passcode',
                    icon: Icons.key_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),
                  _RoundedButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _login,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FactlineInter(
                        "Don't have an account? ",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.router.push(
                            CreateAccountRoute(
                              authService: widget.authService,
                              secureStorage: widget.secureStorage,
                            ),
                          );
                        },
                        child: FactlineInter(
                          'Create one',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _RoundedButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? color.withValues(alpha: 0.6) : color,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : FactlineMerriweather(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
