import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/user_account.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class KelolaAkunScreen extends StatefulWidget {
  const KelolaAkunScreen({super.key});

  @override
  State<KelolaAkunScreen> createState() => _KelolaAkunScreenState();
}

class _KelolaAkunScreenState extends State<KelolaAkunScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<UserAccount> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService().getAdminUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _openResetPasswordDialog(UserAccount user) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    String? localError;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.lock_reset, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Ubah Sandi ${user.username}', style: const TextStyle(fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru *',
                      hintText: 'Minimal 6 karakter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Sandi *',
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final p1 = passwordController.text.trim();
                          final p2 = confirmController.text.trim();

                          if (p1.length < 6) {
                            setDialogState(() => localError = 'Kata sandi minimal 6 karakter');
                            return;
                          }
                          if (p1 != p2) {
                            setDialogState(() => localError = 'Konfirmasi kata sandi tidak cocok');
                            return;
                          }

                          setDialogState(() => submitting = true);

                          final navigator = Navigator.of(dialogCtx);
                          final messenger = ScaffoldMessenger.of(this.context);

                          try {
                            final adminName = AuthService().currentUser?.username ?? 'Admin';
                            await ApiService().resetPassword(
                              targetUsername: user.username,
                              kataSandiBaru: p1,
                              adminUsername: adminName,
                            );

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Kata sandi untuk ${user.username} berhasil diubah!')),
                            );
                            _fetchUsers();
                          } catch (e) {
                            setDialogState(() {
                              submitting = false;
                              localError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: const Color(0xFFEFF6FF),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Kelola Akun Pengguna',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sebagai Admin, Anda dapat mengelola akun dan memperbarui kata sandi tim operasional (Pengelola & Perancang).',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(10)),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              const Text('Daftar Akun Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              Skeletonizer(
                enabled: _isLoading,
                child: _isLoading
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 2,
                        itemBuilder: (context, index) => _buildUserCard(UserAccount.dummy()),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          return _buildUserCard(u);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserAccount user) {
    final canReset = user.username == 'Pengelola' || user.username == 'Perancang';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.badgeBlueBg,
              child: Icon(
                user.peran == 'Admin'
                    ? Icons.shield
                    : (user.peran == 'Pengelola' ? Icons.manage_accounts : Icons.edit_document),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Peran: ${user.peran}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                  if (user.tanggalKataSandiDiubah != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sandi diubah: ${user.tanggalKataSandiDiubah}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (canReset)
              OutlinedButton.icon(
                icon: const Icon(Icons.key, size: 16),
                label: const Text('Reset Sandi', style: TextStyle(fontSize: 12)),
                onPressed: () => _openResetPasswordDialog(user),
              ),
          ],
        ),
      ),
    );
  }
}
