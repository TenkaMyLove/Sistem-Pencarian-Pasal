import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'settings_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(AppConstants.prefRememberMe) ?? false;
    final savedUsername = prefs.getString(AppConstants.prefSavedUsername) ?? '';
    if (!mounted) return;
    setState(() {
      _rememberSession = remember;
      if (remember && savedUsername.isNotEmpty) {
        _usernameController.text = savedUsername;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username dan kata sandi wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefRememberMe, _rememberSession);
    if (_rememberSession) {
      await prefs.setString(AppConstants.prefSavedUsername, username);
    } else {
      await prefs.remove(AppConstants.prefSavedUsername);
    }

    final res = await AuthService().login(username, password);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['message'] ?? 'Login gagal. Silakan coba lagi.';
      });
    }
  }

  Future<void> _handleGuestLogin() async {
    await AuthService().loginAsGuest();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showForgotPasswordInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Lupa Kata Sandi?'),
          ],
        ),
        content: const Text(
          'Untuk keamanan kredensial pegawai, pembaruan kata sandi hanya dapat dilakukan oleh Administrator melalui menu Kelola Akun & Keamanan.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textBody),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle server settings trigger on top-right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
                tooltip: 'Pengaturan Server API',
                onPressed: () => SettingsDialog.show(context),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo box
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.account_balance,
                            color: AppColors.accentLight,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'KANTOR WILAYAH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'KEMENTERIAN HUKUM KALIMANTAN SELATAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Masuk Sistem',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Portal Pencarian Pasal & Harmonisasi Regulasi Daerah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // White Form Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(10),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  border: Border.all(color: AppColors.dangerBorder),
                                  borderRadius: AppRadius.controlR,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const Text(
                              'Username / NIP Pegawai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                hintText: 'Masukkan username atau NIP',
                                prefixIcon: Icon(Icons.badge_outlined, size: 19, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'Kata Sandi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi akun',
                                prefixIcon: const Icon(Icons.lock_outline, size: 19, color: AppColors.textSecondary),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 19,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Ingat Sesi Saya + Lupa Sandi?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _rememberSession = !_rememberSession),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberSession,
                                          onChanged: (v) => setState(() => _rememberSession = v ?? false),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Ingat Sesi Saya',
                                        style: TextStyle(fontSize: 12, color: AppColors.textBody),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showForgotPasswordInfo,
                                  child: const Text(
                                    'Lupa Sandi?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Masuk ke Sistem
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.controlR),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Masuk ke Sistem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 8),
                                        Icon(Icons.login, size: 18),
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'ATAU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Akses Publik (Mode Tamu)
                            OutlinedButton(
                              onPressed: _isLoading ? null : _handleGuestLogin,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: AppColors.background,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.controlR),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.manage_search, size: 18, color: AppColors.textPrimary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Akses Publik (Mode Tamu)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        '\u00a9 2026 Kantor Wilayah Kementerian Hukum Kalimantan Selatan',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
