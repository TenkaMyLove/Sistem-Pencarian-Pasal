import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'jadwal_screen.dart';
import 'kelola_akun_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'settings_dialog.dart';
import 'tambah_peraturan_screen.dart';

class _NavTab {
  final Widget screen;
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({
    required this.screen,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool? _serverOnline;

  @override
  void initState() {
    super.initState();
    _checkHealthQuietly();
  }

  Future<void> _checkHealthQuietly() async {
    final res = await ApiService().checkHealth();
    if (mounted) {
      setState(() => _serverOnline = res['success'] == true);
    }
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'TM';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isTamu = user?.isTamu ?? true;
    final canTambah = user?.canTambahPeraturan ?? false;

    final tabs = <_NavTab>[
      const _NavTab(
        screen: SearchScreen(),
        label: 'Pencarian',
        subtitle: 'PENCARIAN',
        icon: Icons.search,
        activeIcon: Icons.search,
      ),
      if (!isTamu)
        const _NavTab(
          screen: JadwalScreen(),
          label: 'Jadwal Rapat',
          subtitle: 'JADWAL RAPAT',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
        ),
      if (canTambah)
        const _NavTab(
          screen: TambahPeraturanScreen(),
          label: 'Tambah',
          subtitle: 'TAMBAH PERATURAN',
          icon: Icons.post_add_outlined,
          activeIcon: Icons.post_add,
        ),
      if (isAdmin)
        const _NavTab(
          screen: KelolaAkunScreen(),
          label: 'Kelola Akun',
          subtitle: 'KELOLA AKUN',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
        ),
    ];

    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    final displayName = user?.displayName ?? 'Tamu';
    final initials = _initials(displayName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySlate,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'P3H KEMENKUM KALSEL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tabs[_currentIndex].subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Server API config & status indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.dns_outlined, color: Colors.white, size: 21),
                tooltip: 'Pengaturan Server API',
                onPressed: () async {
                  await SettingsDialog.show(context);
                  _checkHealthQuietly();
                },
              ),
              if (_serverOnline != null)
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _serverOnline! ? const Color(0xFF22C55E) : AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 2),
          // Profile avatar button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Tooltip(
              message: 'Profil & Hak Akses ($displayName)',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _checkHealthQuietly();
                },
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(210),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
                ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: tabs.length > 1
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 62,
                  child: Row(
                    children: List.generate(tabs.length, (i) {
                      final tab = tabs[i];
                      final selected = _currentIndex == i;
                      final color = selected ? AppColors.primaryLight : AppColors.textSecondary;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _currentIndex = i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
