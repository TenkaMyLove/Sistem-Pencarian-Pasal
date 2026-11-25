/**
 * P3H Kalsel — Notifikasi Jadwal Rapat Harmonisasi (web / PWA).
 *
 * Setiap 60 detik mengambil /jadwal/notifikasi-hari-ini (rapat hari ini yang jamnya belum lewat,
 * dihitung server dalam WITA), lalu:
 *  - menampilkan banner di halaman (tanpa izin browser), dan
 *  - mengirim notifikasi browser sekali per rapat (bila izin diberikan).
 * Rapat yang jamnya sudah lewat hilang dari banner dan notifikasinya ditutup otomatis.
 * Notifikasi baru aktif mulai pukul 08:00 WITA (jam server, bukan jam perangkat).
 */
(function () {
  'use strict';

  var ENDPOINT = '/jadwal/notifikasi-hari-ini';
  var POLL_INTERVAL_MS = 60 * 1000;
  var WORK_START = '08:00:00';
  var DISMISS_MS = 5 * 60 * 1000;
  var DISMISS_KEY = 'jadwal_notif_dismissed';
  var TAG_PREFIX = 'jadwal-';

  var banner, list, permBtn;

  function formatJam(jam) {
    var m = String(jam || '').match(/(\d{1,2})[:.](\d{2})/);
    return m ? (m[1].length === 1 ? '0' + m[1] : m[1]) + ':' + m[2] : String(jam || '');
  }

  function deskripsi(item) {
    return formatJam(item.jam) + ' WITA — ' + (item.jenis_rancangan || '') + ': ' + (item.tentang || '');
  }

  // ── Banner di halaman ──

  function isDismissed() {
    var t = parseInt(sessionStorage.getItem(DISMISS_KEY) || '0', 10);
    return t && Date.now() - t < DISMISS_MS;
  }

  function renderBanner(items) {
    if (!banner || !list) return;

    if (items.length === 0 || isDismissed()) {
      banner.classList.add('hidden');
      return;
    }

    list.textContent = '';
    items.forEach(function (item) {
      var row = document.createElement('div');
      row.className = 'jadwal-notif-item';

      var time = document.createElement('span');
      time.className = 'jadwal-notif-time';
      time.textContent = formatJam(item.jam) + ' WITA';

      var desc = document.createElement('span');
      desc.className = 'jadwal-notif-desc';
      desc.textContent = (item.jenis_rancangan || '') + ' — ' + (item.tentang || '');

      row.appendChild(time);
      row.appendChild(desc);
      list.appendChild(row);
    });

    updatePermissionButton();
    banner.classList.remove('hidden');
  }

  window.dismissJadwalBanner = function () {
    if (banner) banner.classList.add('hidden');
    sessionStorage.setItem(DISMISS_KEY, Date.now().toString());
  };

  // ── Notifikasi browser ──

  function notificationsSupported() {
    return 'Notification' in window;
  }

  function updatePermissionButton() {
    if (!permBtn) return;
    var show = notificationsSupported() && Notification.permission === 'default';
    permBtn.classList.toggle('hidden', !show);
  }

  window.enableJadwalNotifications = function () {
    if (!notificationsSupported()) return;
    // Harus dipicu klik pengguna (syarat Safari/Chrome)
    Promise.resolve(Notification.requestPermission()).then(function () {
      updatePermissionButton();
      check();
    });
  };

  function swRegistration() {
    if (!('serviceWorker' in navigator)) return Promise.resolve(null);
    return navigator.serviceWorker.getRegistration().then(function (reg) {
      return reg && reg.active ? reg : null;
    }).catch(function () { return null; });
  }

  // Simpan id rapat yang sudah diberi notifikasi (per tanggal) agar tidak berulang tiap pindah halaman.
  function notifiedKey(tanggal) {
    return 'jadwal_notified_' + tanggal;
  }

  function getNotified(tanggal) {
    try {
      return JSON.parse(localStorage.getItem(notifiedKey(tanggal)) || '[]');
    } catch (_) {
      return [];
    }
  }

  function setNotified(tanggal, ids) {
    try {
      // Bersihkan catatan hari-hari sebelumnya
      for (var i = localStorage.length - 1; i >= 0; i--) {
        var k = localStorage.key(i);
        if (k && k.indexOf('jadwal_notified_') === 0 && k !== notifiedKey(tanggal)) localStorage.removeItem(k);
      }
      localStorage.setItem(notifiedKey(tanggal), JSON.stringify(ids));
    } catch (_) {}
  }

  function syncBrowserNotifications(items, tanggal) {
    var activeTags = items.map(function (it) { return TAG_PREFIX + it.id; });

    return swRegistration().then(function (reg) {
      // Tutup otomatis notifikasi rapat yang jamnya sudah lewat
      if (reg && reg.getNotifications) {
        reg.getNotifications().then(function (notifs) {
          notifs.forEach(function (n) {
            if (n.tag && n.tag.indexOf(TAG_PREFIX) === 0 && activeTags.indexOf(n.tag) === -1) n.close();
          });
        }).catch(function () {});
      }

      if (!notificationsSupported() || Notification.permission !== 'granted') return;

      var notified = getNotified(tanggal);
      var baru = items.filter(function (it) { return notified.indexOf(it.id) === -1; });
      if (baru.length === 0) return;

      baru.forEach(function (item) {
        var title = 'Rapat Harmonisasi Hari Ini';
        var options = {
          body: deskripsi(item),
          icon: '/images/icon-192.png',
          badge: '/images/icon-192.png',
          tag: TAG_PREFIX + item.id,
          data: { url: '/jadwal' },
        };
        try {
          // Chrome Android hanya mendukung notifikasi lewat service worker
          if (reg) reg.showNotification(title, options);
          else new Notification(title, options);
          notified.push(item.id);
        } catch (_) {}
      });
      setNotified(tanggal, notified);
    });
  }

  // ── Polling ──

  function check() {
    return fetch(ENDPOINT, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
      cache: 'no-store',
    })
      .then(function (resp) { return resp.ok ? resp.json() : null; })
      .then(function (json) {
        if (!json || !json.success) return;
        // Sebelum jam kerja (08:00 WITA) belum ada notifikasi
        var items = (json.jam_server || '') >= WORK_START ? (json.data || []) : [];
        renderBanner(items);
        return syncBrowserNotifications(items, json.tanggal || '');
      })
      .catch(function () { /* jaringan/sesi bermasalah — coba lagi di polling berikutnya */ });
  }

  document.addEventListener('DOMContentLoaded', function () {
    banner = document.getElementById('jadwal-notif-banner');
    list = document.getElementById('jadwal-notif-list');
    permBtn = document.getElementById('jadwal-notif-enable');
    if (!banner) return; // banner hanya dirender untuk pegawai (bukan Tamu)

    check();
    setInterval(check, POLL_INTERVAL_MS);
    // Segera perbarui ketika tab/PWA kembali aktif
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') check();
    });
  });
})();
