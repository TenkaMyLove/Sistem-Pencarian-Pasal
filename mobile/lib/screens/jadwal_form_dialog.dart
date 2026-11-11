import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/jadwal_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class JadwalFormDialog extends StatefulWidget {
  final JadwalItem? editItem;

  const JadwalFormDialog({super.key, this.editItem});

  static Future<bool?> show(BuildContext context, {JadwalItem? editItem}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => JadwalFormDialog(editItem: editItem),
    );
  }

  @override
  State<JadwalFormDialog> createState() => _JadwalFormDialogState();
}

class _JadwalFormDialogState extends State<JadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _jenisRancangan;
  final _tentangController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _jamController = TextEditingController();
  final _namaKompilatorController = TextEditingController();
  final _timPokjaController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _jenisRancangan = widget.editItem!.jenisRancangan;
      _tentangController.text = widget.editItem!.tentang;
      _tanggalController.text = widget.editItem!.tanggal;
      _jamController.text = widget.editItem!.jam;
      _namaKompilatorController.text = widget.editItem!.namaKompilator;
      _timPokjaController.text = widget.editItem!.timPokja;
    } else {
      _jenisRancangan = 'Ranperda';
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _jamController.text = '09:00 WITA';
      _timPokjaController.text = 'Pokja I';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_tanggalController.text.isNotEmpty) {
      try {
        initial = DateFormat('yyyy-MM-dd').parse(_tanggalController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final min = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _jamController.text = '$hour:$min WITA';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = {
        'jenis_rancangan': _jenisRancangan,
        'tentang': _tentangController.text.trim(),
        'tanggal': _tanggalController.text.trim(),
        'jam': _jamController.text.trim(),
        'nama_kompilator': _namaKompilatorController.text.trim(),
        'tim_pokja': _timPokjaController.text.trim(),
        'dibuat_oleh': AuthService().currentUser?.username ?? 'Pengelola',
      };

      if (widget.editItem != null) {
        await ApiService().updateJadwal(widget.editItem!.id, data);
      } else {
        await ApiService().addJadwal(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
    final isEdit = widget.editItem != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEdit ? Icons.edit_calendar : Icons.add_circle_outline, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(isEdit ? 'Ubah Jadwal Rapat' : 'Tambah Agenda Rapat', style: const TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      border: Border.all(color: AppColors.dangerBorder),
                      borderRadius: AppRadius.controlR,
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Jenis Rancangan
                const Text('Jenis Rancangan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _jenisRancangan,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Ranperda', child: Text('Ranperda (Perda)')),
                    DropdownMenuItem(value: 'Ranperkada', child: Text('Ranperkada (Perkada/Perbup/Perwali)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _jenisRancangan = val);
                  },
                ),
                const SizedBox(height: 12),

                // Pokok Materi / Tentang
                TextFormField(
                  controller: _tentangController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pokok Materi / Tentang *',
                    hintText: 'Contoh: Raperda tentang Pajak Daerah dan Retribusi Daerah',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Tanggal & Jam
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal *',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Pilih tanggal' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _jamController,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: const InputDecoration(
                          labelText: 'Jam (WITA) *',
                          suffixIcon: Icon(Icons.access_time, size: 18),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Pilih jam' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nama Kompilator
                TextFormField(
                  controller: _namaKompilatorController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kompilator',
                    hintText: 'Contoh: Ahmad Faisal, S.H. / Siti Rahmah, M.H.',
                    prefixIcon: Icon(Icons.people_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Tim Pokja
                TextFormField(
                  controller: _timPokjaController,
                  decoration: const InputDecoration(
                    labelText: 'Tim Pokja',
                    hintText: 'Contoh: Pokja I, Pokja II, dsb.',
                    prefixIcon: Icon(Icons.group_work_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Text(isEdit ? 'Perbarui' : 'Simpan Agenda'),
        ),
      ],
    );
  }
}
