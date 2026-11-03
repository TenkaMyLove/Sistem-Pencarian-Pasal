class UserAccount {
  final int id;
  final String username;
  final String peran;
  final String? diubahTerakhirOleh;
  final String? tanggalKataSandiDiubah;

  UserAccount({
    required this.id,
    required this.username,
    required this.peran,
    this.diubahTerakhirOleh,
    this.tanggalKataSandiDiubah,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      peran: json['peran']?.toString() ?? '',
      diubahTerakhirOleh: json['diubah_terakhir_oleh']?.toString(),
      tanggalKataSandiDiubah: json['tanggal_kata_sandi_diubah']?.toString(),
    );
  }

  static UserAccount dummy() {
    return UserAccount(
      id: 1,
      username: 'Pengelola',
      peran: 'Pengelola',
      diubahTerakhirOleh: 'Admin',
      tanggalKataSandiDiubah: '2026-10-25 10:00:00',
    );
  }
}
