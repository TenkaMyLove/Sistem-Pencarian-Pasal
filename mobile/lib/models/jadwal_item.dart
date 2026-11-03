class JadwalItem {
  final int id;
  final String jenisRancangan; // 'Ranperda' or 'Ranperkada'
  final String tentang;
  final String tanggal; // YYYY-MM-DD
  final String jam; // e.g. '09:00 WITA'
  final String namaKompilator;
  final String timPokja;
  final String dibuatOleh;

  JadwalItem({
    required this.id,
    required this.jenisRancangan,
    required this.tentang,
    required this.tanggal,
    required this.jam,
    required this.namaKompilator,
    required this.timPokja,
    required this.dibuatOleh,
  });

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    return JadwalItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jenisRancangan: json['jenis_rancangan']?.toString() ?? 'Ranperda',
      tentang: json['tentang']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      namaKompilator: json['nama_kompilator']?.toString() ?? '',
      timPokja: json['tim_pokja']?.toString() ?? '',
      dibuatOleh: json['dibuat_oleh']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jenis_rancangan': jenisRancangan,
      'tentang': tentang,
      'tanggal': tanggal,
      'jam': jam,
      'nama_kompilator': namaKompilator,
      'tim_pokja': timPokja,
      'dibuat_oleh': dibuatOleh,
    };
  }

  // Dummy mock for Skeletonizer preview
  static JadwalItem dummy() {
    return JadwalItem(
      id: 1,
      jenisRancangan: 'Ranperda',
      tentang: 'Penyelenggaraan Ketenteraman dan Ketertiban Umum di Provinsi Kalimantan Selatan',
      tanggal: '2026-11-15',
      jam: '09:30 WITA',
      namaKompilator: 'Ahmad Faisal, S.H. / Siti Rahmah, M.H.',
      timPokja: 'Pokja II',
      dibuatOleh: 'Pengelola',
    );
  }
}
