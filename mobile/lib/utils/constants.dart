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
  // Brand (DESIGN.md: Institutional High-Precision Flat)
  static const Color primary = Color(0xFF0B192C); // Deep Sovereign Navy
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF1E3A8A); // Administrative Slate Blue (hover/aktif)
  static const Color accent = Color(0xFFD97706); // Solid Legal Gold
  static const Color accentLight = Color(0xFFFDE68A);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status: Berlaku
  static const Color statusBerlakuBg = Color(0xFFF0FDF4);
  static const Color statusBerlakuText = Color(0xFF166534);
  static const Color statusBerlakuBorder = Color(0xFFBBF7D0);

  // Status: Diubah / terkait P3H
  static const Color statusDiubahBg = Color(0xFFFFFBEB);
  static const Color statusDiubahText = Color(0xFFB45309);
  static const Color statusDiubahBorder = Color(0xFFFDE68A);

  // Status: Dicabut
  static const Color statusDicabutBg = Color(0xFFFEF2F2);
  static const Color statusDicabutText = Color(0xFF991B1B);
  static const Color statusDicabutBorder = Color(0xFFFECACA);

  // Netral (jenis norma, metadata)
  static const Color badgeBlueBg = Color(0xFFF1F5F9);
  static const Color badgeBlueText = Color(0xFF0F172A);
  static const Color badgeBlueBorder = Color(0xFFCBD5E1);

  // Destruktif
  static const Color danger = Color(0xFF991B1B);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // Sorotan kata kunci / referensi pasal
  static const Color markBg = Color(0xFFFDE68A);
  static const Color markText = Color(0xFF78350F);
  static const Color refBg = Color(0xFFFEF08A);
  static const Color refText = Color(0xFF854D0E);

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

  static Color getStatusBorder(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('berlaku') && !s.contains('tidak')) {
      return statusBerlakuBorder;
    } else if (s.contains('ubah') || s.contains('sebagian')) {
      return statusDiubahBorder;
    } else if (s.contains('cabut')) {
      return statusDicabutBorder;
    }
    return badgeBlueBorder;
  }
}

/// Radius sesuai DESIGN.md: kontrol 4px, kontainer 8px, penanda 2px. Tanpa bentuk pil.
class AppRadius {
  static const double tag = 2;
  static const double control = 4;
  static const double container = 8;

  static BorderRadius get tagR => BorderRadius.circular(tag);
  static BorderRadius get controlR => BorderRadius.circular(control);
  static BorderRadius get containerR => BorderRadius.circular(container);
}