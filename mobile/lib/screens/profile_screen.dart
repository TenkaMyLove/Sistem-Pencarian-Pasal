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
  String _baseUrl = '';
  String _healthStatus = 'Memeriksa...';
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final url = await ApiService().getBaseUrl();
    setState(() => _baseUrl = url);

    final res = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _isOnline = res['success'] == true;
        _healthStatus = _isOnline ? 'Terhubung (Online)' : 'Tidak Terhubung (Offline)';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isTamu = user == null || user.isTamu;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'T'),
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.username ?? 'Tamu / Publik',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBlueBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Peran: ${user?.peran ?? 'Tamu'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.badgeBlueText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Server Connection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Koneksi Server API',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isOnline ? const Color(0xFFDEF7EC) : const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isOnline ? Icons.check_circle : Icons.error,
                                size: 12,
                                color: _isOnline ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _healthStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isOnline ? const Color(0xFF03543F) : const Color(0xFF9B1C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alamat Host: $_baseUrl',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Ubah Pengaturan Host API'),
                        onPressed: () async {
                          await SettingsDialog.show(context);
                          _checkServer();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hak Akses Role Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Hak Akses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    _buildPermissionItem('Pencarian Pasal Peraturan', true),
                    _buildPermissionItem('Lihat Detail Status Relasi Peraturan', true),
                    _buildPermissionItem('Lihat Dokumen PDF Asli', true),
                    _buildPermissionItem('Lihat Jadwal Harmonisasi Rapat', !isTamu),
                    _buildPermissionItem('Tambah & Edit Jadwal Harmonisasi', user?.canManageJadwal ?? false),
                    _buildPermissionItem('Tambah Peraturan via URL (Crawler)', user?.canTambahPeraturan ?? false),
                    _buildPermissionItem('Kelola Akun & Reset Kata Sandi', user?.isAdmin ?? false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Logout or Switch Account
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTamu ? AppColors.primary : Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(isTamu ? Icons.login : Icons.logout),
                label: Text(isTamu ? 'Masuk dengan Akun Pegawai' : 'Keluar dari Akun'),
                onPressed: _logout,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String text, bool granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.grey.shade400,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: granted ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
