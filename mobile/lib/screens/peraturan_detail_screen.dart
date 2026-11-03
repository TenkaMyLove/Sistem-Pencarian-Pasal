import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/search_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

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
  String? _errorMessage;
  Map<String, dynamic>? _peraturan;
  List<dynamic> _pasalList = [];
  String _filterQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final title = widget.initialItem != null
        ? widget.initialItem!.peraturanTitle
        : (_peraturan != null
            ? '${_peraturan!['jenis_peraturan']} No. ${_peraturan!['nomor']} Th. ${_peraturan!['tahun']}'
            : 'Detail Peraturan');

    final status = widget.initialItem?.status ?? (_peraturan?['status'] ?? 'Berlaku');

    final filteredPasal = _pasalList.where((p) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      final no = (p['nomor_pasal'] ?? '').toString().toLowerCase();
      final text = (p['teks_pasal'] ?? '').toString().toLowerCase();
      return no.contains(q) || text.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.getStatusBg(status),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.getStatusText(status),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  widget.initialItem?.wilayah ?? (_peraturan?['wilayah'] ?? 'Nasional'),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.initialItem?.judul ?? (_peraturan?['judul'] ?? ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sektor: ${widget.initialItem?.sektor ?? (_peraturan?['sektor'] ?? '-')}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const Divider(height: 24),

                          // Document Link
                          Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              const Text('Tautan Dokumen Asli:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  final url = widget.initialItem?.urlDokumenAsli ?? _peraturan?['url_dokumen_asli'];
                                  _openUrl(url);
                                },
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
                                  'Tidak ada pasal yang cocok dengan pencarian.',
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
    );
  }

  Widget _buildPasalCard(dynamic p) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBlueBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        noPasal.isNotEmpty ? noPasal : 'Pasal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.badgeBlueText,
                        ),
                      ),
                    ),
                    if (noAyat.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        noAyat,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Salin Pasal',
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
            const SizedBox(height: 6),
            Text(
              teks,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
