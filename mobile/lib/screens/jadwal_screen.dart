import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  List<JadwalItem> _allJadwal = [];
  String _selectedTab = 'Semua'; // 'Semua', 'Ranperda', 'Ranperkada'

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
      setState(() {
        _allJadwal = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _deleteItem(JadwalItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal "${item.tentang}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().deleteJadwal(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil dihapus')),
          );
        }
        _fetchJadwal();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final canWrite = user != null && user.canManageJadwal;

    final filtered = _allJadwal.where((item) {
      if (_selectedTab == 'Semua') return true;
      return item.jenisRancangan.toLowerCase() == _selectedTab.toLowerCase();
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchJadwal,
        child: Column(
          children: [
            // Filter Pills Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildTabChip('Semua'),
                  const SizedBox(width: 8),
                  _buildTabChip('Ranperda'),
                  const SizedBox(width: 8),
                  _buildTabChip('Ranperkada'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Area
            Expanded(
              child: _errorMessage != null && !_isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchJadwal, child: const Text('Muat Ulang')),
                          ],
                        ),
                      ),
                    )
                  : Skeletonizer(
                      enabled: _isLoading,
                      child: _isLoading
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: 4,
                              itemBuilder: (context, index) => _buildCard(JadwalItem.dummy(), canWrite),
                            )
                          : filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Belum ada jadwal rapat harmonisasi',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Jadwal rapat yang telah diagendakan akan tampil di sini.',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return _buildCard(filtered[index], canWrite);
                                  },
                                ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await JadwalFormDialog.show(context);
                if (result == true) {
                  _fetchJadwal();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Agenda'),
            )
          : null,
    );
  }

  Widget _buildTabChip(String label) {
    final isSelected = _selectedTab == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildCard(JadwalItem item, bool canWrite) {
    final isRanperda = item.jenisRancangan.toLowerCase().contains('perda') &&
        !item.jenisRancangan.toLowerCase().contains('perkada');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRanperda ? const Color(0xFFE0E7FF) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.jenisRancangan,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isRanperda ? const Color(0xFF3730A3) : const Color(0xFF6B21A8),
                    ),
                  ),
                ),
                if (canWrite)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                        tooltip: 'Ubah Jadwal',
                        onPressed: () async {
                          final res = await JadwalFormDialog.show(context, editItem: item);
                          if (res == true) _fetchJadwal();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Hapus Jadwal',
                        onPressed: () => _deleteItem(item),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Pokok Materi
            Text(
              item.tentang,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Date & Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  item.tanggal,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  item.jam,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
              ],
            ),
            const Divider(height: 20),

            // Kompilator & Pokja
            if (item.namaKompilator.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kompilator: ${item.namaKompilator}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (item.timPokja.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.group_work_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Tim: ${item.timPokja}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
