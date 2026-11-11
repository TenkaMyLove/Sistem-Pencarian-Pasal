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
    final isTamu = user?.isTamu ?? true;
    final canTambah = user?.canTambahPeraturan ?? false;

    // Build tabs based on role (mirroring Web RBAC)
    final List<Widget> screens = [
      const SearchScreen(),
      if (!isTamu) const JadwalScreen(),
      if (canTambah) const TambahPeraturanScreen(),
      if (isAdmin) const KelolaAkunScreen(),
      const ProfileScreen(),
    ];

    final List<NavigationDestination> navItems = [
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Pencarian',
      ),
      if (!isTamu)
        const NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Jadwal',
        ),
      if (canTambah)
        const NavigationDestination(
          icon: Icon(Icons.post_add_outlined),
          selectedIcon: Icon(Icons.post_add),
          label: 'Tambah',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Kelola Akun',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    final titles = [
      'Pencarian Peraturan & Pasal',
      if (!isTamu) 'Jadwal Rapat Harmonisasi',
      if (canTambah) 'Tambah Peraturan via URL',
      if (isAdmin) 'Kelola Akun Pengguna',
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
          if (!isTamu)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent),
                borderRadius: AppRadius.tagR,
              ),
              child: Center(
                child: Text(
                  (user?.displayName ?? '').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: navItems,
        ),
      ),
    );
  }
}
