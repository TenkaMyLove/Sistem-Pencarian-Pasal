import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'P3H Kemenkumham Kalsel';
  static const String appSubTitle = 'Sistem Pencarian Pasal Harmonisasi Ranperda';
  static const String defaultPort = '3000';

  // Smart default base URL
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    } else {
      // Android Emulator loopback
      return 'http://10.0.2.2:$defaultPort';
    }
  }

  // SharedPreferences Keys
  static const String prefBaseUrl = 'api_base_url';
  static const String prefUserData = 'user_data';
  static const String prefIsLoggedIn = 'is_logged_in';
}

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFFD97706); // Gold / Amber
  static const Color accentLight = Color(0xFFFBBF24);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Badges
  static const Color statusBerlakuBg = Color(0xFFDEF7EC);
  static const Color statusBerlakuText = Color(0xFF03543F);

  static const Color statusDiubahBg = Color(0xFFFEF08A);
  static const Color statusDiubahText = Color(0xFF854D0E);

  static const Color statusDicabutBg = Color(0xFFFDE8E8);
  static const Color statusDicabutText = Color(0xFF9B1C1C);

  static const Color badgeBlueBg = Color(0xFFE0E7FF);
  static const Color badgeBlueText = Color(0xFF3730A3);

  // Helpers
  static Color getStatusBg(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('berlaku') && !s.contains('tidak')) {
      return statusBerlakuBg;
    } else if (s.contains('ubah') || s.contains('sebagian')) {
      return statusDiubahBg;
    } else if (s.contains('cabut')) {
      return statusDicabutBg;
    }
    return badgeBlueBg;
  }

  static Color getStatusText(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('berlaku') && !s.contains('tidak')) {
      return statusBerlakuText;
    } else if (s.contains('ubah') || s.contains('sebagian')) {
      return statusDiubahText;
    } else if (s.contains('cabut')) {
      return statusDicabutText;
    }
    return badgeBlueText;
  }
}
