{{--
    Layout utama (kerangka halaman): sidebar + top bar + area isi.
    Dipakai oleh semua halaman setelah login dengan cara:

        @extends('layouts.app', ['title' => 'Judul Halaman', 'activeNav' => 'pencarian'])
        @section('content')
            ... isi halaman ...
        @endsection

    activeNav: pencarian | jadwal | kelola-akun | tambah-peraturan
    $user (array: id, username, peran) otomatis tersedia dari middleware LoadUser.
--}}
@php
    $isGuest = $user['peran'] === 'Tamu';

    // Nama tampilan & keterangan peran agar tidak ada kata ganda
    $profiles = [
        'Admin'     => ['name' => 'Administrator', 'subtitle' => 'Manajemen Sistem'],
        'Pengelola' => ['name' => 'Pengelola',     'subtitle' => 'Data & Jadwal'],
        'Perancang' => ['name' => 'Perancang',     'subtitle' => 'Tim Harmonisasi'],
        'Tamu'      => ['name' => 'Tamu',          'subtitle' => 'Akses Publik'],
    ];
    $profile = $profiles[$user['peran']] ?? ['name' => $user['username'], 'subtitle' => $user['peran']];
    $isDefaultRoleUsername = $isGuest || strtolower($user['username']) === strtolower($user['peran']);
    $displayName = $isDefaultRoleUsername ? $profile['name'] : $user['username'];
    $displayRole = $isDefaultRoleUsername ? $profile['subtitle'] : $profile['name'];

    $navIcon = [
        'pencarian' => 'find_in_page',
        'jadwal' => 'event_available',
        'tambah-peraturan' => 'post_add',
        'kelola-akun' => 'manage_accounts',
    ];

    $navCls = fn ($key) => $activeNav === $key
        ? 'flex items-center gap-space-md px-space-md py-3 transition-colors bg-secondary text-on-secondary rounded'
        : 'flex items-center gap-space-md px-space-md py-3 text-on-primary hover:bg-white/10 transition-colors rounded';
@endphp
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title }} - P3H Kanwil Kementerian Hukum Kalsel</title>
    <link rel="icon" type="image/png" href="/images/logo.png">

    {{-- Material Symbols & font Inter --}}
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap" rel="stylesheet">

    {{-- Tailwind (CDN) + konfigurasi warna --}}
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="/js/tailwind-config.js"></script>

    <style>
        @layer base { html, body { margin: 0; padding: 0; } body { overscroll-behavior: none; } }
        ::-webkit-scrollbar { display: none; }
        .content-body { width: 100%; padding: 1.5rem 2rem; display: flex; flex-direction: column; gap: 1.5rem; }
    </style>

    {{-- CSS halaman (hasil pencarian, tabel, modal, dll.) --}}
    <link rel="stylesheet" href="/css/style.css">

    {{-- HTMX --}}
    <script src="https://unpkg.com/htmx.org@1.9.10" integrity="sha384-D1Kt99CQMDuVetoL1lrYwg5t+9QdHe7NLX/SoJYkXDFfX37iInKRy5xLSi8nO7UC" crossorigin="anonymous"></script>
    {{-- Batasi teks pasal 5 baris + tombol "Selengkapnya" --}}
    <script src="/js/quote-clamp.js" defer></script>
</head>

