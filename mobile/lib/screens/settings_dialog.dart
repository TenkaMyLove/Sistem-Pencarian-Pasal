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

  Future<void> _loadCurrentUrl() async {
    final url = await ApiService().getBaseUrl();
    _urlController.text = url;
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    // Temporarily set to test
    await ApiService().setBaseUrl(_urlController.text);
    final res = await ApiService().checkHealth();

    setState(() {
      _testing = false;
      _testSuccess = res['success'] == true;
      if (_testSuccess) {
        _testResult = 'Terhubung! Server: ${res['data']?['app'] ?? 'Online'}';
      } else {
        _testResult = 'Gagal terhubung: ${res['message']}';
      }
    });
  }

  Future<void> _save() async {
    await ApiService().setBaseUrl(_urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat server berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Pengaturan Server API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih atau masukkan alamat backend server P3H Kemenkumham:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://localhost:3000',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Preset Cepat:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.language, size: 16),
                  label: const Text('Web (localhost:3000)'),
                  onPressed: () {
                    _urlController.text = 'http://localhost:3000';
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.android, size: 16),
                  label: const Text('Android (10.0.2.2:3000)'),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:3000';
                  },
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
                    : const Icon(Icons.network_check),
                label: Text(_testing ? 'Memeriksa...' : 'Uji Koneksi Server'),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess ? const Color(0xFFDEF7EC) : const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? const Color(0xFF03543F) : const Color(0xFF9B1C1C),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
