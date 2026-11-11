import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/peraturan_edit_dialogs.dart';

class PeraturanDetailScreen extends StatefulWidget {
  final int peraturanId;
  final String highlightQuery;

  const PeraturanDetailScreen({
    super.key,
    required this.peraturanId,
    this.highlightQuery = '',
  });

  @override
  State<PeraturanDetailScreen> createState() => _PeraturanDetailScreenState();
}

class _PeraturanDetailScreenState extends State<PeraturanDetailScreen> {
  final TextEditingController _filterCtrl = TextEditingController();

  Map<String, dynamic>? _peraturan;
  List<Map<String, dynamic>> _pasalList = [];
  String _filterText = '';
  bool _isLoading = true;
  bool _hasMutated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().getPeraturanDetail(widget.peraturanId);
      final rawPeraturan = res['peraturan'];
      final rawPasal = res['pasalList'] ?? res['pasal'] ?? res['results'] ?? [];

      if (!mounted) return;
      setState(() {
        _peraturan = rawPeraturan is Map
            ? Map<String, dynamic>.from(rawPeraturan)
            : Map<String, dynamic>.from(res);
        _pasalList = (rawPasal is List)
            ? rawPasal
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
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

  List<String> _extractStatusEntries(Map<String, dynamic> p) {
    final List<String> entries = [];
    final raw = p['status_detail_json'];
    dynamic decoded = raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(raw.trim());
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
    final detail = p['status_detail']?.toString().trim() ?? '';
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
    if (query.trim().isEmpty) return [TextSpan(text: text)];
    final words = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .map(RegExp.escape)
        .toList();
    if (words.isEmpty) return [TextSpan(text: text)];

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

  Map<String, Color> _statusBadgeStyle(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('berlaku') && !lower.contains('tidak')) {
      return {'bg': const Color(0xFFECFDF5), 'fg': const Color(0xFF15803D)};
    }
    if (lower.contains('ubah') || lower.contains('revisi')) {
      return {'bg': const Color(0xFFFEF3C7), 'fg': const Color(0xFFB45309)};
    }
    if (lower.contains('cabut') || lower.contains('batal')) {
      return {'bg': const Color(0xFFFEE2E2), 'fg': AppColors.danger};
    }
    return {'bg': AppColors.infoBg, 'fg': AppColors.primaryLight};
  }

  Future<void> _editPeraturan() async {
    if (_peraturan == null) return;
    final changed = await showEditPeraturanDialog(context, _peraturan!);
    if (changed) {
      _hasMutated = true;
      _fetchDetail();
    }
  }

  Future<void> _deletePeraturan() async {
    final p = _peraturan;
    final jenis = (p?['jenis_peraturan'] ?? p?['jenis'] ?? '').toString();
    final label = p == null
        ? 'Peraturan #${widget.peraturanId}'
        : '$jenis No. ${p['nomor'] ?? ''} Tahun ${p['tahun'] ?? ''}';
    final deleted = await confirmDeletePeraturanDialog(
      context,
      widget.peraturanId,
      label.trim(),
    );
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _editPasal(Map<String, dynamic> pasal) async {
    final changed = await showEditPasalDialog(context, pasal);
    if (changed) {
      _hasMutated = true;
      _fetchDetail();
    }
  }

  Future<void> _deletePasal(Map<String, dynamic> pasal) async {
    final id = int.tryParse(pasal['id']?.toString() ?? '') ?? 0;
    if (id <= 0) return;
    final label =
        (pasal['nomor_pasal'] ?? pasal['pasal_nomor'] ?? 'Pasal').toString();
    final deleted = await confirmDeletePasalDialog(context, id, label);
    if (deleted) {
      _hasMutated = true;
      _fetchDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AuthService().currentUser?.canManagePeraturan ?? false;
    final p = _peraturan ?? {};
    final jenis =
        (p['jenis_peraturan'] ?? p['jenis'] ?? 'PERATURAN').toString();
    final nomor = p['nomor']?.toString() ?? '-';
    final tahun = p['tahun']?.toString() ?? '-';
    final judul =
        (p['judul'] ?? p['tentang'] ?? 'Memuat judul peraturan...').toString();
    final wilayah = p['wilayah']?.toString() ?? '';
    final sektor = p['sektor']?.toString() ?? '';
    final status = p['status']?.toString() ?? 'Berlaku';
    final url =
        (p['url_dokumen_asli'] ?? p['url'] ?? '').toString().trim();
    final statusEntries = _peraturan != null
        ? _extractStatusEntries(_peraturan!)
        : <String>[];

    final effectiveQuery = _filterText.trim().isNotEmpty
        ? _filterText.trim()
        : widget.highlightQuery;

    final filteredPasal = _pasalList.where((item) {
      if (_filterText.trim().isEmpty) return true;
      final needle = _filterText.trim().toLowerCase();
      final no =
          (item['nomor_pasal'] ?? item['pasal_nomor'] ?? '').toString().toLowerCase();
      final ayat = (item['nomor_ayat'] ?? '').toString().toLowerCase();
      final isi =
          (item['teks_pasal'] ?? item['isi_pasal'] ?? item['isi'] ?? '')
              .toString()
              .toLowerCase();
      return no.contains(needle) || ayat.contains(needle) || isi.contains(needle);
    }).toList();

    final displayPasal = _isLoading && _pasalList.isEmpty
        ? List.generate(
            4,
            (i) => {
              'id': i + 1,
              'nomor_pasal': 'Pasal ${i + 1}',
              'nomor_ayat': '',
              'teks_pasal':
                  'Ketentuan umum dan pengaturan lebih lanjut mengenai penyelenggaraan urusan pemerintahan daerah sebagaimana dimaksud pada ayat ini.',
            },
          )
        : filteredPasal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_hasMutated);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasMutated),
          ),
          title: const Text(
            'Detail Peraturan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (canManage && _peraturan != null) ...[
              IconButton(
                tooltip: 'Edit Peraturan',
                icon: const Icon(Icons.edit_outlined, size: 21),
                onPressed: _editPeraturan,
              ),
              IconButton(
                tooltip: 'Hapus Peraturan',
                icon: const Icon(Icons.delete_outline, size: 21),
                onPressed: _deletePeraturan,
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchDetail,
          child: _errorMessage != null
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.deleteBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 36,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Gagal Memuat Detail Peraturan',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _fetchDetail,
                            icon: const Icon(Icons.refresh, size: 17),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Skeletonizer(
                  enabled: _isLoading,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Metadata Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
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
                                    jenis.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                                if (wilayah.isNotEmpty)
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
                                      wilayah.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (sektor.isNotEmpty)
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
                                      sektor.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBadgeStyle(status)['bg'],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _statusBadgeStyle(status)['fg'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$jenis No. $nomor Tahun $tahun',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              judul,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            if (url.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.tryParse(url);
                                    if (uri != null) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 17),
                                  label: const Text('Buka Dokumen Sumber Resmi'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Status & Keterangan Hubungan Card (non-clickable Pasal highlights)
                      if (statusEntries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.account_tree_outlined,
                                    size: 18,
                                    color: AppColors.primaryLight,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Keterangan & Pasal Terdampak',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...statusEntries.map(
                                (entry) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBg.withValues(
                                      alpha: 0.65,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        height: 1.45,
                                      ),
                                      children: _buildHighlightedPasalSpans(
                                        entry,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Daftar Pasal (${_pasalList.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _filterCtrl,
                        onChanged: (v) => setState(() => _filterText = v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          hintText: 'Saring nomor atau isi pasal...',
                          prefixIcon: const Icon(
                            Icons.filter_list,
                            size: 19,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: _filterText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _filterCtrl.clear();
                                    setState(() => _filterText = '');
                                  },
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!_isLoading && filteredPasal.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Belum ada data pasal yang cocok dengan saringan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...displayPasal.map((pasal) {
                          final nomorPasal =
                              (pasal['nomor_pasal'] ??
                                      pasal['pasal_nomor'] ??
                                      'Pasal')
                                  .toString();
                          final nomorAyat =
                              (pasal['nomor_ayat'] ?? '').toString().trim();
                          final headerLabel = nomorAyat.isNotEmpty
                              ? '$nomorPasal $nomorAyat'
                              : nomorPasal;
                          final teksPasal =
                              (pasal['teks_pasal'] ??
                                      pasal['isi_pasal'] ??
                                      pasal['isi'] ??
                                      '')
                                  .toString();

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
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.infoBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.gavel_outlined,
                                        size: 16,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        headerLabel,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Salin Pasal',
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: '$headerLabel\n$teksPasal',
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Pasal disalin.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    if (canManage) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _editPasal(pasal),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.editBg,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 17,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _deletePasal(pasal),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.deleteBg,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 17,
                                            color: AppColors.deleteIcon,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SelectableText.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.primarySlate,
                                        height: 1.5,
                                      ),
                                      children: _buildQueryHighlightSpans(
                                        teksPasal,
                                        effectiveQuery,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
