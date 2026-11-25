{{--
    Layout utama (kerangka halaman): sidebar responsif (drawer di mobile/PWA) + top bar + area isi + navigasi bawah mobile.
    Dipakai oleh semua halaman dengan cara:

        @extends('layouts.app', ['title' => 'Judul Halaman', 'activeNav' => 'pencarian'])
        @section('content')
            ... isi halaman ...
        @endsection

    activeNav: pencarian | jadwal | kelola-akun | tambah-peraturan
    $user (array: id, username, peran) otomatis tersedia dari middleware LoadUser.
--}}
@use('App\Support\TeksHelper')
@php
    $isGuest = $user['peran'] === 'Tamu';
    $isPengelola = $user['peran'] === 'Pengelola';

    // Nama tampilan & keterangan peran agar tidak ada kata ganda
    $profiles = [
        'Pengelola' => ['name' => 'Pengelola', 'subtitle' => 'Data, Jadwal & Akun'],
        'Perancang' => ['name' => 'Perancang', 'subtitle' => 'Tim Harmonisasi'],
        'Tamu'      => ['name' => 'Tamu',      'subtitle' => 'Akses Publik'],
    ];
    $profile = $profiles[$user['peran']] ?? ['name' => $user['username'], 'subtitle' => $user['peran']];
    $isDefaultRoleUsername = $isGuest || strtolower($user['username']) === strtolower($user['peran']);
    $displayName = $isDefaultRoleUsername ? $profile['name'] : $user['username'];
    $displayRole = $isDefaultRoleUsername ? $profile['subtitle'] : $profile['name'];

    $navIcon = [
        'pencarian'        => 'find_in_page',
        'jadwal'           => 'event_available',
        'tambah-peraturan' => 'post_add',
        'kelola-akun'      => 'manage_accounts',
    ];

    $navCls = fn ($key) => $activeNav === $key
        ? 'flex items-center gap-space-md px-space-md py-3 transition-colors bg-secondary text-on-secondary rounded'
        : 'flex items-center gap-space-md px-space-md py-3 text-on-primary hover:bg-white/10 transition-colors rounded';

    $mobileTabCls = fn ($key) => $activeNav === $key
        ? 'flex flex-col items-center justify-center gap-0.5 flex-1 py-2 text-[#1d4ed8] font-semibold'
        : 'flex flex-col items-center justify-center gap-0.5 flex-1 py-2 text-[#64748b] hover:text-[#0e1c2f] font-medium';
@endphp
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @if (! $isGuest && \App\Services\JadwalPushService::aktif())
        {{-- Kunci publik Web Push (aman ditampilkan) --}}
        <meta name="vapid-public-key" content="{{ config('webpush.public_key') }}">
    @endif
    <meta name="theme-color" content="#0e1c2f">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="P3H Kalsel">
    <title>{{ $title }} - P3H Kanwil Kementerian Hukum Kalsel</title>
    <link rel="icon" type="image/png" href="/images/logo.png">
    <link rel="apple-touch-icon" sizes="180x180" href="/images/apple-touch-icon.png">
    <link rel="manifest" href="/manifest.json">

    {{-- Font Inter --}}
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap" rel="stylesheet">

    {{-- Tailwind (CDN) + konfigurasi warna --}}
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="/js/tailwind-config.js"></script>

    <style>
        @layer base {
            html, body { margin: 0; padding: 0; height: auto; min-height: 100%; }
            body { overflow-x: clip; -webkit-overflow-scrolling: touch; }
        }
        ::-webkit-scrollbar { display: none; }
        .content-body { width: 100%; padding: 1.5rem 2rem; display: flex; flex-direction: column; gap: 1.5rem; }
        .pwa-safe-top { padding-top: env(safe-area-inset-top, 0px); }
        .pwa-safe-bottom { padding-bottom: env(safe-area-inset-bottom, 0px); }
    </style>

    {{-- CSS halaman (hasil pencarian, tabel, modal, dll.) --}}
    <link rel="stylesheet" href="/css/style.css?v=2">
    {{-- Banner notifikasi jadwal rapat hari ini --}}
    <link rel="stylesheet" href="/css/notification.css?v=2">

    {{-- HTMX --}}
    <script src="https://unpkg.com/htmx.org@1.9.10" integrity="sha384-D1Kt99CQMDuVetoL1lrYwg5t+9QdHe7NLX/SoJYkXDFfX37iInKRy5xLSi8nO7UC" crossorigin="anonymous"></script>
    {{-- Batasi teks pasal 5 baris + tombol "Selengkapnya" --}}
    <script src="/js/quote-clamp.js" defer></script>
