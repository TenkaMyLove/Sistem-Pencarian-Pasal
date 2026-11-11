import 'package:flutter/material.dart';
import '../services/api_service.dart';

const List<String> kJenisPeraturanOptions = [
  'UU',
  'PP',
  'Perpres',
  'Permen',
  'Perda',
  'Pergub',
  'Perbup',
  'Perwal',
  'Inpres',
  'Keppres',
  'Kepmen',
  'SE',
  'Perppu',
  'UUD 1945',
];

const List<String> kWilayahOptions = [
  'Nasional',
  'Kalimantan Selatan',
  'Kabupaten Banjar',
  'Kabupaten Barito Kuala',
  'Kabupaten Hulu Sungai Selatan',
  'Kabupaten Hulu Sungai Tengah',
  'Kabupaten Hulu Sungai Utara',
  'Kabupaten Kotabaru',
  'Kabupaten Tabalong',
  'Kabupaten Tanah Bumbu',
  'Kabupaten Tanah Laut',
  'Kabupaten Tapin',
  'Kabupaten Balangan',
  'Kota Banjarbaru',
  'Kota Banjarmasin',
];

const List<String> kSektorOptions = [
  'Keuangan Daerah',
  'Otonomi Daerah',
  'Tata Ruang',
  'Lingkungan Hidup',
  'Pendidikan',
  'Kesehatan',
  'Ketenagakerjaan',
  'Pertanahan',
  'Perpajakan',
  'Perdagangan',
  'Pertanian',
  'Perikanan',
  'Infrastruktur',
  'Pemerintahan',
  'Hukum',
  'Lainnya',
];

const List<Map<String, String>> kStatusOptions = [
  {'value': 'berlaku', 'label': 'Berlaku'},
  {'value': 'diubah', 'label': 'Diubah'},
  {'value': 'dicabut_sebagian', 'label': 'Dicabut Sebagian'},
  {'value': 'dicabut', 'label': 'Dicabut / Tidak Berlaku'},
];

List<String> _mergeOption(List<String> base, String current) {
  final trimmed = current.trim();
  if (trimmed.isEmpty || base.contains(trimmed)) {
    return base;
  }
  return [trimmed, ...base];
}

String _normalizeStatusValue(String? rawStatus) {
  final s = (rawStatus ?? 'berlaku').trim().toLowerCase();
  if (s == 'dicabut_sebagian' || s.contains('sebagian')) return 'dicabut_sebagian';
  if (s == 'dicabut' || s.contains('cabut') || s.contains('tidak')) return 'dicabut';
  if (s == 'diubah' || s.contains('ubah')) return 'diubah';
  return 'berlaku';
}

Future<bool> showEditPeraturanDialog(
  BuildContext context,
  Map<String, dynamic> peraturan,
) async {
  final id = int.tryParse((peraturan['id'] ?? peraturan['peraturan_id'] ?? '0').toString()) ?? 0;
  if (id <= 0) return false;

  final formKey = GlobalKey<FormState>();
  final currentJenis = (peraturan['jenis_peraturan'] ?? 'UU').toString();
  final currentWilayah = (peraturan['wilayah'] ?? 'Nasional').toString();
  final currentSektor = (peraturan['sektor'] ?? 'Lainnya').toString();

  final jenisItems = _mergeOption(kJenisPeraturanOptions, currentJenis);
  final wilayahItems = _mergeOption(kWilayahOptions, currentWilayah);
  final sektorItems = _mergeOption(kSektorOptions, currentSektor);

  String selectedJenis = currentJenis.isNotEmpty ? currentJenis : jenisItems.first;
  String selectedWilayah = currentWilayah.isNotEmpty ? currentWilayah : wilayahItems.first;
  String selectedSektor = currentSektor.isNotEmpty ? currentSektor : sektorItems.first;
  String selectedStatus = _normalizeStatusValue(peraturan['status']?.toString());

  final nomorCtrl = TextEditingController(text: (peraturan['nomor'] ?? '').toString());
  final tahunCtrl = TextEditingController(text: (peraturan['tahun'] ?? '').toString());
  final judulCtrl = TextEditingController(text: (peraturan['judul'] ?? '').toString());
  final urlCtrl = TextEditingController(text: (peraturan['url_dokumen_asli'] ?? '').toString());
  final detailCtrl = TextEditingController(text: (peraturan['status_detail'] ?? '').toString());

  bool isSaving = false;
  String? errorMsg;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Peraturan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMsg != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 12),
                          ),
                        ),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: selectedJenis,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Jenis Peraturan *'),
                        items: jenisItems
                            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedJenis = val);
                              },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nomorCtrl,
                              enabled: !isSaving,
                              decoration: const InputDecoration(labelText: 'Nomor *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: tahunCtrl,
                              enabled: !isSaving,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Tahun *'),
                              validator: (v) {
                                final parsed = int.tryParse((v ?? '').trim());
                                if (parsed == null || parsed < 1900) return 'Tahun tidak valid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: judulCtrl,
                        enabled: !isSaving,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Judul / Tentang Peraturan *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Status Hukum'),
                        items: kStatusOptions
                            .map((opt) => DropdownMenuItem(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                ))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedStatus = val);
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedWilayah,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Wilayah'),
                        items: wilayahItems
                            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedWilayah = val);
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSektor,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sektor'),
                        items: sektorItems
                            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedSektor = val);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: urlCtrl,
                        enabled: !isSaving,
                        decoration: const InputDecoration(labelText: 'URL Dokumen Asli *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'URL wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: detailCtrl,
                        enabled: !isSaving,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Keterangan Status (Opsional)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });
                        try {
                          await ApiService().updatePeraturan(id, {
                            'jenis_peraturan': selectedJenis,
                            'nomor': nomorCtrl.text.trim(),
                            'tahun': int.parse(tahunCtrl.text.trim()),
                            'judul': judulCtrl.text.trim(),
                            'status': selectedStatus,
                            'status_detail': detailCtrl.text.trim(),
                            'wilayah': selectedWilayah,
                            'sektor': selectedSektor,
                            'url_dokumen_asli': urlCtrl.text.trim(),
                          });
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(true);
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            errorMsg = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      );
    },
  );

  nomorCtrl.dispose();
  tahunCtrl.dispose();
  judulCtrl.dispose();
  urlCtrl.dispose();
  detailCtrl.dispose();
  return result == true;
}

