import 'package:flutter/material.dart';

import 'constants.dart';
import 'widgets/hero_section.dart';
import 'widgets/sign_in_section.dart';

/// High-level wrapper that stitches together the hero and sign-in sections.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
              HeroSection(),
              SignInSection(),
            ],
          ),
        ),
      ),
    );
  }
}