</head>

{{-- hx-headers: setiap permintaan HTMX otomatis menyertakan token CSRF (wajib di Laravel untuk POST) --}}
<body class="bg-surface font-body-md text-on-surface antialiased" data-is-guest="{{ $isGuest ? 'true' : 'false' }}" hx-headers='{"X-CSRF-TOKEN": "{{ csrf_token() }}"}'>

    {{-- ── Sidebar (Khusus Desktop >= 1024px; Mobile memakai navigasi bawah) ── --}}
    <aside
        id="app-sidebar"
        class="hidden lg:flex fixed left-0 top-0 h-full w-72 xl:w-80 bg-primary-container text-on-primary border-r border-outline/20 z-50 flex-col"
        aria-label="Navigasi utama"
    >
        <div class="h-16 px-space-md border-b border-white/10 flex items-center gap-space-sm flex-shrink-0">
            <img src="/images/logo.png" alt="Logo Pengayoman" class="w-10 h-10 object-contain rounded-lg flex-shrink-0">
            <div class="flex flex-col min-w-0 leading-tight">
                <span class="text-[17px] font-bold text-on-primary tracking-tight truncate">Kementerian Hukum</span>
                <span class="text-[12px] text-[#94a3b8] font-medium tracking-normal truncate">Kalimantan Selatan</span>
            </div>
        </div>

        <div class="px-space-md pt-space-md pb-space-xs flex-shrink-0">
            <span class="text-[11px] uppercase tracking-widest text-on-primary-container font-bold">Menu Yuridis</span>
        </div>

        <nav class="flex flex-col px-space-md gap-space-xs flex-1 overflow-y-auto">
            <a href="/pencarian" class="{{ $navCls('pencarian') }}">
                <span class="flex-shrink-0">{!! TeksHelper::ikon($navIcon['pencarian'], 20) !!}</span>
                <span class="text-[15px] font-semibold">Pencarian Pasal</span>
            </a>

            @unless ($isGuest)
                <a href="/jadwal" class="{{ $navCls('jadwal') }}">
                    <span class="flex-shrink-0">{!! TeksHelper::ikon($navIcon['jadwal'], 20) !!}</span>
                    <span class="text-[15px] font-semibold">Jadwal Harmonisasi</span>
                </a>
            @endunless

            @if ($isPengelola)
                <a href="/tambah-peraturan" class="{{ $navCls('tambah-peraturan') }}">
                    <span class="flex-shrink-0">{!! TeksHelper::ikon($navIcon['tambah-peraturan'], 20) !!}</span>
                    <span class="text-[15px] font-semibold">Tambah Peraturan</span>
                </a>

                <a href="/kelola-akun" class="{{ $navCls('kelola-akun') }}">
                    <span class="flex-shrink-0">{!! TeksHelper::ikon($navIcon['kelola-akun'], 20) !!}</span>
                    <span class="text-[15px] font-semibold">Kelola Akun</span>
                </a>
            @endif
        </nav>
    </aside>

    {{-- ── Area utama ── --}}
    <div class="lg:pl-72 xl:pl-80 min-h-screen flex flex-col">

        <header class="fixed top-0 left-0 lg:left-72 xl:left-80 right-0 min-h-16 bg-surface-container-lowest border-b border-outline-variant z-30 px-3 sm:px-space-lg flex items-center justify-between gap-2 pwa-safe-top">
            <div class="flex items-center gap-2.5 min-w-0 flex-1 py-2">
                <img src="/images/logo.png" alt="Logo Pengayoman" class="lg:hidden w-8 h-8 object-contain flex-shrink-0">
                <h1 class="text-[14px] sm:text-[17px] lg:text-[18px] font-bold text-[#0b192c] tracking-tight uppercase truncate">{{ mb_strtoupper($title) }}</h1>
            </div>

            <div class="flex items-center gap-2 sm:gap-space-md flex-shrink-0 py-2">
                <div class="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-[#0b192c] text-white rounded-lg flex-shrink-0">
                    <span class="text-white flex-shrink-0">{!! TeksHelper::ikon('person', 18) !!}</span>
                    <div class="flex flex-col min-w-0 text-left leading-tight">
                        <span class="text-[13px] font-semibold text-white truncate">{{ $displayName }}</span>
                        <span class="text-[11px] text-[#94a3b8] leading-none truncate">{{ $displayRole }}</span>
                    </div>
                </div>

                @if ($isGuest)
                    <a href="/login" class="h-9 px-3 sm:px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1.5 transition-colors rounded-lg hover:bg-surface-container-high">
                        {!! TeksHelper::ikon('login', 17) !!}
                        <span>Masuk</span>
                    </a>
                @else
                    {{-- Notifikasi jadwal rapat di perangkat ini (Web Push) — status diatur oleh /js/notification.js --}}
                    <button
                        type="button"
                        id="notif-toggle-btn"
                        class="notif-toggle-btn hidden h-9 w-9 border border-outline-variant rounded-lg flex items-center justify-center transition-colors"
                        onclick="toggleJadwalNotifications()"
                        aria-label="Notifikasi jadwal rapat"
                        title="Notifikasi jadwal rapat"
                    >
                        {!! TeksHelper::ikon('notifications', 18) !!}
                        <span class="notif-toggle-dot" aria-hidden="true"></span>
                    </button>

                    <a href="/logout" id="logout-link" class="h-9 px-3 sm:px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1.5 transition-colors rounded-lg hover:bg-surface-container-high">
                        {!! TeksHelper::ikon('logout', 17) !!}
                        <span>Keluar</span>
                    </a>
                @endif
            </div>
        </header>

        <main class="w-full pt-16 pb-24 lg:pb-0 bg-surface flex-1">
            <div class="content-body">
                @unless ($isGuest)
                    {{-- Diisi oleh /js/notification.js bila ada rapat hari ini --}}
                    <div id="jadwal-notif-banner" class="jadwal-notif-banner hidden" role="status" aria-live="polite">
                        <div class="jadwal-notif-inner">
                            <span class="jadwal-notif-icon">{!! TeksHelper::ikon('notifications', 22) !!}</span>
                            <div class="jadwal-notif-content">
                                <a href="/jadwal" class="jadwal-notif-title">Jadwal Rapat Hari Ini</a>
                                <div id="jadwal-notif-list"></div>
                                <button type="button" id="jadwal-notif-enable" class="jadwal-notif-enable hidden" onclick="enableJadwalNotifications()">
                                    Aktifkan notifikasi perangkat
                                </button>
                            </div>
                            <button type="button" class="jadwal-notif-close" onclick="dismissJadwalBanner()" aria-label="Tutup">
                                {!! TeksHelper::ikon('close', 18) !!}
                            </button>
                        </div>
                    </div>
                @endunless
                @yield('content')
            </div>
        </main>
    </div>

    {{-- ── Navigasi Bawah Khusus Mobile / PWA (< 1024px) ── --}}
    <nav
        class="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-[#e2e8f0] z-30 flex items-stretch justify-around px-1 pwa-safe-bottom"
        aria-label="Navigasi cepat mobile"
    >
        <a href="/pencarian" class="{{ $mobileTabCls('pencarian') }}">
            {!! TeksHelper::ikon('find_in_page', 20) !!}
            <span class="text-[11px] leading-tight">Pencarian</span>
        </a>

        @unless ($isGuest)
            <a href="/jadwal" class="{{ $mobileTabCls('jadwal') }}">
                {!! TeksHelper::ikon('event_available', 20) !!}
                <span class="text-[11px] leading-tight">Jadwal</span>
            </a>
        @endunless

        @if ($isPengelola)
            <a href="/tambah-peraturan" class="{{ $mobileTabCls('tambah-peraturan') }}">
                {!! TeksHelper::ikon('post_add', 20) !!}
                <span class="text-[11px] leading-tight">Tambah</span>
            </a>

            <a href="/kelola-akun" class="{{ $mobileTabCls('kelola-akun') }}">
                {!! TeksHelper::ikon('manage_accounts', 20) !!}
                <span class="text-[11px] leading-tight">Akun</span>
            </a>
        @endif

        <button
            type="button"
            id="mobile-nav-pwa-btn"
            onclick="triggerPwaDownload()"
            class="flex flex-col items-center justify-center gap-0.5 flex-1 py-2 text-[#64748b] hover:text-[#0e1c2f] font-medium cursor-pointer bg-transparent border-0"
        >
            {!! TeksHelper::ikon('download', 20) !!}
            <span class="text-[11px] leading-tight">Aplikasi</span>
        </button>
    </nav>

    {{-- ── Modal Panduan Install PWA (iOS Safari & Desktop/Android) ── --}}
    <div
        id="pwa-install-modal"
        class="modal-backdrop hidden"
        role="dialog"
        aria-modal="true"
        aria-labelledby="pwa-modal-title"
        onclick="if (event.target === this) closePwaModal()"
    >
        <div class="modal-content" style="max-width: 480px;">
            <div class="modal-header">
                <div class="flex items-center gap-3 min-w-0">
                    <img src="/images/icon-192.png" alt="Ikon P3H Kalsel" class="w-11 h-11 rounded-lg flex-shrink-0">
                    <div class="min-w-0">
                        <h3 id="pwa-modal-title">Download Aplikasi P3H Kalsel</h3>
                        <p>Pasang langsung di layar utama perangkat Anda (PWA)</p>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="closePwaModal()" aria-label="Tutup">
                    {!! TeksHelper::ikon('close', 18) !!}
                </button>
            </div>

            <div id="pwa-modal-standalone" class="hidden alert alert-success" style="margin-bottom: 1rem;">
                {!! TeksHelper::ikon('check', 18) !!}
                <span>Aplikasi P3H Kalsel sudah terpasang dan berjalan dalam mode aplikasi.</span>
            </div>

            <div id="pwa-modal-prompt-wrap" class="hidden" style="margin-bottom: 1rem;">
                <button
                    type="button"
                    id="pwa-modal-install-action"
                    class="btn btn-primary btn-block"
                    onclick="runNativePwaInstall()"
                >
                    {!! TeksHelper::ikon('download', 18) !!}
                    Pasang Aplikasi Sekarang
                </button>
            </div>

            <div class="space-y-3">
                <div style="padding: 0.875rem 1rem; background: var(--canvas); border: 1px solid var(--border); border-radius: var(--radius-lg);">
                    <div style="font-size: 13px; font-weight: 700; color: var(--navy); margin-bottom: 0.45rem;">
                        Pengguna Apple (iPhone / iPad — Safari)
                    </div>
                    <ol style="margin: 0; padding-left: 1.25rem; list-style: decimal; font-size: 13px; line-height: 1.65; color: var(--text);">
                        <li>Buka situs ini menggunakan browser <strong>Safari</strong>.</li>
                        <li>Ketuk tombol <strong>Bagikan (Share)</strong> di bagian bawah layar Safari.</li>
                        <li>Gulir ke bawah lalu pilih <strong>Tambahkan ke Layar Utama (Add to Home Screen)</strong>.</li>
                        <li>Ketuk <strong>Tambah (Add)</strong> di pojok kanan atas.</li>
                    </ol>
                </div>

                <div style="padding: 0.875rem 1rem; background: var(--canvas); border: 1px solid var(--border); border-radius: var(--radius-lg);">
                    <div style="font-size: 13px; font-weight: 700; color: var(--navy); margin-bottom: 0.45rem;">
                        Pengguna Android (Chrome &amp; Edge)
                    </div>
                    <ol style="margin: 0; padding-left: 1.25rem; list-style: decimal; font-size: 13px; line-height: 1.65; color: var(--text);">
                        <li>Klik tombol <strong>Pasang Aplikasi</strong> bila tersedia, atau buka menu browser (<strong>&#8942;</strong>).</li>
                        <li>Pilih <strong>Instal Aplikasi</strong> / <strong>Tambahkan ke layar utama</strong>.</li>
                    </ol>
                </div>
            </div>

            <div class="form-actions" style="margin-top: 1.25rem;">
                <button type="button" class="btn btn-primary" onclick="closePwaModal()">Mengerti</button>
            </div>
        </div>
    </div>

    <script>
        // ── PWA Install & Service Worker ──
        let deferredPwaPrompt = null;

        function isRunningStandalone() {
            return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
        }

        function updatePwaUi() {
            const titleEl = document.getElementById('pwa-download-title');
            const subEl = document.getElementById('pwa-download-sub');
            const standaloneNote = document.getElementById('pwa-modal-standalone');
            const promptWrap = document.getElementById('pwa-modal-prompt-wrap');
            const mobileNavPwaBtn = document.getElementById('mobile-nav-pwa-btn');

            if (isRunningStandalone()) {
                if (titleEl) titleEl.textContent = 'Aplikasi Terpasang';
                if (subEl) subEl.textContent = 'Mode Aplikasi Aktif';
                if (standaloneNote) standaloneNote.classList.remove('hidden');
                if (mobileNavPwaBtn) mobileNavPwaBtn.classList.add('hidden');
            }
            if (promptWrap) {
                if (deferredPwaPrompt) promptWrap.classList.remove('hidden');
                else promptWrap.classList.add('hidden');
            }
        }

        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            deferredPwaPrompt = e;
            updatePwaUi();
        });

        window.addEventListener('appinstalled', () => {
            deferredPwaPrompt = null;
            updatePwaUi();
            closePwaModal();
        });

        function openPwaModal() {
            updatePwaUi();
            const modal = document.getElementById('pwa-install-modal');
            if (modal) modal.classList.remove('hidden');
        }

        function closePwaModal() {
            const modal = document.getElementById('pwa-install-modal');
            if (modal) modal.classList.add('hidden');
        }

        async function runNativePwaInstall() {
            if (!deferredPwaPrompt) return;
            deferredPwaPrompt.prompt();
            try {
                await deferredPwaPrompt.userChoice;
            } catch (_) {}
            deferredPwaPrompt = null;
            updatePwaUi();
            closePwaModal();
        }

        function triggerPwaDownload() {
            if (deferredPwaPrompt) {
                runNativePwaInstall();
            } else {
                openPwaModal();
            }
        }

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                closePwaModal();
            }
        });

        document.addEventListener('DOMContentLoaded', () => {
            updatePwaUi();
            if ('serviceWorker' in navigator) {
                navigator.serviceWorker.register('/sw.js').catch(() => {});
            }
        });
    </script>

    @unless ($isGuest)
        {{-- Notifikasi jadwal rapat hari ini (banner + notifikasi browser) --}}
        <script src="/js/notification.js?v=4" defer></script>
    @endunless

</body>
</html>
