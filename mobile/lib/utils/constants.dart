import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'P3H Kemenkum Kalsel';
  static const String appSubTitle = 'Portal Pencarian Pasal & Harmonisasi Regulasi Daerah';
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
  static const String prefRememberMe = 'remember_me';
  static const String prefSavedUsername = 'saved_username';
  static const String prefSearchHistory = 'search_history';
}

class AppColors {
  // Brand (Sovereign Navy + Administrative Blue + Slate)
  static const Color primary = Color(0xFF0B192C);
  static const Color primaryDark = Color(0xFF081220);
  static const Color primarySlate = Color(0xFF1E293B);
  static const Color primaryLight = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFDE68A);

  // Soft Indigo / Info / Action Button Tints
  static const Color infoBg = Color(0xFFEEF2FF);
  static const Color infoBorder = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1E3A8A);
  static const Color editBg = Color(0xFFEEF2FF);
  static const Color deleteBg = Color(0xFFFEE2E2);
  static const Color deleteIcon = Color(0xFFDC2626);

  // Background, Inputs & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color inputFill = Color(0xFFF1F5F9);
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

  // Status: Diubah
  static const Color statusDiubahBg = Color(0xFFFFF7ED);
  static const Color statusDiubahText = Color(0xFFC2410C);
  static const Color statusDiubahBorder = Color(0xFFFED7AA);

  // Status: Dicabut
  static const Color statusDicabutBg = Color(0xFFFEF2F2);
  static const Color statusDicabutText = Color(0xFF991B1B);
  static const Color statusDicabutBorder = Color(0xFFFECACA);

  // Netral (jenis norma, metadata)
  static const Color badgeBlueBg = Color(0xFFF1F5F9);
  static const Color badgeBlueText = Color(0xFF334155);
  static const Color badgeBlueBorder = Color(0xFFE2E8F0);

  // Destruktif
  static const Color danger = Color(0xFFDC2626);
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

class AppRadius {
  static const double tag = 6;
  static const double control = 10;
  static const double container = 14;
  static const double pill = 20;

  static BorderRadius get tagR => BorderRadius.circular(tag);
  static BorderRadius get controlR => BorderRadius.circular(control);
  static BorderRadius get containerR => BorderRadius.circular(container);
  static BorderRadius get pillR => BorderRadius.circular(pill);
}
