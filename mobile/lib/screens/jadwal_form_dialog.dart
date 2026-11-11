import 'package:flutter/material.dart';
import '../models/jadwal_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class JadwalFormDialog extends StatefulWidget {
  final JadwalItem? item;

  const JadwalFormDialog({super.key, this.item});

  @override
  State<JadwalFormDialog> createState() => _JadwalFormDialogState();
}

class _JadwalFormDialogState extends State<JadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _jenisRancangan;
  late String _timPokja;
  late TextEditingController _tentangController;
  late TextEditingController _tanggalController;
  late TextEditingController _jamController;
  late TextEditingController _kompilatorController;

  bool _isSaving = false;
  String? _errorText;

  static const List<String> _baseJenisOptions = ['Ranperda', 'Ranpergub'];
  static const List<String> _pokjaOptions = ['Pokja 1', 'Pokja 2'];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _jenisRancangan = _normalizeJenis(item?.jenisRancangan);
    _timPokja = _normalizePokja(item?.timPokja);
    _tentangController = TextEditingController(text: item?.tentang ?? '');
    _tanggalController = TextEditingController(
      text: _normalizeDateString(item?.tanggal),
    );
    _jamController = TextEditingController(
      text: _normalizeTimeString(item?.jam),
    );
    _kompilatorController = TextEditingController(
      text: item?.namaKompilator ?? '',
    );
  }

  @override
  void dispose() {
    _tentangController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    _kompilatorController.dispose();
    super.dispose();
  }

  String _normalizeJenis(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return 'Ranperda';
    for (final opt in _baseJenisOptions) {
      if (opt.toLowerCase() == trimmed.toLowerCase()) return opt;
    }
    return trimmed;
  }

  String _normalizePokja(String? raw) {
    final lower = (raw ?? '').toLowerCase().trim();
    if (lower.contains('2') || RegExp(r'\bii\b').hasMatch(lower)) {
      return 'Pokja 2';
    }
    if (lower.contains('1') || RegExp(r'\bi\b').hasMatch(lower)) {
      return 'Pokja 1';
    }
    return 'Pokja 1';
  }

  String _normalizeDateString(String? raw) {
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) {
        final y = parsed.year.toString().padLeft(4, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw.trim())) {
        return raw.trim().substring(0, 10);
      }
    }
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _normalizeTimeString(String? raw) {
    if (raw != null && raw.trim().isNotEmpty) {
      final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw);
      if (match != null) {
        final hh = match.group(1)!.padLeft(2, '0');
        final mm = match.group(2)!.padLeft(2, '0');
        return '$hh:$mm';
      }
    }
    return '09:00';
  }

  Future<void> _pickDate() async {
    final initial =
        DateTime.tryParse(_tanggalController.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      _tanggalController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final parts = _jamController.text.split(':');
    final initialHour = int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9;
    final initialMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour.clamp(0, 23),
        minute: initialMinute.clamp(0, 59),
      ),
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      _jamController.text =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final user = AuthService().currentUser;
    final payload = {
      'jenis_rancangan': _jenisRancangan,
      'tentang': _tentangController.text.trim(),
      'tanggal': _tanggalController.text.trim(),
      'jam': _normalizeTimeString(_jamController.text),
      'nama_kompilator': _kompilatorController.text.trim(),
      'tim_pokja': _timPokja,
      'dibuat_oleh':
          widget.item?.dibuatOleh ?? (user?.displayName ?? 'Pengelola'),
    };

    try {
      if (widget.item == null) {
        await ApiService().addJadwal(payload);
      } else {
        await ApiService().updateJadwal(widget.item!.id, payload);
      }
      if (!mounted) return;
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
    final isEdit = widget.item != null;
    final jenisItems = {
      ..._baseJenisOptions,
      _jenisRancangan,
    }.toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
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
                      child: Icon(
                        isEdit ? Icons.edit_calendar : Icons.event_available,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Jadwal Harmonisasi'
                                : 'Tambah Jadwal Harmonisasi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Agenda Rapat Harmonisasi Kanwil Kalsel',
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

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jenis Rancangan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _jenisRancangan,
                            items: jenisItems
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _jenisRancangan = val);
                                    }
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
                            'Tim Pokja',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _timPokja,
                            items: _pokjaOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _timPokja = val);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Tentang / Pokok Materi Rancangan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _tentangController,
                  enabled: !_isSaving,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Rancangan Perda tentang Pengelolaan Sampah...',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty
                          ? 'Judul/tentang wajib diisi'
                          : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal (YYYY-MM-DD)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tanggalController,
                            readOnly: true,
                            onTap: _isSaving ? null : _pickDate,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today, size: 17),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam (WITA)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _jamController,
                            readOnly: true,
                            onTap: _isSaving ? null : _pickTime,
                            decoration: const InputDecoration(
                              hintText: '09:00',
                              suffixIcon: Icon(Icons.access_time, size: 18),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Nama Kompilator / Koordinator',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kompilatorController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Ahmad Fauzi, S.H., M.H.',
                    prefixIcon: Icon(Icons.badge_outlined, size: 19),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty
                          ? 'Nama kompilator wajib diisi'
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
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : (isEdit ? 'Simpan Perubahan' : 'Simpan Jadwal'),
                        ),
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
