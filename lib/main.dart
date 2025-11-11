import 'package:flutter/material.dart';

import 'login/login_page.dart';

void main() {
  runApp(const EventNetworkingApp());
}

class EventNetworkingApp extends StatelessWidget {
  const EventNetworkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Networking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C4E78),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
