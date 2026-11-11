import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/search_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/peraturan_edit_dialogs.dart';

class PeraturanDetailScreen extends StatefulWidget {
  final int peraturanId;
  final SearchItem? initialItem;

  const PeraturanDetailScreen({
    super.key,
    required this.peraturanId,
    this.initialItem,
  });

  @override
  State<PeraturanDetailScreen> createState() => _PeraturanDetailScreenState();
}

class _PeraturanDetailScreenState extends State<PeraturanDetailScreen> {
  bool _isLoading = true;
  bool _wasModified = false;
  String? _errorMessage;
  Map<String, dynamic>? _peraturan;
  List<dynamic> _pasalList = [];
  String _filterQuery = '';

  static const Map<String, String> _statusRelationLabels = {
    'mencabut': 'MENCABUT',
    'mencabut_sebagian': 'MENCABUT SEBAGIAN',
    'diubah_dengan': 'DIUBAH DENGAN',
    'dicabut_dengan': 'DICABUT DENGAN',
    'dicabut_sebagian_dengan': 'DICABUT SEBAGIAN DENGAN',
    'mengubah': 'MENGUBAH',
    'diubah': 'DIUBAH',
    'perubahan': 'PERUBAHAN',
    'peraturan_terkait': 'PERATURAN TERKAIT',
  };

