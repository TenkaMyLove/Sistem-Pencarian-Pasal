import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'settings_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _checkingServer = false;
  bool? _serverOnline;
  String? _serverDetail;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    setState(() {
      _checkingServer = true;
    });
    try {
      final res = await ApiService().checkHealth();
      if (!mounted) return;
      final isOk = res['success'] == true ||
          res['status']?.toString().toLowerCase() == 'ok' ||
          res['online'] == true;
      setState(() {
        _serverOnline = isOk;
        _serverDetail =
            res['app']?.toString() ?? 'Terhubung ke backend API P3H';
        _checkingServer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverOnline = false;
        _serverDetail = e.toString().replaceAll('Exception: ', '');
        _checkingServer = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
    _checkServer();
  }

  Future<void> _handleLogout() async {
    final user = AuthService().currentUser;
    if (user == null || user.isTamu) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Keluar dari Sistem?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: const Text(
          'Sesi aktif Anda akan diakhiri dan Anda akan kembali ke halaman masuk.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'Tamu / Publik';
    final roleSubtitle = user?.roleSubtitle ?? 'Akses Publik';
    final isTamu = user?.isTamu ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil & Hak Akses',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _checkServer,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // User Identity Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(displayName),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleSubtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            if (!isTamu && (user?.username ?? '').isNotEmpty)
                              Text(
                                '@${user!.username}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Server Connection Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.dns_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Koneksi Server Backend',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _checkingServer
                              ? AppColors.inputFill
                              : (_serverOnline == true
                                  ? const Color(0xFFECFDF5)
                                  : AppColors.deleteBg),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _checkingServer
                              ? 'Memeriksa...'
                              : (_serverOnline == true ? 'Online' : 'Offline'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _checkingServer
                                ? AppColors.textSecondary
                                : (_serverOnline == true
                                    ? const Color(0xFF15803D)
                                    : AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_serverDetail != null)
                    Text(
                      _serverDetail!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _checkingServer ? null : _checkServer,
                          icon: const Icon(Icons.refresh, size: 17),
                          label: const Text('Cek Ulang'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.tune, size: 17),
                          label: const Text('Atur URL Server'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // RBAC Matrix Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 19,
                        color: AppColors.primaryLight,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hak Akses Peran Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PermissionRow(
                    label: 'Pencarian Pasal & Detail Peraturan',
                    allowed: true,
                  ),
                  _PermissionRow(
                    label: 'Lihat Jadwal Rapat Harmonisasi',
                    allowed: !isTamu,
                  ),
                  _PermissionRow(
                    label: 'Tambah, Edit & Hapus Jadwal Rapat',
                    allowed: user?.canManageJadwal ?? false,
                  ),
                  _PermissionRow(
                    label: 'Tambah, Edit & Hapus Peraturan / Pasal',
                    allowed: user?.canManagePeraturan ?? false,
                  ),
                  _PermissionRow(
                    label: 'Kelola Akun Pengguna & Reset Kata Sandi',
                    allowed: user?.isAdmin ?? false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout / Login CTA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: isTamu
                  ? ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Masuk Sebagai Pegawai'),
                    )
                  : ElevatedButton.icon(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deleteBg,
                        foregroundColor: AppColors.deleteIcon,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Keluar dari Sistem',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool allowed;
  final bool isLast;

  const _PermissionRow({
    required this.label,
    required this.allowed,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: allowed ? const Color(0xFF15803D) : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: allowed ? FontWeight.w600 : FontWeight.w400,
                color: allowed ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
