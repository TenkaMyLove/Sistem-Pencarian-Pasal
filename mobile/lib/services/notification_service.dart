import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/jadwal_item.dart';
import 'api_service.dart';

/// Notifikasi lokal untuk jadwal rapat harmonisasi hari ini.
///
/// Selama aplikasi berjalan, setiap 60 detik mengambil /api/jadwal/hari-ini
/// (rapat hari ini yang jamnya belum lewat, dihitung server dalam WITA):
///  - rapat baru  -> tampilkan notifikasi (sekali per rapat),
///  - rapat yang sudah lewat -> notifikasinya dihapus otomatis.
/// Notifikasi baru aktif mulai pukul 08:00 WITA.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Timer? _pollTimer;
  bool _initialized = false;

  /// Id rapat yang notifikasinya sudah ditampilkan (agar tidak berbunyi ulang tiap polling).
  final Set<int> _shownIds = {};
  String _shownForDate = '';

  static const String _channelId = 'jadwal_rapat';
  static const String _channelName = 'Jadwal Rapat Harmonisasi';
  static const String _channelDesc = 'Notifikasi jadwal rapat harmonisasi hari ini';
  static const String _title = 'Rapat Harmonisasi Hari Ini';
  static const int _workStartHour = 8; // 08:00 WITA

  /// Panggil sekali dari main().
  Future<void> init() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init: $e');
    }
  }

  /// Mulai polling (hanya untuk pegawai yang login, bukan Tamu).
  Future<void> startPolling() async {
    if (!_initialized) return;
    await _requestPermission();
    _pollTimer?.cancel();
    unawaited(_checkAndNotify());
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkAndNotify());
  }

  /// Hentikan polling dan hapus semua notifikasi (dipanggil saat logout).
  Future<void> stopPolling() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _shownIds.clear();
    if (_initialized) await _plugin.cancelAll();
  }

  Future<void> _requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('NotificationService.permission: $e');
    }
  }

  /// Waktu sekarang dalam WITA (UTC+8), terlepas dari zona waktu perangkat.
  DateTime _nowWita() => DateTime.now().toUtc().add(const Duration(hours: 8));

  Future<void> _checkAndNotify() async {
    try {
      final now = _nowWita();
      final today = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (today != _shownForDate) {
        _shownIds.clear();
        _shownForDate = today;
      }

      final items = now.hour < _workStartHour
          ? <JadwalItem>[]
          : await ApiService().getJadwalHariIni();
      final activeIds = items.map((e) => e.id).toSet();

      // Hapus notifikasi rapat yang jamnya sudah lewat
      final active = await _plugin.getActiveNotifications();
      for (final n in active) {
        if (n.id != null && n.channelId == _channelId && !activeIds.contains(n.id)) {
          await _plugin.cancel(n.id!);
        }
      }
      for (final id in _shownIds.difference(activeIds).toList()) {
        await _plugin.cancel(id);
        _shownIds.remove(id);
      }

      // Tampilkan notifikasi untuk rapat yang belum pernah ditampilkan
      for (final item in items) {
        if (_shownIds.add(item.id)) {
          await _showNotification(item);
        }
      }
    } catch (e) {
      debugPrint('NotificationService: $e');
    }
  }

  static String _formatJam(String jam) {
    final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(jam);
    return m == null ? jam : '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
  }

  Future<void> _showNotification(JadwalItem item) async {
    final body = '${_formatJam(item.jam)} WITA — ${item.jenisRancangan}: ${item.tentang}';
    final detail = [
      if (item.timPokja.isNotEmpty) 'Tim: ${item.timPokja}',
      if (item.namaKompilator.isNotEmpty) 'Kompilator: ${item.namaKompilator}',
    ].join(' • ');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        onlyAlertOnce: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          detail.isEmpty ? body : '$body\n$detail',
          contentTitle: _title,
          summaryText: 'P3H Kemenkum Kalsel',
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(item.id, _title, body, details);
  }
}
