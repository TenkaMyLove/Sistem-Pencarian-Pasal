import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/peraturan_edit_dialogs.dart';

class TambahPeraturanScreen extends StatefulWidget {
  const TambahPeraturanScreen({super.key});

  @override
  State<TambahPeraturanScreen> createState() => _TambahPeraturanScreenState();
}

class _TambahPeraturanScreenState extends State<TambahPeraturanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nomorController = TextEditingController();
  final _tahunController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final _judulController = TextEditingController();
  final _teksManualController = TextEditingController();

  String _selectedJenis = kJenisPeraturanOptions.first;
  String _selectedWilayah = kWilayahOptions.first;
  String _selectedSektor = kSektorOptions.first;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nomorController.dispose();
    _tahunController.dispose();
    _judulController.dispose();
    _teksManualController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _urlController.clear();
    _nomorController.clear();
    _tahunController.text = DateTime.now().year.toString();
    _judulController.clear();
    _teksManualController.clear();
    setState(() {
      _selectedJenis = kJenisPeraturanOptions.first;
      _selectedWilayah = kWilayahOptions.first;
      _selectedSektor = kSektorOptions.first;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final urlText = _urlController.text.trim();
    final manualText = _teksManualController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final user = AuthService().currentUser;
      final res = await ApiService().tambahPeraturan({
        'url': urlText,
        'jenis_peraturan': _selectedJenis,
        'nomor': _nomorController.text.trim(),
        'tahun': int.tryParse(_tahunController.text.trim()) ??
            DateTime.now().year,
        'judul': _judulController.text.trim(),
        'wilayah': _selectedWilayah,
        'sektor': _selectedSektor,
        'teks_manual': manualText,
        'ditambahkan_oleh': user?.displayName ?? 'Pengelola',
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showResultDialog(success: true, data: res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showResultDialog(
        success: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _showResultDialog({
    required bool success,
    Map<String, dynamic>? data,
    String? errorMessage,
  }) {
    final payload = (data?['data'] is Map)
        ? Map<String, dynamic>.from(data!['data'])
        : data;
    final pasalCount =
        payload?['pasal_count'] ??
        payload?['total_pasal'] ??
        payload?['jumlah_pasal'] ??
        payload?['inserted_pasal'];
    final message =
        data?['message']?.toString() ??
        payload?['message']?.toString() ??
        (success
            ? 'Peraturan berhasil diproses dan diindeks ke basis data.'
            : (errorMessage ?? 'Gagal memproses peraturan.'));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: success ? const Color(0xFFECFDF5) : AppColors.deleteBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? const Color(0xFF15803D) : AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success ? 'Peraturan Tersimpan' : 'Proses Gagal',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (success && pasalCount != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.gavel_outlined,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Pasal Terindeks: $pasalCount pasal',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (success)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resetForm();
              },
              child: const Text('Input Peraturan Lain'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Row(
            children: [
              Icon(
                Icons.library_add_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'INDEKSASI DOKUMEN HUKUM',
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
            'Tambah Peraturan Baru',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ekstrak pasal otomatis dari tautan sumber JDIH atau tempel naskah peraturan secara manual.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Card 1: Parameter Web Crawler
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
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.travel_explore,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Parameter Web Crawler',
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
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Otomatis',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'URL Peraturan (JDIH / Peraturan.go.id)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _urlController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://peraturan.bpk.go.id/Details/...',
                    prefixIcon: Icon(Icons.link, size: 19),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'URL sumber peraturan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Apabila halaman sumber berbasis PDF atau tidak dapat diekstrak otomatis, isi juga teks naskah manual di kolom bawah.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Card 2: Metadata & Klasifikasi Peraturan
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
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Metadata & Klasifikasi Peraturan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Jenis Peraturan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedJenis,
                  isExpanded: true,
                  items: kJenisPeraturanOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedJenis = val);
                        },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nomor',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nomorController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                              hintText: 'Mis. 23',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tahun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tahunController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '2026',
                            ),
                            validator: (val) {
                              final yr = int.tryParse((val ?? '').trim());
                              if (yr == null || yr < 1945 || yr > 2100) {
                                return 'Tahun invalid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Judul / Tentang Peraturan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _judulController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan judul lengkap peraturan...',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty
                          ? 'Judul peraturan wajib diisi'
                          : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Wilayah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedWilayah,
                  isExpanded: true,
                  items: kWilayahOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedWilayah = val);
                          }
                        },
                ),
                const SizedBox(height: 14),

                const Text(
                  'Sektor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSektor,
                  isExpanded: true,
                  items: kSektorOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedSektor = val);
                          }
                        },
                ),
                const SizedBox(height: 14),

                const Text(
                  'Teks Naskah Manual (Opsional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _teksManualController,
                  enabled: !_isSubmitting,
                  maxLines: 5,
                  minLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Tempel teks isi peraturan (Pasal 1, Pasal 2, dst.) apabila URL gagal diparsing otomatis...',
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 19),
                    label: Text(
                      _isSubmitting
                          ? 'Memproses & Mengekstrak...'
                          : 'Simpan & Proses Peraturan',
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
        ],
      ),
    );
  }
}
