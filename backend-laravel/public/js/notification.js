/**
 * P3H Kalsel — Notifikasi Jadwal Rapat Harmonisasi (web / PWA).
 *
 * 1. Web Push (utama): perangkat yang mengaktifkan notifikasi (tombol lonceng di header)
 *    didaftarkan ke server. Server mengirim notifikasi mulai 08:00 WITA walau browser/PWA
 *    sedang tertutup (lihat app/Services/JadwalPushService.php & public/sw.js).
 * 2. Banner di halaman: setiap 60 detik mengambil /jadwal/notifikasi-hari-ini (semua rapat hari ini).
 * 3. Cadangan: bila Web Push tidak tersedia, notifikasi browser ditampilkan selama halaman terbuka.
 *
 * Ketika tanggal berganti, rapat kemarin hilang dari banner dan notifikasinya ditutup otomatis.
 * Notifikasi aktif mulai pukul 08:00 WITA (jam server, bukan jam perangkat).
 */
(function () {
  'use strict';

  var ENDPOINT = '/jadwal/notifikasi-hari-ini';
  var POLL_INTERVAL_MS = 60 * 1000;
  var WORK_START = '08:00:00';
  var DISMISS_MS = 5 * 60 * 1000;
  var DISMISS_KEY = 'jadwal_notif_dismissed';
  var TAG_PREFIX = 'jadwal-';

  var banner, list, permBtn, toggleBtn;
  var vapidKey = '';
  var pushActive = false; // true bila perangkat ini terdaftar Web Push di server
  var pushFailed = false; // pendaftaran Web Push gagal -> pakai notifikasi lokal sebagai cadangan
  var subscribing = null; // pendaftaran yang sedang berjalan (cegah subscribe ganda)
  var state = 'hidden';   // status tombol lonceng: aktif | mati | diblokir | ios-pasang | hidden

  // ── Util ──

  function formatJam(jam) {
    var m = String(jam || '').match(/(\d{1,2})[:.](\d{2})/);
    return m ? (m[1].length === 1 ? '0' + m[1] : m[1]) + ':' + m[2] : String(jam || '');
  }

  function deskripsi(item) {
    return formatJam(item.jam) + ' WITA — ' + (item.jenis_rancangan || '') + ': ' + (item.tentang || '');
  }

  function csrfToken() {
    var el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.content : '';
  }

  function postJson(url, data) {
    return fetch(url, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'X-CSRF-TOKEN': csrfToken() },
      body: JSON.stringify(data),
    }).then(function (resp) {
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      return resp.json();
    }).then(function (json) {
      if (!json || !json.success) throw new Error('Gagal');
      return json;
    });
  }

  function withTimeout(promise, ms) {
    return Promise.race([promise, new Promise(function (_, reject) {
      setTimeout(function () { reject(new Error('timeout')); }, ms);
    })]);
  }

  function notificationsSupported() {
    return 'Notification' in window;
  }

  function pushSupported() {
    return !!vapidKey && notificationsSupported() && 'serviceWorker' in navigator && 'PushManager' in window;
  }

  function isIos() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  }

  function isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
  }

  function urlBase64ToUint8Array(base64) {
    var padding = '='.repeat((4 - (base64.length % 4)) % 4);
    var raw = atob((base64 + padding).replace(/-/g, '+').replace(/_/g, '/'));
    var out = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }

  function swReady() {
    if (!('serviceWorker' in navigator)) return Promise.reject(new Error('no sw'));
    return withTimeout(navigator.serviceWorker.ready, 5000);
  }

  function swRegistration() {
    if (!('serviceWorker' in navigator)) return Promise.resolve(null);
    return navigator.serviceWorker.getRegistration().then(function (reg) {
      return reg && reg.active ? reg : null;
    }).catch(function () { return null; });
  }

  // ── Web Push ──

  function saveSubscription(sub) {
    var json = sub.toJSON();
    var encodings = (window.PushManager && PushManager.supportedContentEncodings) || ['aesgcm'];
    json.contentEncoding = encodings.indexOf('aes128gcm') !== -1 ? 'aes128gcm' : 'aesgcm';
    return postJson('/notifikasi/langganan', json);
  }

  /**
   * Daftarkan perangkat ini (pakai langganan lama bila ada) lalu simpan ke server.
   * Pendaftaran pertama ke layanan push bisa memakan beberapa detik; panggilan bersamaan
   * memakai proses yang sama agar tidak tercipta dua langganan.
   */
  function subscribePush() {
    if (subscribing) return subscribing;
    subscribing = swReady().then(function (reg) {
      return reg.pushManager.getSubscription().then(function (sub) {
        return sub || reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(vapidKey),
        });
      });
    }).then(function (sub) {
      return saveSubscription(sub).then(function () {
        pushActive = true;
        pushFailed = false;
        return sub;
      });
    }).catch(function (err) {
      if (window.console) console.warn('Web Push gagal didaftarkan:', err);
      pushActive = false;
      pushFailed = true;
      throw err;
    }).finally(function () {
      subscribing = null;
      updateUi();
    });
    return subscribing;
  }

  /** Hapus langganan perangkat ini (server + browser). */
  function unsubscribePush() {
    return Promise.resolve(subscribing).catch(function () {}).then(swRegistration).then(function (reg) {
      if (!reg || !reg.pushManager) return null;
      return reg.pushManager.getSubscription();
    }).then(function (sub) {
      pushActive = false;
      if (!sub) return;
      return postJson('/notifikasi/berhenti', { endpoint: sub.endpoint })
        .catch(function () {})
        .then(function () { return sub.unsubscribe(); });
    });
  }

  /** Saat halaman dibuka: bila izin sudah diberikan, pastikan langganan tersimpan untuk akun yang login. */
  function syncPush() {
    if (!pushSupported() || Notification.permission !== 'granted') return Promise.resolve();
    return subscribePush().catch(function () {});
  }

  // ── Tombol lonceng (header) ──

  function computeState() {
    if (isIos() && !isStandalone()) return 'ios-pasang'; // iOS: notifikasi hanya untuk PWA di Layar Utama
    if (!notificationsSupported()) return 'hidden';
    if (Notification.permission === 'denied') return 'diblokir';
    if (Notification.permission === 'granted' && (pushActive || !pushSupported())) return 'aktif';
    return 'mati';
  }

  var TITLES = {
    'aktif': 'Notifikasi jadwal rapat aktif di perangkat ini',
    'mati': 'Aktifkan notifikasi jadwal rapat',
    'diblokir': 'Notifikasi diblokir di pengaturan browser',
    'ios-pasang': 'Pasang aplikasi ke Layar Utama untuk menerima notifikasi',
  };

  function updateUi() {
    state = computeState();
    if (toggleBtn) {
      toggleBtn.classList.toggle('hidden', state === 'hidden');
      toggleBtn.setAttribute('data-state', state);
      toggleBtn.title = TITLES[state] || '';
      toggleBtn.setAttribute('aria-label', TITLES[state] || 'Notifikasi jadwal rapat');
    }
    if (permBtn) permBtn.classList.toggle('hidden', state !== 'mati');
  }

  function enable() {
    if (!notificationsSupported()) return Promise.resolve();
    // Harus dipicu klik pengguna (syarat Safari/Chrome)
    return Promise.resolve(Notification.requestPermission()).then(function (perm) {
      if (perm !== 'granted') return;
      if (!pushSupported()) return;
      return subscribePush().then(function () {
        return swRegistration().then(function (reg) {
          if (reg) {
            reg.showNotification('Notifikasi jadwal rapat aktif', {
              body: 'Anda akan diberi tahu jadwal rapat harmonisasi setiap hari mulai pukul 08:00 WITA.',
              icon: '/images/icon-192.png',
              tag: 'notif-aktif',
            });
          }
        });
      }).catch(function () {
        alert('Notifikasi belum dapat diaktifkan. Periksa koneksi internet lalu coba lagi.');
      });
    }).then(function () {
      updateUi();
      check();
    });
  }

  window.enableJadwalNotifications = enable;

  window.toggleJadwalNotifications = function () {
    if (state === 'ios-pasang') {
      alert('Di iPhone/iPad, notifikasi hanya tersedia setelah aplikasi P3H Kalsel ditambahkan ke Layar Utama ' +
        '(iOS 16.4 atau lebih baru). Setelah terpasang, buka aplikasinya lalu ketuk ikon lonceng.');
      if (typeof window.openPwaModal === 'function') window.openPwaModal();
      return;
    }
    if (state === 'diblokir') {
      alert('Notifikasi diblokir untuk situs ini. Izinkan melalui pengaturan situs di browser ' +
        '(ikon gembok di samping alamat situs → Notifikasi → Izinkan), lalu muat ulang halaman.');
      return;
    }
    if (state === 'aktif') {
      if (!pushSupported()) {
        alert('Notifikasi aktif selama halaman ini terbuka. Browser ini tidak mendukung notifikasi saat aplikasi tertutup.');
        return;
      }
      if (confirm('Matikan notifikasi jadwal rapat di perangkat ini?')) {
        unsubscribePush().catch(function () {}).then(updateUi);
      }
      return;
    }
    enable();
  };

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

    updateUi();
    banner.classList.remove('hidden');
  }

  window.dismissJadwalBanner = function () {
    if (banner) banner.classList.add('hidden');
    sessionStorage.setItem(DISMISS_KEY, Date.now().toString());
  };

  // ── Notifikasi browser (cadangan tanpa Web Push) ──

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
      // Tutup otomatis notifikasi rapat yang bukan jadwal hari ini (tanggal sudah berganti)
      if (reg && reg.getNotifications) {
        reg.getNotifications().then(function (notifs) {
          notifs.forEach(function (n) {
            if (n.tag && n.tag.indexOf(TAG_PREFIX) === 0 && activeTags.indexOf(n.tag) === -1) n.close();
          });
        }).catch(function () {});
      }

      // Web Push aktif/sedang didaftarkan: notifikasi dikirim server, jangan dobel dari halaman.
      // Notifikasi lokal hanya cadangan bila Web Push tidak didukung atau gagal didaftarkan.
      if (pushSupported() && Notification.permission === 'granted' && !pushFailed) return;
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
          data: { url: '/jadwal', tanggal: tanggal },
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
    toggleBtn = document.getElementById('notif-toggle-btn');
    var vapidMeta = document.querySelector('meta[name="vapid-public-key"]');
    vapidKey = vapidMeta ? vapidMeta.content : '';
    if (!banner) return; // hanya dirender untuk pegawai (bukan Tamu)

    // Keluar: hapus langganan perangkat ini dulu agar akun berikutnya tidak menerima notifikasi akun ini
    var logout = document.getElementById('logout-link');
    if (logout) {
      logout.addEventListener('click', function (e) {
        if (!pushSupported()) return;
        e.preventDefault();
        var go = function () { window.location.href = logout.href; };
        withTimeout(unsubscribePush(), 2500).then(go, go);
      });
    }

    updateUi();
    syncPush(); // tombol lonceng diperbarui otomatis setelah pendaftaran selesai
    check();
    setInterval(check, POLL_INTERVAL_MS);

    // Segera perbarui ketika tab/PWA kembali aktif
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') check();
    });
  });
})();
