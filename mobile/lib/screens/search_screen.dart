import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/search_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _fetchData(page: 1),
                              decoration: InputDecoration(
                                hintText: 'Cari pasal, topik, undang-undang...',
                                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _fetchData(page: 1);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: (_selectedSektor.isNotEmpty || _selectedWilayah.isNotEmpty)
                                ? AppColors.accent
                                : Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.red, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _fetchData(page: _currentPage),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
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
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada pasal ditemukan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentPage < _totalPages ? () => _fetchData(page: _currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Berikutnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.getStatusBg(item.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getStatusText(item.status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Article Number & Ayat
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBlueBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.nomorPasal.isNotEmpty ? item.nomorPasal : 'Pasal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.badgeBlueText,
                    ),
                  ),
                ),
                if (item.nomorAyat.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.nomorAyat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Article text
            Text(
              item.teksPasal,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
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
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Salin Teks Pasal',
                  onPressed: () => _copyPasal(item),
                ),
                if (item.urlDokumenAsli != null && item.urlDokumenAsli!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _launchUrl(item.urlDokumenAsli),
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                    label: const Text('PDF Asli', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PeraturanDetailScreen(
                          peraturanId: item.peraturanId,
                          initialItem: item,
                        ),
                      ),
                    );
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
