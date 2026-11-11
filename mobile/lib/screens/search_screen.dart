import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/search_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/peraturan_edit_dialogs.dart';
import 'peraturan_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _errorMessage;

  List<SearchItem> _items = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  String _selectedSektor = '';
  String _selectedWilayah = '';
  List<String> _sektorList = [];
  List<String> _wilayahList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().search(
        query: _searchController.text.trim(),
        sektor: _selectedSektor,
        wilayah: _selectedWilayah,
        page: page,
        pageSize: _pageSize,
      );

      setState(() {
        _items = res.items;
        _totalCount = res.totalCount;
        _currentPage = res.currentPage;
        _totalPages = res.totalPages;
        if (res.sektorList.isNotEmpty) _sektorList = res.sektorList;
        if (res.wilayahList.isNotEmpty) _wilayahList = res.wilayahList;
        _isLoading = false;
      });

      // Scroll to top on page change
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String tempSektor = _selectedSektor;
        String tempWilayah = _selectedWilayah;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Pencarian',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSektor = '';
                              tempWilayah = '';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Filter Sektor
                    const Text('Sektor Hukum', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: tempSektor.isEmpty ? null : tempSektor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Semua Sektor',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Semua Sektor')),
                        ..._sektorList.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          tempSektor = val ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Filter Wilayah
                    const Text('Cakupan Wilayah', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: tempWilayah.isEmpty ? null : tempWilayah,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Semua Wilayah',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Semua Wilayah')),
                        ..._wilayahList.map((w) => DropdownMenuItem(value: w, child: Text(w))),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          tempWilayah = val ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedSektor = tempSektor;
                            _selectedWilayah = tempWilayah;
                          });
                          _fetchData(page: 1);
                        },
                        child: const Text('Terapkan Filter'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan dokumen asli tidak tersedia')),
      );
      return;
    }
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka tautan dokumen')),
          );
        }
      }
    }
  }

  void _copyPasal(SearchItem item) {
    final text = '${item.peraturanTitle}\n${item.nomorPasal} ${item.nomorAyat}\n\n${item.teksPasal}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teks ${item.nomorPasal} berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchData(page: _currentPage),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Header Box
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    // Search bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _fetchData(page: 1),
                            decoration: InputDecoration(
                              hintText: 'Nomor Undang-Undang atau Kata Kunci',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      tooltip: 'Hapus kata kunci',
                                      onPressed: () {
                                        _searchController.clear();
                                        _fetchData(page: 1);
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: (_selectedSektor.isNotEmpty || _selectedWilayah.isNotEmpty)
                                ? AppColors.accent
                                : Colors.transparent,
                            border: Border.all(
                              color: (_selectedSektor.isNotEmpty || _selectedWilayah.isNotEmpty)
                                  ? AppColors.accent
                                  : const Color(0xFF475569),
                            ),
                            borderRadius: AppRadius.controlR,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune, color: Colors.white),
                            tooltip: 'Filter Sektor & Wilayah',
                            onPressed: _openFilterDialog,
                          ),
                        ),
                      ],
                    ),

                    // Active filter pills
                    if (_selectedSektor.isNotEmpty || _selectedWilayah.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_selectedSektor.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text('Sektor: $_selectedSektor', style: const TextStyle(fontSize: 11)),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    setState(() => _selectedSektor = '');
                                    _fetchData(page: 1);
                                  },
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (_selectedWilayah.isNotEmpty)
                              Chip(
                                label: Text('Wilayah: $_selectedWilayah', style: const TextStyle(fontSize: 11)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() => _selectedWilayah = '');
                                  _fetchData(page: 1);
                                },
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Results count banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading ? 'Memuat data peraturan...' : 'Ditemukan $_totalCount pasal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_totalPages > 1 && !_isLoading)
                      Text(
                        'Hal $_currentPage dari $_totalPages',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),

            // Error Display
            if (_errorMessage != null && !_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      border: Border.all(color: AppColors.dangerBorder),
                      borderRadius: AppRadius.containerR,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.danger, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _fetchData(page: _currentPage),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Empty State
            if (!_isLoading && _items.isEmpty && _errorMessage == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada pasal ditemukan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Coba kata kunci lain atau ubah filter sektor dan wilayah Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Skeletonizer Item List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Skeletonizer(
                  enabled: _isLoading,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _isLoading ? 4 : _items.length,
                    itemBuilder: (context, index) {
                      final item = _isLoading ? SearchItem.dummy() : _items[index];
                      return _buildItemCard(item);
                    },
                  ),
                ),
              ),
            ),

            // Pagination Footer
            if (!_isLoading && _totalPages > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentPage > 1 ? () => _fetchData(page: _currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Sebelumnya'),
                      ),
                      Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentPage < _totalPages ? () => _fetchData(page: _currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Berikutnya'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(SearchItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Regulation title + Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.peraturanTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusBg(item.status),
                    border: Border.all(color: AppColors.getStatusBorder(item.status)),
                    borderRadius: AppRadius.tagR,
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.55,
                      color: AppColors.getStatusText(item.status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Article Number & Ayat
            Builder(
              builder: (context) {
                final hasPasal = item.pasalId > 0 || _isLoading;
                return Row(
                  children: [
                    Text(
                      hasPasal
                          ? (item.nomorPasal.isNotEmpty ? item.nomorPasal : 'Pasal')
                          : 'Belum ada pasal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: hasPasal ? 0.3 : 0,
                        color: hasPasal ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    if (hasPasal && item.nomorAyat.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.nomorAyat,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Article text (blok kutipan hukum: border kiri 3px)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
              ),
              child: Text(
                item.teksPasal,
                style: const TextStyle(
                  fontSize: 14,
                  height: 22 / 14,
                  color: AppColors.textBody,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Metadata pills: Wilayah & Sektor
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.tagR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(item.wilayah, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.tagR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(item.sektor, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if ((AuthService().currentUser?.canManagePeraturan ?? false) && !_isLoading)
                  PopupMenuButton<String>(
                    tooltip: 'Kelola Peraturan / Pasal',
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    onSelected: (action) async {
                      final messenger = ScaffoldMessenger.of(context);
                      bool changed = false;
                      String? msg;

                      if (action == 'edit_peraturan') {
                        changed = await showEditPeraturanDialog(context, {
                          'id': item.peraturanId,
                          'jenis_peraturan': item.jenisPeraturan,
                          'nomor': item.nomor,
                          'tahun': item.tahun,
                          'judul': item.judul,
                          'status': item.status,
                          'status_detail': item.statusDetail ?? '',
                          'wilayah': item.wilayah,
                          'sektor': item.sektor,
                          'url_dokumen_asli': item.urlDokumenAsli ?? '',
                        });
                        if (changed) msg = 'Peraturan berhasil diperbarui';
                      } else if (action == 'hapus_peraturan') {
                        changed = await confirmDeletePeraturanDialog(
                          context,
                          item.peraturanId,
                          item.peraturanTitle,
                        );
                        if (changed) msg = 'Peraturan berhasil dihapus';
                      } else if (action == 'edit_pasal' && item.pasalId > 0) {
                        changed = await showEditPasalDialog(context, {
                          'id': item.pasalId,
                          'nomor_pasal': item.nomorPasal,
                          'nomor_ayat': item.nomorAyat,
                          'teks_pasal': item.teksPasal,
                        });
                        if (changed) msg = 'Pasal berhasil diperbarui';
                      } else if (action == 'hapus_pasal' && item.pasalId > 0) {
                        changed = await confirmDeletePasalDialog(
                          context,
                          item.pasalId,
                          item.nomorPasal.isNotEmpty ? item.nomorPasal : 'pasal ini',
                        );
                        if (changed) msg = 'Pasal berhasil dihapus';
                      }

                      if (changed && mounted) {
                        if (msg != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
                          );
                        }
                        _fetchData(page: _currentPage);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit_peraturan', child: Text('Edit Peraturan')),
                      if (item.pasalId > 0)
                        const PopupMenuItem(value: 'edit_pasal', child: Text('Edit Pasal')),
                      if (item.pasalId > 0)
                        PopupMenuItem(
                          value: 'hapus_pasal',
                          child: const Text('Hapus Pasal', style: TextStyle(color: AppColors.danger)),
                        ),
                      const PopupMenuItem(
                        value: 'hapus_peraturan',
                        child: Text('Hapus Peraturan', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                if (item.pasalId > 0)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Salin Teks Pasal',
                    onPressed: () => _copyPasal(item),
                  ),
                if (item.urlDokumenAsli != null && item.urlDokumenAsli!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _launchUrl(item.urlDokumenAsli),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Dokumen Asli', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () async {
                    final modified = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PeraturanDetailScreen(
                          peraturanId: item.peraturanId,
                          initialItem: item,
                        ),
                      ),
                    );
                    if (modified == true && mounted) {
                      _fetchData(page: _currentPage);
                    }
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Status & Pasal', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
