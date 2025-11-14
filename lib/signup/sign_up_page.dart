import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../home/home_page.dart';
import '../login/constants.dart';
import '../login/login_page.dart';

/// Landing page shown when users choose to sign up from the login flow.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenBackground,
      body: const SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignUpHeader(),
              _SignUpFormShell(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpFormShell extends StatefulWidget {
  const _SignUpFormShell();

  @override
  State<_SignUpFormShell> createState() => _SignUpFormShellState();
}

/// Hosts the white container, form controllers, and CTA logic.
class _SignUpFormShellState extends State<_SignUpFormShell> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  late final List<_TextFieldConfig> _fieldConfigs;

  @override
  void initState() {
    super.initState();
    _fieldConfigs = [
      _TextFieldConfig(
        label: 'First Name',
        icon: Icons.person_outline,
        controller: _firstNameController,
      ),
      _TextFieldConfig(
        label: 'Last Name',
        icon: Icons.person,
        controller: _lastNameController,
      ),
      _TextFieldConfig(
        label: 'Email Address',
        icon: Icons.mail_outline,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
      ),
      _TextFieldConfig(
        label: 'Company',
        icon: Icons.apartment_outlined,
        controller: _companyController,
      ),
      _TextFieldConfig(
        label: 'Job Title',
        icon: Icons.badge_outlined,
        controller: _jobTitleController,
      ),
    ];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in _fieldConfigs.asMap().entries) ...[
              // Base text fields get generated from metadata for consistency.
              _buildField(entry.value),
              if (entry.key == 2) ...[
                // Password slot lives after email to match UX spec.
                const SizedBox(height: 16),
                _buildPasswordField(),
              ],
              if (entry.key != _fieldConfigs.length - 1)
                const SizedBox(height: 16),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSignUpYellow,
                  foregroundColor: kHeroBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kHeroBlue),
                        ),
                      )
                    : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: kSecondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _handleBackToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: kHeroBlue,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final payload = {
      'name': '$firstName $lastName'.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'first_name': firstName,
      'last_name': lastName,
      'job_title': _jobTitleController.text.trim(),
      'company_name': _companyController.text.trim(),
    };

    setState(() => _isSubmitting = true);

    try {
      final response = await http
          .post(
            Uri.parse(EnvConfig.signUpEndpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final status = response.statusCode;
      final isSuccess = status == 200 || status == 201;
      final message = _extractMessage(
        response.body,
        fallback:
            isSuccess ? 'Account created successfully.' : 'Sign-up failed ($status).',
      );

      if (isSuccess) {
        _showSnack(message, isError: false);
        _goToHomePage();
      } else {
        _showSnack(message);
      }
    } on TimeoutException {
      _showSnack('Request timed out. Please try again.');
    } catch (error) {
      _showSnack('Sign-up failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateInputs() {
    if (_firstNameController.text.trim().isEmpty) {
      return 'First name is required.';
    }
    if (_lastNameController.text.trim().isEmpty) {
      return 'Last name is required.';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
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
              if (first is String && first.isNotEmpty) return first;
            } else if (value is String && value.isNotEmpty) {
              return value;
            }
          }
        }
        if (decoded['message'] is String && (decoded['message'] as String).isNotEmpty) {
          return decoded['message'] as String;
        }
      }
    } catch (_) {
      // Ignore decoding issues and fall back to provided message.
    }
    return fallback;
  }

  void _goToHomePage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  /// Returns the user to the login screen regardless of navigation history.
  void _handleBackToLogin() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(
              color: Color(0xFF8C95A3),
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF8C95A3),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF8C95A3),
              ),
            ),
            border: _outlineBorder(),
            enabledBorder: _outlineBorder(),
            focusedBorder: _outlineBorder(color: kHeroBlue),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildField(_TextFieldConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(config.label),
        const SizedBox(height: 8),
        TextField(
          controller: config.controller,
          keyboardType: config.keyboardType,
          decoration: InputDecoration(
            hintText: 'Enter ${config.label}'.toLowerCase(),
            hintStyle: const TextStyle(
              color: Color(0xFF8C95A3),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              config.icon,
              color: const Color(0xFF8C95A3),
            ),
            border: _outlineBorder(),
            enabledBorder: _outlineBorder(),
            focusedBorder: _outlineBorder(color: kHeroBlue),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: kPrimaryText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  OutlineInputBorder _outlineBorder({Color color = kBorderColor}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}

/// Reuses the hero styling to keep login and sign-up headers aligned.
class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Container(
      width: double.infinity,
      color: kHeroBlue,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: kAccentYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: kHeroBlue,
              size: 42,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Conference Quest',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'EngageU $currentYear • Antwerp',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create Your Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight descriptor for rendering a labeled text field.
class _TextFieldConfig {
  const _TextFieldConfig({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
}
