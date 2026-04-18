import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:factline/api/exceptions.dart' show APIException;
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/button.dart';
import 'package:factline/widgets/error_snackbar.dart';
import 'package:factline/widgets/textfield.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@RoutePage()
class CreateAccountScreen extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  const CreateAccountScreen({
    super.key,
    required this.authService,
    required this.secureStorage,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xffD90429);

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 48,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 32),
                FactlineMerriweather(
                  'Create an account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FactlineInter(
                  'Start verifying stories with Factline',
                  style: const TextStyle(fontSize: 14, color: Colors.white38),
                ),
                const SizedBox(height: 48),
                RoundedInputField(
                  controller: _emailController,
                  hintText: 'Work Email Address',
                  icon: Icons.alternate_email_rounded,
                  isPassword: false,
                ),
                const SizedBox(height: 16),
                RoundedInputField(
                  controller: _passwordController,
                  hintText: 'Security Passcode',
                  icon: Icons.key_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                RoundedButton(
                  label: 'Create account',
                  color: primary,
                  isLoading: _isLoading,
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            await widget.authService.register(
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.greenAccent,
                                  content: FactlineInter(
                                    "Account Initialized. Redirecting to access portal...",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                              Timer(const Duration(seconds: 3), () {
                                if (context.mounted) {
                                  context.router.pop();
                                }
                              });
                            }
                          } on APIException catch (exception) {
                            if (context.mounted) {
                              showErrorSnackbar(
                                "${exception.code}: ${exception.message}",
                                context,
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showErrorSnackbar(
                                "Critical Initialization Error. Try again.",
                                context,
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FactlineInter(
                      "Already have an account? ",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: FactlineInter(
                        'Sign in',
                        style: const TextStyle(
                          color: primary,
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
    );
  }
}