{{-- hx-headers: setiap permintaan HTMX otomatis menyertakan token CSRF (wajib di Laravel untuk POST) --}}
<body class="bg-surface font-body-md text-on-surface antialiased" hx-headers='{"X-CSRF-TOKEN": "{{ csrf_token() }}"}'>

    {{-- ── Sidebar ── --}}
    <aside class="fixed left-0 top-0 h-full w-80 bg-primary-container text-on-primary border-r border-outline/20 z-50 flex flex-col">

        <div class="h-16 px-space-md border-b border-white/10 flex items-center gap-space-sm flex-shrink-0">
            <img src="/images/logo.png" alt="Logo Pengayoman" class="w-10 h-10 object-contain rounded-lg flex-shrink-0">
            <div class="flex flex-col min-w-0 leading-tight">
                <span class="text-[18px] font-bold text-on-primary tracking-tight truncate">Kementerian Hukum</span>
                <span class="text-[13px] text-[#94a3b8] font-medium tracking-normal truncate">Kalimantan Selatan</span>
            </div>
        </div>

        <div class="px-space-md pt-space-md pb-space-xs flex-shrink-0">
            <span class="text-[11px] uppercase tracking-widest text-on-primary-container font-bold">Menu Yuridis</span>
        </div>

        <nav class="flex flex-col px-space-md gap-space-xs flex-1 overflow-hidden">
            <a href="/pencarian" class="{{ $navCls('pencarian') }}">
                <span class="material-symbols-outlined text-[22px]">{{ $navIcon['pencarian'] }}</span>
                <span class="text-[15px] font-semibold">Pencarian Pasal</span>
            </a>

            @unless ($isGuest)
                <a href="/jadwal" class="{{ $navCls('jadwal') }}">
                    <span class="material-symbols-outlined text-[22px]">{{ $navIcon['jadwal'] }}</span>
                    <span class="text-[15px] font-semibold">Jadwal Harmonisasi</span>
                </a>
            @endunless

            @if (in_array($user['peran'], ['Pengelola', 'Admin']))
                <a href="/tambah-peraturan" class="{{ $navCls('tambah-peraturan') }}">
                    <span class="material-symbols-outlined text-[22px]">{{ $navIcon['tambah-peraturan'] }}</span>
                    <span class="text-[15px] font-semibold">Tambah Peraturan</span>
                </a>
            @endif

            @if ($user['peran'] === 'Admin')
                <a href="/kelola-akun" class="{{ $navCls('kelola-akun') }}">
                    <span class="material-symbols-outlined text-[22px]">{{ $navIcon['kelola-akun'] }}</span>
                    <span class="text-[15px] font-semibold">Kelola Akun</span>
                </a>
            @endif
        </nav>

        <div class="px-space-md py-space-md border-t border-white/10 flex-shrink-0">
            <div class="flex items-center gap-space-sm">
                <div class="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
                    <span class="material-symbols-outlined text-[18px] text-on-primary-container">person</span>
                </div>
                <div class="flex flex-col min-w-0">
                    <span class="text-[14px] font-semibold text-on-primary truncate leading-tight">{{ $displayName }}</span>
                    <span class="text-[11px] text-on-primary-container truncate leading-tight">{{ $displayRole }}</span>
                </div>
            </div>
        </div>
    </aside>

    {{-- ── Area utama ── --}}
    <div class="pl-80">

        <header class="fixed top-0 left-80 right-0 h-16 bg-surface-container-lowest border-b border-outline-variant z-40 px-space-lg flex items-center justify-between">
            <h1 class="text-[18px] font-bold text-[#0b192c] tracking-tight uppercase">{{ mb_strtoupper($title) }}</h1>

            <div class="flex items-center gap-space-md">
                <div class="flex items-center gap-2 px-3 py-1.5 bg-[#0b192c] text-white rounded-lg flex-shrink-0">
                    <span class="material-symbols-outlined text-[18px] text-white flex-shrink-0">person</span>
                    <div class="flex flex-col min-w-0 text-left leading-tight">
                        <span class="text-[13px] font-semibold text-white truncate">{{ $displayName }}</span>
                        <span class="text-[11px] text-[#94a3b8] leading-none truncate">{{ $displayRole }}</span>
                    </div>
                </div>

                @if ($isGuest)
                    <a href="/login" class="h-9 px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1 transition-colors rounded-lg hover:bg-surface-container-high">
                        <span class="material-symbols-outlined text-[18px]">login</span>
                        <span>Masuk</span>
                    </a>
                @else
                    <a href="/logout" class="h-9 px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1 transition-colors rounded-lg hover:bg-surface-container-high">
                        <span class="material-symbols-outlined text-[18px]">logout</span>
                        <span>Keluar</span>
                    </a>
                @endif
            </div>
        </header>

        <main class="w-full pt-16 bg-surface min-h-screen">
            <div class="content-body">
                @yield('content')
            </div>
        </main>
    </div>

</body>
</html>
