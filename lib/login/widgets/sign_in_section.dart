import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../../home/home_page.dart';
import '../../signup/sign_up_page.dart';
import '../constants.dart';

/// Card-like white area that hosts the email/password form and social CTAs.
class SignInSection extends StatefulWidget {
  const SignInSection({super.key});

  @override
  State<SignInSection> createState() => _SignInSectionState();
}

class _SignInSectionState extends State<SignInSection> {
  static final RegExp _emailRegExp =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: EnvConfig.googleServerClientId.isEmpty
        ? null
        : EnvConfig.googleServerClientId,
  );
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode()..addListener(_handleFocusChange);
    _passwordFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() => setState(() {});

  @override
  void dispose() {
    _emailFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Draws the custom border + fill so both TextFields share identical chrome.
  Widget _inputWrapper({
    required FocusNode focusNode,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: kFieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus ? kHeroBlue : kBorderColor,
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      ),
    );
  }

  String _extractMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['errors'] is Map<String, dynamic>) {
          final errors = decoded['errors'] as Map<String, dynamic>;
          for (final entry in errors.entries) {
            final value = entry.value;
            if (value is List && value.isNotEmpty) {
              final first = value.first;
              if (first is String && first.isNotEmpty) {
                return first;
              }
            } else if (value is String && value.isNotEmpty) {
              return value;
            }
          }
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } catch (_) {
      // Ignore decoding errors and use fallback.
    }
    return fallback;
  }

  /// Client-side guardrails so we avoid noisy backend requests.
  String? _validateInputs(String email, String password) {
    if (email.isEmpty) return 'Email is required.';
    if (!_emailRegExp.hasMatch(email)) return 'Enter a valid email.';
    if (password.isEmpty) return 'Password is required.';
    return null;
  }

  String _normalizeBackendMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('selected email is invalid')) {
      return 'Invalid credentials.';
    }
    return message;
  }

  /// Uses backend response codes/messages to decide what the user sees next.
  void _handleResponse(http.Response response) {
    final status = response.statusCode;
    bool isSuccess = false;
    String fallback;

    switch (status) {
      case 200:
        fallback = 'Login successful.';
        isSuccess = true;
        break;
      case 401:
      case 404:
      case 422:
        fallback = 'Invalid credentials.';
        break;
      default:
        fallback = 'Sign-in failed ($status).';
    }

    final message = _normalizeBackendMessage(
      _extractMessage(response.body, fallback: fallback),
    );

    _showSnack(message, isError: !isSuccess);

    if (isSuccess) {
      _goToHomePage();
    }
  }

  void _goToHomePage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  /// Handles sign-in CTA: validate form, hit API, then react to response.
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validationError = _validateInputs(email, password);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http
          .post(
            Uri.parse(EnvConfig.authCheckEndpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _handleResponse(response);
    } on TimeoutException {
      _showSnack('Request timed out. Is the API running?');
    } catch (error) {
      _showSnack('Sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleSubmitting = true);

    try {
      // Always sign out first so users can pick a different Google account.
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Ignore disconnect errors when no session exists.
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        _showSnack('Google sign-in was cancelled.');
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _showSnack('Unable to retrieve Google token. Please try again.');
        return;
      }

      final response = await http
          .post(
            Uri.parse(EnvConfig.googleSignInEndpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final status = response.statusCode;
      final isSuccess = status == 200 || status == 201;
      final message = _extractMessage(
        response.body,
        fallback:
            isSuccess ? 'Google sign-in successful.' : 'Google sign-in failed ($status).',
      );

      _showSnack(message, isError: !isSuccess);

      if (isSuccess) {
        _goToHomePage();
      }
    } on TimeoutException {
      _showSnack('Google sign-in timed out. Please try again.');
    } catch (error) {
      _showSnack('Google sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Slide the card upward to create the overlapping effect with the hero.
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Address',
                  style: TextStyle(
                    color: kPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _inputWrapper(
                  focusNode: _emailFocusNode,
                  child: TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kPrimaryText,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        color: Color(0xFF8C95A3),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.mail_rounded,
                        color: Color(0xFF8C95A3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Password',
                  style: TextStyle(
                    color: kPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _inputWrapper(
                  focusNode: _passwordFocusNode,
                  child: TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSignIn(),
                    autocorrect: false,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kPrimaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8C95A3),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF8C95A3),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8C95A3),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: kHeroBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: kSecondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: kHeroBlue,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentYellow,
                      foregroundColor: kHeroBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _handleSignIn,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(kHeroBlue),
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        color: kBorderColor,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          color: Color(0xFF8C95A3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: kBorderColor,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  iconColor: Color(0xFFEA4335),
                  iconSize: 34,
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isGoogleSubmitting,
                ),
                const SizedBox(height: 14),
                const _SocialButton(
                  icon: Icons.window_rounded,
                  label: 'Continue with Microsoft',
                  iconColor: Color(0xFF2F7FE0),
                  iconSize: 30,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: kSecondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignUpPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kHeroBlue,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Sign up here'),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.iconSize = 28,
    this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final double iconSize;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kBorderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: kPrimaryText,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kHeroBlue),
                ),
              )
            else ...[
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 12),
              Text(label),
            ],
          ],
        ),
      ),
    );
  }
}
