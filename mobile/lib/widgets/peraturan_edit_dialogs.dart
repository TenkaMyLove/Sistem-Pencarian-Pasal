import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

const List<String> kJenisPeraturanOptions = [
  'Undang-Undang',
  'Peraturan Pemerintah',
  'Peraturan Presiden',
  'Peraturan Menteri',
  'Peraturan Daerah',
  'Peraturan Gubernur',
  'Peraturan Bupati/Walikota',
];

const List<String> kWilayahOptions = [
  'Nasional',
  'Provinsi Kalimantan Selatan',
  'Kota Banjarmasin',
  'Kota Banjarbaru',
  'Kabupaten Banjar',
  'Kabupaten Barito Kuala',
  'Kabupaten Tapin',
  'Kabupaten Hulu Sungai Selatan',
  'Kabupaten Hulu Sungai Tengah',
  'Kabupaten Hulu Sungai Utara',
  'Kabupaten Balangan',
  'Kabupaten Tabalong',
  'Kabupaten Tanah Laut',
  'Kabupaten Tanah Bumbu',
  'Kabupaten Kotabaru',
];

const List<String> kSektorOptions = [
  'Umum / Pemerintahan',
  'Otonomi Daerah',
  'Tata Ruang & Lingkungan',
  'Kesehatan',
  'Pendidikan',
  'Perizinan & Investasi',
  'Keuangan & Pajak Daerah',
  'Sosial & Ketenagakerjaan',
  'Infrastruktur & Perhubungan',
];

const List<String> kStatusOptions = [
  'Berlaku',
  'Diubah',
  'Dicabut',
  'Tidak Berlaku',
];

List<String> _mergeWithCurrent(List<String> defaults, String current) {
  final trimmed = current.trim();
  if (trimmed.isEmpty) return defaults;
  if (defaults.contains(trimmed)) return defaults;
  return [trimmed, ...defaults];
}

Future<bool> showEditPeraturanDialog(
  BuildContext context,
  Map<String, dynamic> peraturan,
) async {
  final id = int.tryParse(peraturan['id']?.toString() ?? '') ?? 0;
  if (id <= 0) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EditPeraturanDialog(peraturan: peraturan, id: id),
  );
  return result == true;
}

class _EditPeraturanDialog extends StatefulWidget {
  final Map<String, dynamic> peraturan;
  final int id;

  const _EditPeraturanDialog({
    required this.peraturan,
    required this.id,
  });

  @override
  State<_EditPeraturanDialog> createState() => _EditPeraturanDialogState();
}

