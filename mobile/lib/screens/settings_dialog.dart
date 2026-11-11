import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _urlController = TextEditingController();
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    final url = await ApiService().getBaseUrl();
    if (mounted) {
      _urlController.text = url;
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final res = await ApiService().checkHealth(baseUrlOverride: _urlController.text);

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testSuccess = res['success'] == true;
      if (_testSuccess) {
        _testResult = 'Terhubung! Server: ${res['data']?['app'] ?? 'Online'}';
      } else {
        final rawMsg = res['message']?.toString() ?? 'Unknown error';
        _testResult = 'Gagal terhubung: $rawMsg';
      }
    });
  }

  Future<void> _save() async {
    await ApiService().setBaseUrl(_urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat server berhasil disimpan.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: const Row(
        children: [
          Icon(Icons.settings_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengaturan Server API',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih atau masukkan alamat backend server P3H Kemenkumham:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Text(
                'Base URL API',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'http://localhost:3000',
                  prefixIcon: Icon(Icons.link, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Preset Cepat:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _urlController.text = 'http://localhost:3000';
                    },
                    icon: const Icon(Icons.language, size: 16),
                    label: const Text('Web (localhost:3000)', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.tagR),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _urlController.text = 'http://10.0.2.2:3000';
                    },
                    icon: const Icon(Icons.android, size: 16),
                    label: const Text('Android (10.0.2.2:3000)', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.tagR),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: Text(_testing ? 'Memeriksa...' : 'Uji Koneksi Server'),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess ? AppColors.statusBerlakuBg : AppColors.dangerBg,
                    border: Border.all(
                      color: _testSuccess ? AppColors.statusBerlakuBorder : AppColors.dangerBorder,
                    ),
                    borderRadius: AppRadius.controlR,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: _testSuccess ? AppColors.statusBerlakuText : AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess ? AppColors.statusBerlakuText : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
