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
  bool get canManagePeraturan => isPengelola || isAdmin;
  bool get canTambahPeraturan => isPengelola || isAdmin;

  static const Map<String, Map<String, String>> _roleProfile = {
    'Admin': {'name': 'Administrator', 'subtitle': 'Manajemen Sistem'},
    'Pengelola': {'name': 'Pengelola', 'subtitle': 'Data & Jadwal'},
    'Perancang': {'name': 'Perancang', 'subtitle': 'Tim Harmonisasi'},
    'Tamu': {'name': 'Tamu', 'subtitle': 'Akses Publik'},
  };

  bool get _isDefaultRoleUsername =>
      isTamu || username.trim().toLowerCase() == peran.trim().toLowerCase();

  String get displayName {
    final mapped = _roleProfile[peran];
    if (_isDefaultRoleUsername && mapped != null) {
      return mapped['name']!;
    }
    return username.isNotEmpty ? username : (mapped?['name'] ?? 'Tamu');
  }

  String get roleSubtitle {
    final mapped = _roleProfile[peran];
    if (_isDefaultRoleUsername && mapped != null) {
      return mapped['subtitle']!;
    }
    return mapped?['name'] ?? peran;
  }

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
    return User(id: 0, username: 'Tamu', peran: 'Tamu');
  }
}
