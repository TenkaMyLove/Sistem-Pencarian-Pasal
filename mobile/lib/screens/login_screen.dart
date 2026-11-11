import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Brand header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.account_balance, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEMENTERIAN HUKUM RI',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Kanwil Kalimantan Selatan',
                          style: textTheme.bodySmall?.copyWith(color: const Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Pengaturan Server',
                    onPressed: () => SettingsDialog.show(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.containerR,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Masuk Sistem',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Portal Pencarian Pasal & Harmonisasi Regulasi Daerah',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),

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
                                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const _FieldLabel('Username'),
                          TextField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(hintText: 'Username'),
                          ),
                          const SizedBox(height: 16),

                          const _FieldLabel('Kata Sandi'),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              hintText: 'Kata sandi',
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ATAU',
                                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),

                          OutlinedButton(
                            onPressed: _isLoading ? null : _handleGuestLogin,
                            child: const Text('Masuk sebagai Tamu'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                '\u00a9 2026 Kantor Wilayah Kementerian Hukum Kalimantan Selatan',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
