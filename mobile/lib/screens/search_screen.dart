import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SearchItem> _items = [];
  List<String> _sektorList = [];
  List<String> _wilayahList = [];
  List<String> _searchHistory = [];

  String _selectedSektor = '';
  String _selectedWilayah = '';
  String _sortBy = 'relevansi';
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  int _totalCount = 0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _performSearch(page: 1, saveHistory: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(AppConstants.prefSearchHistory) ?? [];
    if (!mounted) return;
    setState(() {
      _searchHistory = saved;
    });
  }

  Future<void> _saveQueryToHistory(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final updated = [
      clean,
      ..._searchHistory.where((q) => q.toLowerCase() != clean.toLowerCase()),
    ].take(15).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefSearchHistory, updated);
    if (!mounted) return;
    setState(() {
      _searchHistory = updated;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSearchHistory);
    if (!mounted) return;
    setState(() {
      _searchHistory = [];
    });
  }

  Future<void> _performSearch({int page = 1, bool saveHistory = true}) async {
    final query = _searchController.text.trim();
    if (saveHistory && query.isNotEmpty) {
      _saveQueryToHistory(query);
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final res = await ApiService().search(
        query: query,
        sektor: _selectedSektor,
        wilayah: _selectedWilayah,
        page: page,
        pageSize: _pageSize,
      );

      final sortedResults = List<SearchItem>.from(res.items);
      if (_sortBy == 'terbaru') {
        sortedResults.sort((a, b) => b.tahun.compareTo(a.tahun));
      }

      if (!mounted) return;
      setState(() {
        _items = sortedResults;
        _sektorList = res.sektorList;
        _wilayahList = res.wilayahList;
        _totalCount = res.totalCount;
        _totalPages = res.totalPages < 1 ? 1 : res.totalPages;
        _currentPage = res.currentPage < 1 ? 1 : res.currentPage;
        _isLoading = false;
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _pasalHeader(SearchItem item) {
    final p = item.nomorPasal.trim();
    final a = item.nomorAyat.trim();
    if (p.isEmpty && a.isEmpty) return 'Pasal';
    if (a.isEmpty) return p;
    return '$p $a';
  }

  void _openDetail(SearchItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PeraturanDetailScreen(
          peraturanId: item.peraturanId,
          highlightQuery: _searchController.text.trim(),
        ),
      ),
    );
    if (changed == true) {
      _performSearch(page: _currentPage, saveHistory: false);
    }
  }

  Future<void> _handleEditAction(SearchItem item) async {
    final hasPasal = item.pasalId > 0;
    final pasalLabel = _pasalHeader(item);
    String? action = 'peraturan';

    if (hasPasal) {
      action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                const Text(
                  'Pilih Data yang Diedit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.peraturanTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: AppColors.infoBg,
                  leading: const Icon(
                    Icons.gavel_outlined,
                    color: AppColors.primaryLight,
                  ),
                  title: Text(
                    'Edit $pasalLabel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Ubah nomor atau isi teks pasal',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop('pasal'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: AppColors.inputFill,
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Edit Metadata Peraturan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Ubah jenis, nomor, tahun, judul, status, atau URL',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop('peraturan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!mounted || action == null) return;

    if (action == 'pasal' && hasPasal) {
      final updated = await showEditPasalDialog(context, {
        'id': item.pasalId,
        'nomor_pasal': item.nomorPasal,
        'nomor_ayat': item.nomorAyat,
        'teks_pasal': item.teksPasal,
      });
      if (updated) {
        _performSearch(page: _currentPage, saveHistory: false);
      }
    } else if (action == 'peraturan') {
      try {
        final detail = await ApiService().getPeraturanDetail(item.peraturanId);
        if (!mounted) return;
        final peraturanMap = Map<String, dynamic>.from(
          detail['peraturan'] ??
              {
                'id': item.peraturanId,
                'jenis_peraturan': item.jenisPeraturan,
                'nomor': item.nomor,
                'tahun': item.tahun,
                'judul': item.judul,
                'wilayah': item.wilayah,
                'sektor': item.sektor,
                'status': item.status,
                'status_detail': item.statusDetail ?? '',
                'url_dokumen_asli': item.urlDokumenAsli ?? '',
              },
        );
        final updated = await showEditPeraturanDialog(context, peraturanMap);
        if (updated) {
          _performSearch(page: _currentPage, saveHistory: false);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat detail peraturan: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAction(SearchItem item) async {
    final hasPasal = item.pasalId > 0;
    final pasalLabel = _pasalHeader(item);
    String? action = 'peraturan';

    if (hasPasal) {
      action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                const Text(
                  'Opsi Penghapusan Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.peraturanTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: AppColors.deleteBg,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.deleteIcon,
                  ),
                  title: Text(
                    'Hapus $pasalLabel Saja',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deleteIcon,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Menghapus pasal ini dari peraturan terkait',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop('pasal'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: AppColors.inputFill,
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Hapus Seluruh Peraturan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Menghapus peraturan beserta seluruh pasalnya',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop('peraturan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!mounted || action == null) return;

    if (action == 'pasal' && hasPasal) {
      final deleted = await confirmDeletePasalDialog(
        context,
        item.pasalId,
        pasalLabel,
      );
      if (deleted) {
        _performSearch(page: _currentPage, saveHistory: false);
      }
    } else {
      final deleted = await confirmDeletePeraturanDialog(
        context,
        item.peraturanId,
        item.peraturanTitle,
      );
      if (deleted) {
        _performSearch(page: _currentPage, saveHistory: false);
      }
    }
  }

  void _showStatusHubunganSheet(SearchItem item) {
    final parsedDetails = _extractStatusEntries(item);
    final urlStr = item.urlDokumenAsli?.trim() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final statusColors = _statusBadgeStyle(item.status);
        return SafeArea(
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
                        Icons.account_tree_outlined,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status & Hubungan Peraturan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            item.peraturanTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors['bg'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColors['fg'],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Judul / Tentang:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.judul,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.primary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _metaChip('Sektor', item.sektor),
                          _metaChip(
                            'Wilayah',
                            item.wilayah.isEmpty ? 'Pusat / Umum' : item.wilayah,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Keterangan Relasi & Pasal Terdampak',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (parsedDetails.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Belum ada catatan hubungan peraturan (mengubah, dicabut, atau diubah oleh) yang tercatat.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: parsedDetails.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final entry = parsedDetails[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(alpha: 0.2),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                height: 1.45,
                              ),
                              children: _buildHighlightedPasalSpans(entry),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (urlStr.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(urlStr);
                            if (uri != null) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 17),
                          label: const Text('Buka Sumber'),
                        ),
                      ),
                    if (urlStr.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openDetail(item);
                        },
                        child: const Text('Buka Semua Pasal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  List<String> _extractStatusEntries(SearchItem item) {
    final List<String> entries = [];
    dynamic decoded = item.statusDetailJson;
    if (decoded is String && decoded.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(decoded.trim());
      } catch (_) {}
    }
    if (decoded is List) {
      for (final row in decoded) {
        if (row is Map) {
          final tipe = row['tipe']?.toString() ?? '';
          final ref =
              row['peraturan']?.toString() ?? row['judul']?.toString() ?? '';
          final ket =
              row['keterangan']?.toString() ?? row['detail']?.toString() ?? '';
          final combined = [tipe, ref, ket]
              .where((s) => s.trim().isNotEmpty)
              .join(' — ');
          if (combined.isNotEmpty) entries.add(combined);
        } else if (row != null && row.toString().trim().isNotEmpty) {
          entries.add(row.toString().trim());
        }
      }
    }
    final detail = item.statusDetail?.trim() ?? '';
    if (entries.isEmpty && detail.isNotEmpty) {
      entries.add(detail);
    }
    return entries;
  }

  List<InlineSpan> _buildHighlightedPasalSpans(String text) {
    final regex = RegExp(
      r'\b(Pasal\s+\d+[A-Za-z]?(?:\s+(?:sampai\s+dengan|s\.?d\.?|dan)\s+\d+[A-Za-z]?)?)\b',
      caseSensitive: false,
    );
    final List<InlineSpan> spans = [];
    int start = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFEAB308), width: 0.6),
            ),
            child: Text(
              match.group(0)!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF854D0E),
              ),
            ),
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  List<TextSpan> _buildQueryHighlightSpans(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    final words = query
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .map(RegExp.escape)
        .toList();
    if (words.isEmpty) {
      return [TextSpan(text: text)];
    }
    final pattern = RegExp('(${words.join('|')})', caseSensitive: false);
    final List<TextSpan> spans = [];
    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            backgroundColor: Color(0xFFFEF08A),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
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
                  const Expanded(
                    child: Text(
                      'Riwayat Pencarian Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_searchHistory.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await _clearHistory();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text(
                        'Hapus Semua',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_searchHistory.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Belum ada riwayat kata kunci pencarian di perangkat ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchHistory.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, idx) {
                      final term = _searchHistory[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.history,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(
                          term,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.north_west,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _searchController.text = term;
                          _performSearch(page: 1);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    String tempSektor = _selectedSektor;
    String tempWilayah = _selectedWilayah;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
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
                    const Expanded(
                      child: Text(
                        'Filter Pencarian Pasal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
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
                const SizedBox(height: 12),
                const Text(
                  'Wilayah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tempWilayah.isEmpty ? null : tempWilayah,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Semua Wilayah',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua Wilayah'),
                    ),
                    ..._wilayahList.map(
                      (w) => DropdownMenuItem(value: w, child: Text(w)),
                    ),
                  ],
                  onChanged: (val) =>
                      setModalState(() => tempWilayah = val ?? ''),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sektor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tempSektor.isEmpty ? null : tempSektor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Semua Sektor',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua Sektor'),
                    ),
                    ..._sektorList.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (val) =>
                      setModalState(() => tempSektor = val ?? ''),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedSektor = tempSektor;
                        _selectedWilayah = tempWilayah;
                      });
                      _performSearch(page: 1, saveHistory: false);
                    },
                    child: const Text('Terapkan Filter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _statusBadgeStyle(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('berlaku') && !lower.contains('tidak')) {
      return {
        'bg': const Color(0xFFECFDF5),
        'fg': const Color(0xFF15803D),
      };
    }
    if (lower.contains('ubah') || lower.contains('revisi')) {
      return {
        'bg': const Color(0xFFFEF3C7),
        'fg': const Color(0xFFB45309),
      };
    }
    if (lower.contains('cabut') || lower.contains('batal')) {
      return {
        'bg': const Color(0xFFFEE2E2),
        'fg': AppColors.danger,
      };
    }
    return {
      'bg': AppColors.infoBg,
      'fg': AppColors.primaryLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final canManage = user?.canManagePeraturan ?? false;
    final roleLine =
        '${(user?.displayName ?? 'Tamu').toUpperCase()} / ${(user?.roleSubtitle ?? 'Akses Publik').toUpperCase()}';
    final hasActiveFilter =
        _selectedSektor.isNotEmpty || _selectedWilayah.isNotEmpty;

    final displayItems =
        _isLoading && _items.isEmpty
            ? List.generate(4, (_) => SearchItem.dummy())
            : _items;

    final startIndex =
        _totalCount == 0 ? 0 : ((_currentPage - 1) * _pageSize) + 1;
    final endIndex =
        (_currentPage * _pageSize) > _totalCount
            ? _totalCount
            : (_currentPage * _pageSize);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _performSearch(page: _currentPage, saveHistory: false),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pencarian Pasal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLine,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SquareIconButton(
                icon: Icons.history,
                tooltip: 'Riwayat Pencarian',
                onTap: _showHistorySheet,
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _SquareIconButton(
                    icon: Icons.tune,
                    tooltip: 'Filter Wilayah & Sektor',
                    isActive: hasActiveFilter,
                    onTap: _showFilterSheet,
                  ),
                  if (hasActiveFilter)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: CircleAvatar(
                        radius: 4.5,
                        backgroundColor: AppColors.primaryLight,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Box + Dark Navy "Cari" CTA
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(page: 1),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari kata kunci, nomor pasal, atau judul...',
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                      ),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch(page: 1, saveHistory: false);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _performSearch(page: 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cari',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Pill Strip
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterPill(
                  label: 'Semua Sektor',
                  isSelected: _selectedSektor.isEmpty,
                  onTap: () {
                    if (_selectedSektor.isNotEmpty) {
                      setState(() => _selectedSektor = '');
                      _performSearch(page: 1, saveHistory: false);
                    }
                  },
                ),
                if (_selectedWilayah.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text(
                      'Wilayah: $_selectedWilayah',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    backgroundColor: AppColors.infoBg,
                    side: BorderSide(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 15,
                      color: AppColors.primaryLight,
                    ),
                    onDeleted: () {
                      setState(() => _selectedWilayah = '');
                      _performSearch(page: 1, saveHistory: false);
                    },
                  ),
                ],
                ..._sektorList.map(
                  (sektor) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterPill(
                      label: sektor,
                      isSelected: _selectedSektor == sektor,
                      onTap: () {
                        setState(() {
                          _selectedSektor =
                              _selectedSektor == sektor ? '' : sektor;
                        });
                        _performSearch(page: 1, saveHistory: false);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Count & Sort row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ditemukan $_totalCount pasal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() {
                    _sortBy =
                        _sortBy == 'relevansi' ? 'terbaru' : 'relevansi';
                    if (_sortBy == 'terbaru') {
                      _items.sort((a, b) => b.tahun.compareTo(a.tahun));
                    } else {
                      _performSearch(page: _currentPage, saveHistory: false);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Urutkan: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _sortBy == 'relevansi' ? 'Relevansi' : 'Tahun Terbaru',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                    'Gagal Memuat Data Pencarian',
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
                    onPressed: () =>
                        _performSearch(page: _currentPage, saveHistory: false),
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (!_isLoading && _items.isEmpty)
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
                      Icons.search_off_rounded,
                      size: 32,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak Ada Pasal Ditemukan',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Coba gunakan kata kunci lain atau bersihkan filter wilayah dan sektor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasActiveFilter || _searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedSektor = '';
                          _selectedWilayah = '';
                        });
                        _performSearch(page: 1, saveHistory: false);
                      },
                      child: const Text('Reset Pencarian'),
                    ),
                  ],
                ],
              ),
            )
          else
            Skeletonizer(
              enabled: _isLoading,
              child: Column(
                children: [
                  ...displayItems.map(
                    (item) => _buildResultCard(item, canManage),
                  ),
                  if (!_isLoading && _totalPages > 0) ...[
                    const SizedBox(height: 4),
                    _buildPaginationBar(startIndex, endIndex),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchItem item, bool canManage) {
    final statusColors = _statusBadgeStyle(item.status);
    final query = _searchController.text.trim();
    final pasalHeaderText = _pasalHeader(item);
    final hasTeks = item.teksPasal.trim().isNotEmpty;

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
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.jenisPeraturan.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                          letterSpacing: 0.3,
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
                      child: Text(
                        (item.wilayah.isNotEmpty ? item.wilayah : item.sektor)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColors['bg'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColors['fg'],
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            item.peraturanTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.judul,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.gavel_outlined,
                      size: 15,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pasalHeaderText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (hasTeks)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${item.peraturanTitle} - $pasalHeaderText\n${item.teksPasal}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teks pasal disalin ke clipboard.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.copy_outlined,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primarySlate,
                      height: 1.45,
                    ),
                    children: _buildQueryHighlightSpans(
                      hasTeks
                          ? item.teksPasal
                          : 'Klik "Lihat Pasal" untuk melihat daftar pasal pada peraturan ini.',
                      query,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton(
                  onPressed: () => _openDetail(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lihat Pasal',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: OutlinedButton(
                  onPressed: () => _showStatusHubunganSheet(item),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Status Hubungan',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _handleEditAction(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
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
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _handleDeleteAction(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
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

  Widget _buildPaginationBar(int startIndex, int endIndex) {
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: canPrev
                ? () => _performSearch(page: _currentPage - 1, saveHistory: false)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textMuted,
              side: BorderSide(
                color: canPrev
                    ? AppColors.border
                    : AppColors.border.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 15),
                SizedBox(width: 4),
                Text('Sebelumnya', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Halaman $_currentPage dari $_totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Menampilkan $startIndex-$endIndex dari $_totalCount data',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canNext
                ? () => _performSearch(page: _currentPage + 1, saveHistory: false)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.inputFill,
              disabledForegroundColor: AppColors.textMuted,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Berikutnya', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.infoBg : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primaryLight : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primarySlate,
          ),
        ),
      ),
    );
  }
}
