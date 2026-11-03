import 'dart:convert';

class SearchItem {
  final int pasalId;
  final String nomorPasal;
  final String nomorAyat;
  final String teksPasal;
  final int peraturanId;
  final String jenisPeraturan;
  final String nomor;
  final int tahun;
  final String judul;
  final String status;
  final String? statusDetail;
  final dynamic statusDetailJson;
  final String wilayah;
  final String sektor;
  final String? urlDokumenAsli;
  final String statusTautan;

  SearchItem({
    required this.pasalId,
    required this.nomorPasal,
    required this.nomorAyat,
    required this.teksPasal,
    required this.peraturanId,
    required this.jenisPeraturan,
    required this.nomor,
    required this.tahun,
    required this.judul,
    required this.status,
    this.statusDetail,
    this.statusDetailJson,
    required this.wilayah,
    required this.sektor,
    this.urlDokumenAsli,
    required this.statusTautan,
  });

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    dynamic rawJson = json['status_detail_json'];
    if (rawJson is String && rawJson.isNotEmpty) {
      try {
        rawJson = jsonDecode(rawJson);
      } catch (_) {}
    }

    return SearchItem(
      pasalId: json['pasal_id'] is int
          ? json['pasal_id']
          : int.tryParse(json['pasal_id']?.toString() ?? '0') ?? 0,
      nomorPasal: json['nomor_pasal']?.toString() ?? '',
      nomorAyat: json['nomor_ayat']?.toString() ?? '',
      teksPasal: json['teks_pasal']?.toString() ?? '',
      peraturanId: json['peraturan_id'] is int
          ? json['peraturan_id']
          : int.tryParse(json['peraturan_id']?.toString() ?? '0') ?? 0,
      jenisPeraturan: json['jenis_peraturan']?.toString() ?? '',
      nomor: json['nomor']?.toString() ?? '',
      tahun: json['tahun'] is int
          ? json['tahun']
          : int.tryParse(json['tahun']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Berlaku',
      statusDetail: json['status_detail']?.toString(),
      statusDetailJson: rawJson,
      wilayah: json['wilayah']?.toString() ?? 'Nasional',
      sektor: json['sektor']?.toString() ?? 'Lainnya',
      urlDokumenAsli: json['url_dokumen_asli']?.toString(),
      statusTautan: json['status_tautan']?.toString() ?? 'normal',
    );
  }

  String get peraturanTitle => '$jenisPeraturan No. $nomor Tahun $tahun';

  // Dummy mock for Skeletonizer preview
  static SearchItem dummy() {
    return SearchItem(
      pasalId: 1,
      nomorPasal: 'Pasal 18',
      nomorAyat: 'Ayat (1)',
      teksPasal: 'Pemerintah Daerah berwenang mengatur dan mengurus sendiri Urusan Pemerintahan menurut Asas Otonomi dan Tugas Pembantuan dengan prinsip demokrasi.',
      peraturanId: 1,
      jenisPeraturan: 'Undang-Undang',
      nomor: '23',
      tahun: 2014,
      judul: 'Pemerintahan Daerah',
      status: 'Berlaku',
      wilayah: 'Nasional',
      sektor: 'Otonomi & Pemerintahan Daerah',
      urlDokumenAsli: 'https://peraturan.bpk.go.id',
      statusTautan: 'normal',
    );
  }
}

class SearchResponse {
  final List<SearchItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final List<String> sektorList;
  final List<String> wilayahList;

  SearchResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.sektorList,
    required this.wilayahList,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final items = rawItems.map((e) => SearchItem.fromJson(e as Map<String, dynamic>)).toList();
    final filters = json['filters'] as Map<String, dynamic>? ?? {};

    return SearchResponse(
      items: items,
      totalCount: json['totalCount'] is int
          ? json['totalCount']
          : int.tryParse(json['totalCount']?.toString() ?? '0') ?? 0,
      currentPage: json['currentPage'] is int
          ? json['currentPage']
          : int.tryParse(json['currentPage']?.toString() ?? '1') ?? 1,
      pageSize: json['pageSize'] is int
          ? json['pageSize']
          : int.tryParse(json['pageSize']?.toString() ?? '10') ?? 10,
      totalPages: json['totalPages'] is int
          ? json['totalPages']
          : int.tryParse(json['totalPages']?.toString() ?? '1') ?? 1,
      sektorList: (filters['sektorList'] as List? ?? []).map((e) => e.toString()).toList(),
      wilayahList: (filters['wilayahList'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
