import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _initialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && !_currentUser!.isTamu;
  bool get isGuest => _currentUser != null && _currentUser!.isTamu;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.prefUserData);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (_) {
        _currentUser = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await ApiService().login(username, password);
    if (result['success'] == true && result['user'] != null) {
      _currentUser = User.fromJson(result['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserData, jsonEncode(_currentUser!.toJson()));
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      notifyListeners();
      return {'success': true};
    }
    return {'success': false, 'message': result['message'] ?? 'Login gagal'};
  }

  Future<void> loginAsGuest() async {
    _currentUser = User.guest();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserData, jsonEncode(_currentUser!.toJson()));
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserData);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    notifyListeners();
  }
}
