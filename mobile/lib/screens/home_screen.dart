import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'search_screen.dart';
import 'jadwal_screen.dart';
import 'tambah_peraturan_screen.dart';
import 'kelola_akun_screen.dart';
import 'profile_screen.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isPengelola = user?.isPengelola ?? false;

    // Build tabs based on role
    final List<Widget> screens = [
      const SearchScreen(),
      const JadwalScreen(),
      if (isAdmin)
        const KelolaAkunScreen()
      else if (isPengelola)
        const TambahPeraturanScreen(),
      const ProfileScreen(),
    ];

    final List<NavigationDestination> navItems = [
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Pencarian',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today),
        label: 'Jadwal Rapat',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Kelola Akun',
        )
      else if (isPengelola)
        const NavigationDestination(
          icon: Icon(Icons.post_add_outlined),
          selectedIcon: Icon(Icons.post_add),
          label: 'Tambah Peraturan',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil & Host',
      ),
    ];

    final titles = [
      'Pencarian Peraturan & Pasal',
      'Jadwal Rapat Harmonisasi',
      if (isAdmin)
        'Kelola Akun Pengguna'
      else if (isPengelola)
        'Tambah Peraturan via URL',
      'Profil & Pengaturan',
    ];

    // Ensure index within range
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: Colors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'Kanwil Kemenkumham Kalsel',
              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(217)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user?.peran ?? 'Tamu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan Host Server',
            onPressed: () => SettingsDialog.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: navItems,
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.badgeBlueBg,
      ),
    );
  }
}
