import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class TambahPeraturanScreen extends StatefulWidget {
  const TambahPeraturanScreen({super.key});

  @override
  State<TambahPeraturanScreen> createState() => _TambahPeraturanScreenState();
}

class _TambahPeraturanScreenState extends State<TambahPeraturanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();
  final _nomorController = TextEditingController();
  final _tahunController = TextEditingController(text: DateTime.now().year.toString());
  final _judulController = TextEditingController();
  final _teksManualController = TextEditingController();

  String _jenisPeraturan = 'Peraturan Daerah';
  String _wilayah = 'Provinsi Kalimantan Selatan';
  String _sektor = 'Otonomi & Pemerintahan Daerah';

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _jenisOptions = [
    'Undang-Undang',
    'Peraturan Pemerintah Pengganti Undang-Undang',
    'Peraturan Pemerintah',
    'Peraturan Presiden',
    'Peraturan Daerah',
    'Peraturan Kepala Daerah',
  ];

  final List<String> _wilayahOptions = [
    'Nasional',
    'Provinsi Kalimantan Selatan',
    'Kota Banjarmasin',
    'Kota Banjarbaru',
    'Kabupaten Banjar',
    'Kabupaten Barito Kuala',
    'Kabupaten Tanah Laut',
    'Kabupaten Tanah Bumbu',
    'Kabupaten Kotabaru',
    'Kabupaten Tapin',
    'Kabupaten Hulu Sungai Selatan',
    'Kabupaten Hulu Sungai Tengah',
    'Kabupaten Hulu Sungai Utara',
    'Kabupaten Balangan',
    'Kabupaten Tabalong',
  ];

  final List<String> _sektorOptions = [
    'Otonomi & Pemerintahan Daerah',
    'Investasi & Perizinan',
    'Keuangan Daerah',
    'Tata Ruang & Bangunan',
    'Lingkungan Hidup',
    'Pajak & Retribusi Daerah',
    'Ketenagakerjaan',
    'Kesehatan',
    'Pendidikan',
    'Hukum Pidana & Jasa Konstruksi',
    'Lainnya',
  ];

  Future<void> _submitCrawler() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = {
        'url': _urlController.text.trim(),
        'jenis_peraturan': _jenisPeraturan,
        'nomor': _nomorController.text.trim(),
        'tahun': int.tryParse(_tahunController.text.trim()) ?? DateTime.now().year,
        'judul': _judulController.text.trim(),
        'wilayah': _wilayah,
        'sektor': _sektor,
        'teks_manual': _teksManualController.text.trim(),
        'ditambahkan_oleh': AuthService().currentUser?.username ?? 'Pengelola',
      };

      final result = await ApiService().tambahPeraturan(data);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.statusBerlakuText),
                SizedBox(width: 8),
                Text('Berhasil Diindeks!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peraturan: ${result['judul'] ?? 'Tersimpan'}'),
                const SizedBox(height: 6),
                Text('Jumlah Pasal Terindeks: ${result['pasal_count'] ?? 0} pasal'),
                const SizedBox(height: 6),
                Text('Status Tautan Dokumen: ${result['status_tautan'] ?? 'normal'}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _urlController.clear();
                  _nomorController.clear();
                  _judulController.clear();
                  _teksManualController.clear();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.travel_explore, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Web Crawler Peraturan Baru',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Masukkan URL portal hukum resmi (JDIH BPK/Pemda) untuk mengindeks pasal secara otomatis.',
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

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    border: Border.all(color: AppColors.dangerBorder),
                    borderRadius: AppRadius.controlR,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // URL Field
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL Peraturan (JDIH BPK / Portal Resmi) *',
                  hintText: 'https://peraturan.bpk.go.id/Details/...',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'URL wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Jenis Peraturan Dropdown
              const Text('Jenis Peraturan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _jenisPeraturan,
                isExpanded: true,
                items: _jenisOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _jenisPeraturan = val);
                },
              ),
              const SizedBox(height: 12),

              // Nomor & Tahun
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomorController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor *',
                        hintText: 'Contoh: 12',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tahunController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tahun *',
                        hintText: '2024',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Judul / Tentang
              TextFormField(
                controller: _judulController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Judul / Tentang Peraturan',
                  hintText: 'Contoh: Pajak Daerah dan Retribusi Daerah',
                ),
              ),
              const SizedBox(height: 12),

              // Wilayah Dropdown
              const Text('Cakupan Wilayah', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _wilayah,
                isExpanded: true,
                items: _wilayahOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _wilayah = val);
                },
              ),
              const SizedBox(height: 12),

              // Sektor Dropdown
              const Text('Sektor Hukum', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _sektor,
                isExpanded: true,
                items: _sektorOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sektor = val);
                },
              ),
              const SizedBox(height: 12),

              // Manual text fallback
              TextFormField(
                controller: _teksManualController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Teks Peraturan Manual (Opsional)',
                  hintText: 'Salin-tempel teks pasal di sini jika website asal memerlukan entri manual.',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitCrawler,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Icon(Icons.cloud_download),
                  label: Text(_isLoading ? 'Sedang Mengindeks...' : 'Mulai Crawl & Simpan Peraturan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