class _EditPeraturanDialogState extends State<_EditPeraturanDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _jenis;
  late String _wilayah;
  late String _sektor;
  late String _status;
  late TextEditingController _nomorCtrl;
  late TextEditingController _tahunCtrl;
  late TextEditingController _judulCtrl;
  late TextEditingController _statusDetailCtrl;
  late TextEditingController _urlCtrl;

  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final p = widget.peraturan;
    final rawJenis =
        (p['jenis_peraturan'] ?? p['jenis'] ?? '').toString().trim();
    final rawWilayah = (p['wilayah'] ?? '').toString().trim();
    final rawSektor = (p['sektor'] ?? '').toString().trim();
    final rawStatus = (p['status'] ?? '').toString().trim();

    _jenis =
        rawJenis.isNotEmpty ? rawJenis : kJenisPeraturanOptions.first;
    _wilayah = rawWilayah.isNotEmpty ? rawWilayah : kWilayahOptions.first;
    _sektor = rawSektor.isNotEmpty ? rawSektor : kSektorOptions.first;
    _status = rawStatus.isNotEmpty ? rawStatus : kStatusOptions.first;

    _nomorCtrl = TextEditingController(text: p['nomor']?.toString() ?? '');
    _tahunCtrl = TextEditingController(text: p['tahun']?.toString() ?? '');
    _judulCtrl = TextEditingController(
      text: (p['judul'] ?? p['tentang'] ?? '').toString(),
    );
    _statusDetailCtrl = TextEditingController(
      text: p['status_detail']?.toString() ?? '',
    );
    _urlCtrl = TextEditingController(
      text: (p['url_dokumen_asli'] ?? p['url'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nomorCtrl.dispose();
    _tahunCtrl.dispose();
    _judulCtrl.dispose();
    _statusDetailCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await ApiService().updatePeraturan(widget.id, {
        'jenis_peraturan': _jenis,
        'nomor': _nomorCtrl.text.trim(),
        'tahun': int.tryParse(_tahunCtrl.text.trim()) ?? DateTime.now().year,
        'judul': _judulCtrl.text.trim(),
        'wilayah': _wilayah,
        'sektor': _sektor,
        'status': _status,
        'status_detail': _statusDetailCtrl.text.trim(),
        'url_dokumen_asli': _urlCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metadata peraturan berhasil diperbarui.'),
          backgroundColor: AppColors.statusBerlakuText,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jenisOpts = _mergeWithCurrent(kJenisPeraturanOptions, _jenis);
    final wilayahOpts = _mergeWithCurrent(kWilayahOptions, _wilayah);
    final sektorOpts = _mergeWithCurrent(kSektorOptions, _sektor);
    final statusOpts = _mergeWithCurrent(kStatusOptions, _status);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_document,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Metadata Peraturan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Perbarui klasifikasi, status, atau sumber peraturan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textMuted,
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorText != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.deleteBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'Jenis Peraturan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _jenis,
                  isExpanded: true,
                  items: jenisOpts
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _jenis = v);
                        },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nomor',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nomorCtrl,
                            enabled: !_isSaving,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Wajib' : null,
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tahunCtrl,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                int.tryParse((v ?? '').trim()) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  'Judul / Tentang',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _judulCtrl,
                  enabled: !_isSaving,
                  maxLines: 3,
                  minLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                const Text(
                  'Wilayah',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _wilayah,
                  isExpanded: true,
                  items: wilayahOpts
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _wilayah = v);
                        },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sektor',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _sektor,
                            isExpanded: true,
                            items: sektorOpts
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (v) {
                                    if (v != null) setState(() => _sektor = v);
                                  },
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
                            'Status',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            isExpanded: true,
                            items: statusOpts
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (v) {
                                    if (v != null) setState(() => _status = v);
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  'Keterangan Status / Relasi (Opsional)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _statusDetailCtrl,
                  enabled: !_isSaving,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Mis. Diubah sebagian oleh Pasal 238...',
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Tautan Sumber Dokumen',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _urlCtrl,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: 'https://...'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Tautan sumber dokumen wajib diisi'
                      : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showEditPasalDialog(
  BuildContext context,
  Map<String, dynamic> pasal,
) async {
  final id =
      int.tryParse((pasal['id'] ?? pasal['pasal_id'])?.toString() ?? '') ?? 0;
  if (id <= 0) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EditPasalDialog(pasal: pasal, id: id),
  );
  return result == true;
}

class _EditPasalDialog extends StatefulWidget {
  final Map<String, dynamic> pasal;
  final int id;

  const _EditPasalDialog({required this.pasal, required this.id});

  @override
  State<_EditPasalDialog> createState() => _EditPasalDialogState();
}

class _EditPasalDialogState extends State<_EditPasalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomorCtrl;
  late TextEditingController _ayatCtrl;
  late TextEditingController _teksCtrl;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nomorCtrl = TextEditingController(
      text: (widget.pasal['nomor_pasal'] ?? widget.pasal['pasal_nomor'] ?? '')
          .toString(),
    );
    _ayatCtrl = TextEditingController(
      text: (widget.pasal['nomor_ayat'] ?? '').toString(),
    );
    _teksCtrl = TextEditingController(
      text: (widget.pasal['teks_pasal'] ??
              widget.pasal['isi_pasal'] ??
              widget.pasal['isi'] ??
              '')
          .toString(),
    );
  }

  @override
  void dispose() {
    _nomorCtrl.dispose();
    _ayatCtrl.dispose();
    _teksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await ApiService().updatePasal(widget.id, {
        'nomor_pasal': _nomorCtrl.text.trim(),
        'nomor_ayat': _ayatCtrl.text.trim(),
        'teks_pasal': _teksCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi pasal berhasil diperbarui.'),
          backgroundColor: AppColors.statusBerlakuText,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gavel_outlined,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Teks Pasal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textMuted,
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorText != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.deleteBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nomor Pasal',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nomorCtrl,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Pasal 14',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nomor pasal wajib diisi'
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
                            'Ayat (Opsional)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ayatCtrl,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Ayat (1)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Isi Pasal',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _teksCtrl,
                  enabled: !_isSaving,
                  maxLines: 8,
                  minLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan bunyi lengkap pasal...',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Isi pasal wajib diisi'
                      : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pasal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDeletePeraturanDialog(
  BuildContext context,
  int peraturanId,
  String titleLabel,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hapus Peraturan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Yakin ingin menghapus "$titleLabel" beserta seluruh pasalnya? Tindakan ini tidak dapat dibatalkan.',
        style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
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
          child: const Text('Hapus Peraturan'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  try {
    await ApiService().deletePeraturan(peraturanId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peraturan berhasil dihapus.'),
          backgroundColor: AppColors.statusBerlakuText,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    return false;
  }
}

Future<bool> confirmDeletePasalDialog(
  BuildContext context,
  int pasalId,
  String pasalLabel,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hapus Pasal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Hapus "$pasalLabel" dari daftar pasal peraturan ini?',
        style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
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
          child: const Text('Hapus Pasal'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  try {
    await ApiService().deletePasal(pasalId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasal berhasil dihapus.'),
          backgroundColor: AppColors.statusBerlakuText,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    return false;
  }
}
