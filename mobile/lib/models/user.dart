class User {
  final int id;
  final String username;
  final String peran; // 'Admin', 'Pengelola', 'Perancang', 'Tamu'

  User({
    required this.id,
    required this.username,
    required this.peran,
  });

  bool get isAdmin => peran == 'Admin';
  bool get isPengelola => peran == 'Pengelola';
  bool get isPerancang => peran == 'Perancang';
  bool get isTamu => peran == 'Tamu';
  bool get canManageJadwal => isPengelola || isPerancang;
  bool get canTambahPeraturan => isPengelola;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username'] ?? '',
      peran: json['peran'] ?? 'Tamu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'peran': peran,
    };
  }

  static User guest() {
    return User(id: 0, username: 'Tamu / Publik', peran: 'Tamu');
  }
}
