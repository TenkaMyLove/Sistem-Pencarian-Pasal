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
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<UserAccount> _users = [];
  String? _selectedUsername;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _loadError;
  String? _formStatusMessage;
  bool _formStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final list = await ApiService().getAdminUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
        if (_users.isNotEmpty &&
            (_selectedUsername == null ||
                !_users.any((u) => u.username == _selectedUsername))) {
          final pengelola = _users.where(
            (u) => u.peran.toLowerCase() == 'pengelola',
          );
          _selectedUsername =
              pengelola.isNotEmpty
                  ? pengelola.first.username
                  : _users.first.username;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _roleDisplayName(String peran) {
    switch (peran.toLowerCase().trim()) {
      case 'admin':
        return 'Administrator';
      case 'pengelola':
        return 'Pengelola';
      case 'perancang':
        return 'Perancang';
      default:
        return peran;
    }
  }

  String _roleSubtitle(String peran) {
    switch (peran.toLowerCase().trim()) {
      case 'admin':
        return 'Admin Sistem';
      case 'pengelola':
        return 'Data & Jadwal';
      case 'perancang':
        return 'Tim Harmonisasi';
      default:
        return 'Pengguna Sistem';
    }
  }

  IconData _roleIcon(String peran) {
    switch (peran.toLowerCase().trim()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'pengelola':
        return Icons.event_note_outlined;
      case 'perancang':
        return Icons.edit_note_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _formatLastChanged(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) return rawDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _submitResetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formStatusMessage = null;
    });

    if (_selectedUsername == null || _selectedUsername!.isEmpty) {
      setState(() {
        _formStatusMessage = 'Pilih akun target terlebih dahulu.';
        _formStatusSuccess = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final adminUsername =
          AuthService().currentUser?.username ?? 'admin';
      await ApiService().resetPassword(
        targetUsername: _selectedUsername!,
        kataSandiBaru: _newPasswordController.text.trim(),
        adminUsername: adminUsername,
      );

      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isSubmitting = false;
        _formStatusSuccess = true;
        _formStatusMessage =
            'Kata sandi akun "@$_selectedUsername" berhasil diperbarui.';
      });
      _fetchUsers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formStatusSuccess = false;
        _formStatusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUsers =
        _isLoading && _users.isEmpty
            ? List.generate(3, (_) => UserAccount.dummy())
            : _users;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchUsers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Eyebrow & Title
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'PORTAL HAK AKSES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola Akun & Keamanan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Konfigurasi kredensial pengguna dan pengawasan otentikasi naskah hukum.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Blue Security Protocol Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.security_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protokol Kriptografi Dokumen',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Penyimpanan terenkripsi bcryptjs cost factor 10. Minimal panjang kata sandi 6 karakter.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primarySlate,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form Reset Kata Sandi Staf Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Form Reset Kata Sandi Staf',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Khusus Admin',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_formStatusMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _formStatusSuccess
                            ? const Color(0xFFECFDF5)
                            : AppColors.deleteBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_formStatusSuccess
                                  ? const Color(0xFF15803D)
                                  : AppColors.danger)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _formStatusSuccess
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 18,
                            color: _formStatusSuccess
                                ? const Color(0xFF15803D)
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formStatusMessage!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _formStatusSuccess
                                    ? const Color(0xFF15803D)
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Text(
                    'Pilih Akun Target',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _users.any(
                      (u) => u.username == _selectedUsername,
                    )
                        ? _selectedUsername
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Pilih akun pengguna...',
                    ),
                    items: _users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.username,
                            child: Text(
                              '${_roleDisplayName(u.peran)} (${_roleSubtitle(u.peran)}) — @${u.username}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _selectedUsername = val),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Kata Sandi Baru',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter kombinasi',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 6) {
                        return 'Kata sandi baru minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Konfirmasi Kata Sandi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Ulangi kata sandi baru',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Konfirmasi kata sandi wajib diisi';
                      }
                      if (val.trim() != _newPasswordController.text.trim()) {
                        return 'Konfirmasi kata sandi tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitResetPassword,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.vpn_key_outlined, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Memperbarui...'
                            : 'Perbarui Kata Sandi',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Daftar Akun Header
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 19,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Daftar Akun Pengguna Sistem',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                '${_users.length} Akun Terdaftar',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadError != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.deleteBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Gagal Memuat Daftar Akun',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _fetchUsers,
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('Muat Ulang'),
                  ),
                ],
              ),
            )
          else
            Skeletonizer(
              enabled: _isLoading,
              child: Column(
                children: displayUsers.map((account) {
                  final isSelected = account.username == _selectedUsername;
                  final lastChanged =
                      _formatLastChanged(account.tanggalKataSandiDiubah);
                  final isAdminAcc =
                      account.peran.toLowerCase().trim() == 'admin';

                  return GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedUsername = account.username;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isAdminAcc || isSelected
                                  ? AppColors.infoBg
                                  : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _roleIcon(account.peran),
                              size: 21,
                              color: isAdminAcc || isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _roleDisplayName(account.peran),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Peran: ${_roleSubtitle(account.peran)} • @${account.username}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (lastChanged.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lastChanged,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
