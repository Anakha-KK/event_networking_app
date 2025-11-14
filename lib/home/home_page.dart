import 'package:flutter/material.dart';

/// Landing page shown after successful sign-in.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Lightweight tab bodies so navigation can be wired before real pages exist.
  final List<Widget> _pages = const [
    _SimplePlaceholder(title: 'Home'),
    _SimplePlaceholder(title: 'Scan'),
    _SimplePlaceholder(title: 'Leaderboard'),
    _SimplePlaceholder(title: 'Challenges'),
    _SimplePlaceholder(title: 'Profile'),
  ];

  // Controls the app-bar title/subtitle and trailing icons for each tab.
  static const _headerConfigs = <_HeaderConfig>[
    _HeaderConfig(
      title: 'Conference Quest',
      subtitle: 'Tech Summit 2024',
      trailingIcon: Icons.notifications_none_rounded,
      showNotificationDot: true,
      uppercaseTitle: true,
      leadingIcon: Icons.emoji_events_rounded,
      leadingIconColor: Color(0xFF0B5C87),
      leadingBackgroundColor: Color(0xFFFCC63D),
    ),
    _HeaderConfig(
      title: 'QR Scanner',
      subtitle: 'Scan to connect with attendees',
      trailingIcon: Icons.info_outline_rounded,
    ),
    _HeaderConfig(
      title: 'Leaderboard',
      subtitle: 'EngageU 2025 • Antwerp',
      trailingIcon: Icons.notifications_none_rounded,
    ),
    _HeaderConfig(
      title: 'Challenges',
      subtitle: 'Track streaks & progress',
      trailingIcon: Icons.flag_outlined,
    ),
    _HeaderConfig(
      title: 'Profile',
      subtitle: 'Manage your account',
      trailingIcon: Icons.settings_outlined,
    ),
  ];

  void _handleNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: SafeArea(
          bottom: false,
          child: _HeaderBar(config: _headerConfigs[_selectedIndex]),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _handleNavTap,
        selectedItemColor: const Color(0xFFF4B400),
        unselectedItemColor: const Color(0xFF8C95A3),
        selectedIconTheme: const IconThemeData(color: Color(0xFFF4B400)),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF8C95A3)),
        selectedLabelStyle: const TextStyle(
          color: Color(0xFFF4B400),
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          color: Color(0xFF8C95A3),
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        elevation: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_rounded),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SimplePlaceholder extends StatelessWidget {
  const _SimplePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Gives every tab a neutral backdrop until the real screen is implemented.
    return Container(
      color: const Color(0xFFF4F6F8),
      alignment: Alignment.center,
      child: Text(
        '$title Page',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4E5969),
        ),
      ),
    );
  }
}

class _HeaderConfig {
  const _HeaderConfig({
    required this.title,
    required this.subtitle,
    this.trailingIcon,
    this.showNotificationDot = false,
    this.uppercaseTitle = false,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingBackgroundColor,
  });

  final String title;
  final String subtitle;
  final IconData? trailingIcon;
  final bool showNotificationDot;
  final bool uppercaseTitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingBackgroundColor;
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.config});

  final _HeaderConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B5C87),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0B5C87),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (config.leadingIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: config.leadingBackgroundColor ?? Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config.leadingIcon,
                  color: config.leadingIconColor ?? Colors.white,
                  size: 26,
                ),
              ),
            )
          else
            const SizedBox(width: 20), // Keeps breathing room before the title stack.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.uppercaseTitle ? config.title.toUpperCase() : config.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: config.uppercaseTitle ? 22 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (config.trailingIcon != null)
            _HeaderIcon(
              icon: config.trailingIcon!,
              showDot: config.showNotificationDot,
            ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.showDot = false});

  final IconData icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (showDot)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFCC63D),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
