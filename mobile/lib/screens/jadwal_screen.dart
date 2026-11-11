import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/jadwal_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'jadwal_form_dialog.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  List<JadwalItem> _allItems = [];
  String _selectedPokja = 'semua';
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _weekdaysIndo = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthsIndo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService().getJadwal();
      if (!mounted) return;
      setState(() {
        _allItems = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isPokja1(String pokja) {
    final lower = pokja.toLowerCase().trim();
    return lower.contains('1') || RegExp(r'\bpokja\s*i\b').hasMatch(lower);
  }

  bool _isPokja2(String pokja) {
    final lower = pokja.toLowerCase().trim();
    return lower.contains('2') || RegExp(r'\bpokja\s*ii\b').hasMatch(lower);
  }

  String _formatPokjaDisplay(String pokja) {
    if (_isPokja1(pokja)) return 'Pokja 1 (Kab/Kota)';
    if (_isPokja2(pokja)) return 'Pokja 2 (Provinsi)';
    return pokja.trim().isEmpty ? '-' : pokja;
  }

  String _formatTanggalJam(String tanggalRaw, String jamRaw) {
    String dateFormatted = tanggalRaw;
    final parsed = DateTime.tryParse(tanggalRaw.trim());
    if (parsed != null) {
      final dayName = _weekdaysIndo[parsed.weekday - 1];
      final monthName = _monthsIndo[parsed.month - 1];
      dateFormatted = '$dayName, ${parsed.day} $monthName ${parsed.year}';
    }

    String jamFormatted = jamRaw.trim();
    final timeMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(jamFormatted);
    if (timeMatch != null) {
      final hh = timeMatch.group(1)!.padLeft(2, '0');
      final mm = timeMatch.group(2)!.padLeft(2, '0');
      jamFormatted = '$hh.$mm WITA';
    } else if (jamFormatted.isNotEmpty &&
        !jamFormatted.toUpperCase().contains('WITA')) {
      jamFormatted = '$jamFormatted WITA';
    }

    if (dateFormatted.isEmpty) return jamFormatted;
    if (jamFormatted.isEmpty) return dateFormatted;
    return '$dateFormatted • $jamFormatted';
  }

  Future<void> _openForm({JadwalItem? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => JadwalFormDialog(item: item),
    );
    if (saved == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item == null
                  ? 'Jadwal harmonisasi berhasil ditambahkan.'
                  : 'Jadwal harmonisasi berhasil diperbarui.',
            ),
            backgroundColor: AppColors.statusBerlakuText,
          ),
        );
      }
      _fetchJadwal();
    }
  }

  Future<void> _confirmDelete(JadwalItem item) async {
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
                'Hapus Jadwal Rapat',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus agenda "${item.jenisRancangan} — ${item.tentang}" dari daftar jadwal?',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ApiService().deleteJadwal(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agenda jadwal berhasil dihapus.'),
          backgroundColor: AppColors.statusBerlakuText,
        ),
      );
      _fetchJadwal();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showWeeklyPrintSheet(List<JadwalItem> items) {
    final buffer = StringBuffer()
      ..writeln('AGENDA JADWAL HARMONISASI REGULASI DAERAH')
      ..writeln('Kantor Wilayah Kementerian Hukum Kalimantan Selatan')
      ..writeln('Filter: ${_selectedPokja == 'semua' ? 'Semua Pokja' : _selectedPokja == 'pokja1' ? 'Pokja 1' : 'Pokja 2'} (${items.length} rancangan)')
      ..writeln('=' * 42);

    if (items.isEmpty) {
      buffer.writeln('Belum ada jadwal harmonisasi yang ditampilkan.');
    } else {
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        buffer
          ..writeln('${i + 1}. [${it.jenisRancangan.toUpperCase()}] ${it.tentang}')
          ..writeln('   Waktu      : ${_formatTanggalJam(it.tanggal, it.jam)}')
          ..writeln('   Tim        : ${_formatPokjaDisplay(it.timPokja)}')
          ..writeln('   Kompilator : ${it.namaKompilator}')
          ..writeln('   Penginput  : ${it.dibuatOleh}')
          ..writeln();
      }
    }

    final summaryText = buffer.toString().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_outlined,
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
                          'Ringkasan Cetak Jadwal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Salin laporan jadwal untuk dibagikan atau dicetak',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      summaryText,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.primarySlate,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: summaryText));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ringkasan jadwal mingguan disalin ke clipboard.',
                            ),
                            backgroundColor: AppColors.statusBerlakuText,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 17),
                      label: const Text('Salin Ringkasan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final canManage = user?.canManageJadwal ?? false;

    final pokja1Count = _allItems.where((e) => _isPokja1(e.timPokja)).length;
    final pokja2Count = _allItems.where((e) => _isPokja2(e.timPokja)).length;

    final filteredItems = _allItems.where((item) {
      if (_selectedPokja == 'pokja1') return _isPokja1(item.timPokja);
      if (_selectedPokja == 'pokja2') return _isPokja2(item.timPokja);
      return true;
    }).toList();

    final displayItems =
        _isLoading && _allItems.isEmpty
            ? List.generate(4, (_) => JadwalItem.dummy())
            : filteredItems;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchJadwal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Top Header: Jadwal Harmonisasi + KALSEL badge
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jadwal Harmonisasi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'KALSEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Action Buttons
          Row(
            children: [
              if (canManage) ...[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text(
                        'Tambah Jadwal',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showWeeklyPrintSheet(filteredItems),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text(
                      'Cetak Mingguan',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Pills with Counts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PokjaFilterChip(
                  label: 'Semua',
                  count: _allItems.length,
                  isSelected: _selectedPokja == 'semua',
                  onTap: () => setState(() => _selectedPokja = 'semua'),
                ),
                const SizedBox(width: 8),
                _PokjaFilterChip(
                  label: 'Pokja 1',
                  count: pokja1Count,
                  isSelected: _selectedPokja == 'pokja1',
                  onTap: () => setState(() => _selectedPokja = 'pokja1'),
                ),
                const SizedBox(width: 8),
                _PokjaFilterChip(
                  label: 'Pokja 2',
                  count: pokja2Count,
                  isSelected: _selectedPokja == 'pokja2',
                  onTap: () => setState(() => _selectedPokja = 'pokja2'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 17,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total Agenda: ${_allItems.length} Rancangan',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Ditampilkan: '),
                      TextSpan(
                        text: '${filteredItems.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.deleteBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 32,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gagal Memuat Jadwal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchJadwal,
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (!_isLoading && filteredItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_busy_outlined,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum Ada Agenda Harmonisasi',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Belum ada jadwal rapat pada filter Pokja yang dipilih.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Skeletonizer(
              enabled: _isLoading,
              child: Column(
                children: displayItems
                    .map((item) => _buildJadwalCard(item, canManage))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(JadwalItem item, bool canManage) {
    final isRanperda = item.jenisRancangan.toLowerCase().contains('perda');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: RANPERDA/RANPERGUB badge + Date/Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isRanperda ? AppColors.primaryLight : AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.jenisRancangan.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _formatTanggalJam(item.tanggal, item.jam),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title (Tentang)
          Text(
            item.tentang,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Pokja Row
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 16,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _formatPokjaDisplay(item.timPokja),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Kompilator Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.badge_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Kompilator: ${item.namaKompilator}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer: Dibuat oleh + Edit/Delete Icon Buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  'Diinput: ${item.dibuatOleh}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManage) ...[
                InkWell(
                  onTap: () => _openForm(item: item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.editBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _confirmDelete(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.deleteBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.deleteIcon,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PokjaFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _PokjaFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.infoBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