  static final RegExp _pasalHighlightRegex = RegExp(
    r'(Pasal\s+\d+(?:\s*(?:s\.d\.|sampai dengan|-)\s*(?:Pasal\s*)?\d+)?(?:\s+ayat\s*\(\d+\))?(?:\s+huruf\s+[a-z])?(?:\s+angka\s+\d+)?)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().getPeraturanDetail(widget.peraturanId);
      setState(() {
        _peraturan = res['peraturan'] as Map<String, dynamic>?;
        _pasalList = res['pasalList'] as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _openUrl(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleEditPeraturan() async {
    if (_peraturan == null) return;
    final updated = await showEditPeraturanDialog(context, _peraturan!);
    if (!updated || !mounted) return;
    _wasModified = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peraturan berhasil diperbarui'), behavior: SnackBarBehavior.floating),
    );
    await _fetchDetail();
  }

  Future<void> _handleDeletePeraturan(String title) async {
    final deleted = await confirmDeletePeraturanDialog(context, widget.peraturanId, title);
    if (!deleted || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peraturan berhasil dihapus'), behavior: SnackBarBehavior.floating),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _handleEditPasal(Map<String, dynamic> p) async {
    final updated = await showEditPasalDialog(context, p);
    if (!updated || !mounted) return;
    _wasModified = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasal berhasil diperbarui'), behavior: SnackBarBehavior.floating),
    );
    await _fetchDetail();
  }

  Future<void> _handleDeletePasal(int pasalId, String label) async {
    final deleted = await confirmDeletePasalDialog(context, pasalId, label);
    if (!deleted || !mounted) return;
    _wasModified = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasal berhasil dihapus'), behavior: SnackBarBehavior.floating),
    );
    await _fetchDetail();
  }

  List<InlineSpan> _buildHighlightedPasalSpans(String text) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;
    for (final match in _pasalHighlightRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: ' ${match.group(0)} ',
          style: const TextStyle(
            color: AppColors.refText,
            backgroundColor: AppColors.refBg,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }

  Map<String, dynamic>? _parseStatusDetailJson() {
    dynamic raw = _peraturan != null ? _peraturan!['status_detail_json'] : widget.initialItem?.statusDetailJson;
    if (raw == null) return null;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Widget _buildStatusDetailCard() {
    final jsonMap = _parseStatusDetailJson();
    final relationKeys = jsonMap == null
        ? <String>[]
        : jsonMap.keys.where((k) => jsonMap[k] is List && (jsonMap[k] as List).isNotEmpty).toList();
    final plainDetail = (_peraturan != null
            ? _peraturan!['status_detail']
            : widget.initialItem?.statusDetail)
        ?.toString()
        .trim();

    if (relationKeys.isEmpty && (plainDetail == null || plainDetail.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Detil Status & Relasi Peraturan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (relationKeys.isNotEmpty)
              ...relationKeys.map((key) {
                final items = (jsonMap![key] as List);
                final heading = _statusRelationLabels[key] ?? key.replaceAll('_', ' ').toUpperCase();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.controlR,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.map((rawEntry) {
                        final entry = rawEntry is Map ? rawEntry : <String, dynamic>{};
                        final entryUrl = (entry['url'] ?? '').toString().trim();
                        final entryLabel = (entry['judul'] ?? entry['label'] ?? 'Lihat Dokumen').toString();
                        final keterangan = (entry['keterangan'] ?? '').toString().trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entryUrl.isNotEmpty)
                                InkWell(
                                  onTap: () => _openUrl(entryUrl),
                                  child: Text(
                                    entryLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  entryLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              if (keterangan.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.background,
                                    border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textBody),
                                      children: _buildHighlightedPasalSpans(keterangan),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              })
            else if (plainDetail != null && plainDetail.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: AppRadius.controlR,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plainDetail
                      .split('\n')
                      .map((l) => l.trim())
                      .where((l) => l.isNotEmpty)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textBody),
                              children: _buildHighlightedPasalSpans(line),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AuthService().currentUser?.canManagePeraturan ?? false;

    final title = _peraturan != null
        ? '${_peraturan!['jenis_peraturan']} No. ${_peraturan!['nomor']} Th. ${_peraturan!['tahun']}'
        : (widget.initialItem?.peraturanTitle ?? 'Detail Peraturan');

    final status = (_peraturan?['status'] ?? widget.initialItem?.status ?? 'Berlaku').toString();
    final wilayah = (_peraturan?['wilayah'] ?? widget.initialItem?.wilayah ?? 'Nasional').toString();
    final judul = (_peraturan?['judul'] ?? widget.initialItem?.judul ?? '').toString();
    final sektor = (_peraturan?['sektor'] ?? widget.initialItem?.sektor ?? '-').toString();
    final docUrl = (_peraturan?['url_dokumen_asli'] ?? widget.initialItem?.urlDokumenAsli)?.toString();

    final filteredPasal = _pasalList.where((p) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      final no = (p['nomor_pasal'] ?? '').toString().toLowerCase();
      final text = (p['teks_pasal'] ?? '').toString().toLowerCase();
      return no.contains(q) || text.contains(q);
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_wasModified);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          actions: [
            if (canManage && _peraturan != null) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Peraturan',
                onPressed: _handleEditPeraturan,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Hapus Peraturan',
                onPressed: () => _handleDeletePeraturan(title),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat Ulang',
              onPressed: _fetchDetail,
            ),
          ],
        ),
        body: _errorMessage != null && !_isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchDetail, child: const Text('Coba Lagi')),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.getStatusBg(status),
                                  border: Border.all(color: AppColors.getStatusBorder(status)),
                                  borderRadius: AppRadius.tagR,
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.55,
                                    fontSize: 11,
                                    color: AppColors.getStatusText(status),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: AppRadius.tagR,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  wilayah,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sektor: $sektor',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const Divider(height: 24),

                          // Document Link
                          Row(
                            children: [
                              const Icon(Icons.link, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Tautan Dokumen Asli:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () => _openUrl(docUrl),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Buka Dokumen', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Detail & Non-clickable Pasal Highlights
                  _buildStatusDetailCard(),
                  const SizedBox(height: 16),

                  // Search within articles
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari pasal dalam peraturan ini...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _filterQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _filterQuery = val),
                  ),
                  const SizedBox(height: 16),

                  // Articles Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Pasal (${_isLoading ? '...' : filteredPasal.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Skeletonized Articles
                  Skeletonizer(
                    enabled: _isLoading,
                    child: _isLoading
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return _buildPasalCard({
                                'nomor_pasal': 'Pasal ${index + 1}',
                                'nomor_ayat': 'Ayat (1)',
                                'teks_pasal': 'Ketentuan umum mengenai peraturan ini dijelaskan dalam pasal dan ayat berikut ini dengan seksama.',
                              });
                            },
                          )
                        : filteredPasal.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Belum ada teks pasal pada peraturan ini atau tidak ada yang cocok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredPasal.length,
                                itemBuilder: (context, index) {
                                  final p = filteredPasal[index];
                                  return _buildPasalCard(p);
                                },
                              ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPasalCard(dynamic p) {
    final canManage = AuthService().currentUser?.canManagePeraturan ?? false;
    final pasalId = int.tryParse((p['id'] ?? '0').toString()) ?? 0;
    final noPasal = (p['nomor_pasal'] ?? '').toString();
    final noAyat = (p['nomor_ayat'] ?? '').toString();
    final teks = (p['teks_pasal'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      noPasal.isNotEmpty ? noPasal : 'Pasal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (noAyat.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        noAyat,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canManage && !_isLoading && pasalId > 0) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 17, color: AppColors.primary),
                        tooltip: 'Edit Pasal',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleEditPasal(Map<String, dynamic>.from(p as Map)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.danger),
                        tooltip: 'Hapus Pasal',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleDeletePasal(pasalId, noPasal.isNotEmpty ? noPasal : 'pasal ini'),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Salin Pasal',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '$noPasal $noAyat\n\n$teks'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$noPasal disalin!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
              ),
              child: Text(
                teks,
                style: const TextStyle(fontSize: 14, height: 22 / 14, color: AppColors.textBody),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