Future<bool> showEditPasalDialog(
  BuildContext context,
  Map<String, dynamic> pasal,
) async {
  final id = int.tryParse((pasal['id'] ?? pasal['pasal_id'] ?? '0').toString()) ?? 0;
  if (id <= 0) return false;

  final formKey = GlobalKey<FormState>();
  final nomorPasalCtrl = TextEditingController(text: (pasal['nomor_pasal'] ?? '').toString());
  final nomorAyatCtrl = TextEditingController(text: (pasal['nomor_ayat'] ?? '').toString());
  final teksCtrl = TextEditingController(text: (pasal['teks_pasal'] ?? '').toString());

  bool isSaving = false;
  String? errorMsg;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Pasal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMsg != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 12),
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: nomorPasalCtrl,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Pasal *',
                          hintText: 'Contoh: Pasal 18',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nomor pasal wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nomorAyatCtrl,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Ayat (Opsional)',
                          hintText: 'Contoh: Ayat (1)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: teksCtrl,
                        enabled: !isSaving,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'Isi / Teks Pasal *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Teks pasal wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSaving = true;
                          errorMsg = null;
                        });
                        try {
                          await ApiService().updatePasal(id, {
                            'nomor_pasal': nomorPasalCtrl.text.trim(),
                            'nomor_ayat': nomorAyatCtrl.text.trim(),
                            'teks_pasal': teksCtrl.text.trim(),
                          });
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(true);
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            errorMsg = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Pasal'),
              ),
            ],
          );
        },
      );
    },
  );

  nomorPasalCtrl.dispose();
  nomorAyatCtrl.dispose();
  teksCtrl.dispose();
  return result == true;
}

Future<bool> _confirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onDelete,
}) async {
  bool isDeleting = false;
  String? errorMsg;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() {
                          isDeleting = true;
                          errorMsg = null;
                        });
                        try {
                          await onDelete();
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(true);
                        } catch (e) {
                          setDialogState(() {
                            isDeleting = false;
                            errorMsg = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Hapus'),
              ),
            ],
          );
        },
      );
    },
  );

  return result == true;
}

Future<bool> confirmDeletePeraturanDialog(
  BuildContext context,
  int peraturanId,
  String titleLabel,
) =>
    _confirmDeleteDialog(
      context: context,
      title: 'Hapus Peraturan',
      message: 'Hapus $titleLabel beserta seluruh pasalnya? Tindakan ini tidak dapat dibatalkan.',
      onDelete: () => ApiService().deletePeraturan(peraturanId),
    );

Future<bool> confirmDeletePasalDialog(
  BuildContext context,
  int pasalId,
  String pasalLabel,
) =>
    _confirmDeleteDialog(
      context: context,
      title: 'Hapus Pasal',
      message: 'Hapus $pasalLabel secara permanen?',
      onDelete: () => ApiService().deletePasal(pasalId),
    );
