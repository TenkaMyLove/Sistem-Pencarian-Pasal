import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/search_item.dart';
import '../models/jadwal_item.dart';
import '../models/user_account.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _cachedBaseUrl;

  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(AppConstants.prefBaseUrl) ?? AppConstants.defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefBaseUrl, cleanUrl);
    _cachedBaseUrl = cleanUrl;
  }

  // Check backend connection health
  Future<Map<String, dynamic>> checkHealth() async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      }
      return {
        'success': false,
        'message': 'HTTP Status: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // 1. Auth Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'kata_sandi': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'user': data['user']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal. Periksa username dan password.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server ($baseUrl): $e',
      };
    }
  }

  // 2. Search Peraturan & Pasal
  Future<SearchResponse> search({
    String query = '',
    String sektor = '',
    String wilayah = '',
    int page = 1,
    int pageSize = 10,
  }) async {
    final baseUrl = await getBaseUrl();
    final queryParams = {
      if (query.isNotEmpty) 'q': query,
      if (sektor.isNotEmpty) 'sektor': sektor,
      if (wilayah.isNotEmpty) 'wilayah': wilayah,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return SearchResponse.fromJson(json['data']);
        }
      }
      throw Exception('Gagal memuat data dari server (${response.statusCode})');
    } catch (e) {
      // Re-throw with user-friendly message
      throw Exception('Koneksi bermasalah: $e');
    }
  }

  // 3. Peraturan Detail
  Future<Map<String, dynamic>> getPeraturanDetail(int peraturanId) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/peraturan/$peraturanId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      }
      throw Exception('Gagal memuat detail peraturan (${response.statusCode})');
    } catch (e) {
      throw Exception('Koneksi bermasalah: $e');
    }
  }

  // 4. Jadwal Rapat Harmonisasi
  Future<List<JadwalItem>> getJadwal() async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/jadwal');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['data'] as List? ?? [])
            .map((e) => JadwalItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Gagal memuat jadwal (${response.statusCode})');
    } catch (e) {
      throw Exception('Koneksi bermasalah: $e');
    }
  }

  Future<void> addJadwal(Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/jadwal');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    final res = jsonDecode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(res['message'] ?? 'Gagal menambahkan jadwal');
    }
  }

  Future<void> updateJadwal(int id, Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/jadwal/$id');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    final res = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(res['message'] ?? 'Gagal memperbarui jadwal');
    }
  }

  Future<void> deleteJadwal(int id) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/jadwal/$id');

    final response = await http.delete(uri).timeout(const Duration(seconds: 10));
    final res = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(res['message'] ?? 'Gagal menghapus jadwal');
    }
  }

  // 5. Admin - User Accounts
  Future<List<UserAccount>> getAdminUsers() async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/admin/users');

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = (json['data'] as List? ?? [])
          .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw Exception('Gagal memuat pengguna');
  }

  Future<void> resetPassword({
    required String targetUsername,
    required String kataSandiBaru,
    required String adminUsername,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/admin/reset-password');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target_username': targetUsername,
        'kata_sandi_baru': kataSandiBaru,
        'admin_username': adminUsername,
      }),
    ).timeout(const Duration(seconds: 10));

    final res = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(res['message'] ?? 'Gagal mereset kata sandi');
    }
  }

  Future<void> _sendRequest(String method, String path, {Map<String, dynamic>? body, String fallbackError = 'Permintaan gagal'}) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    if (method == 'PUT') {
      response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body ?? {}),
      ).timeout(const Duration(seconds: 10));
    } else if (method == 'DELETE') {
      response = await http.delete(uri).timeout(const Duration(seconds: 10));
    } else {
      throw ArgumentError('Unsupported method: $method');
    }

    final res = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(res['message'] ?? fallbackError);
    }
  }

  // 3b. Manage Peraturan & Pasal (Pengelola / Admin)
  Future<void> updatePeraturan(int id, Map<String, dynamic> data) =>
      _sendRequest('PUT', '/api/peraturan/$id', body: data, fallbackError: 'Gagal memperbarui peraturan');

  Future<void> deletePeraturan(int id) =>
      _sendRequest('DELETE', '/api/peraturan/$id', fallbackError: 'Gagal menghapus peraturan');

  Future<void> updatePasal(int id, Map<String, dynamic> data) =>
      _sendRequest('PUT', '/api/pasal/$id', body: data, fallbackError: 'Gagal memperbarui pasal');

  Future<void> deletePasal(int id) =>
      _sendRequest('DELETE', '/api/pasal/$id', fallbackError: 'Gagal menghapus pasal');

  // 6. Scraper Tambah Peraturan
  Future<Map<String, dynamic>> tambahPeraturan(Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/tambah-peraturan');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));

    final res = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(res['message'] ?? 'Gagal memproses peraturan');
    }
    return res['data'] ?? {};
  }
}
