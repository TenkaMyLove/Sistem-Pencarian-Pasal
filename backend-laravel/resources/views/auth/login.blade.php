{{--
    Halaman login (STANDALONE: tidak memakai layout utama).
    Variabel: $error (string atau null) -> pesan kesalahan login.
--}}
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#0b192c">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="P3H Kalsel">
    <title>Masuk - P3H Kanwil Kementerian Hukum Kalsel</title>
    <link rel="icon" type="image/png" href="/images/logo.png">
    <link rel="apple-touch-icon" sizes="180x180" href="/images/apple-touch-icon.png">
    <link rel="manifest" href="/manifest.json">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

    {{-- Tailwind (CDN) + konfigurasi warna dari file JS terpisah --}}
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="/js/tailwind-config.js"></script>
    <style>
        body { font-family: 'Inter', sans-serif; margin: 0; padding: 0; background-color: #0b192c; color: #1e293b; -webkit-font-smoothing: antialiased; }
    </style>
</head>

<body class="w-full min-h-screen bg-[#0b192c] flex flex-col justify-between p-4 sm:p-8 lg:p-12">

    {{-- ── Header / identitas instansi ── --}}
    <header class="w-full flex items-center justify-between gap-3 pb-4 sm:pb-6 border-b border-[#1e293b]">
        <div class="flex items-center gap-3 sm:gap-4 min-w-0">
            {{-- Kotak logo --}}
            <div class="w-11 h-11 sm:w-14 sm:h-14 bg-[#081220] border border-[#1e293b] rounded-xl flex items-center justify-center p-2 sm:p-2.5 flex-shrink-0">
                <img src="/images/logo.png" alt="Logo Pengayoman" class="w-full h-full object-contain">
            </div>
            <div class="min-w-0">
                <h1 class="text-white text-sm sm:text-xl font-bold tracking-wide leading-tight">KEMENTERIAN HUKUM REPUBLIK INDONESIA</h1>
                <p class="text-slate-300 text-xs sm:text-sm font-medium mt-0.5 truncate">Kantor Wilayah Kalimantan Selatan &bull; Divisi P3H</p>
            </div>
        </div>
        {{-- Titik hijau "online" --}}
        <div class="hidden sm:flex items-center gap-2.5 text-xs text-slate-300 font-mono bg-[#081220] px-3.5 py-2 rounded-xl border border-[#1e293b] flex-shrink-0">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block"></span>
        </div>
    </header>

    {{-- ── Kartu login ── --}}
    <main class="w-full flex-1 flex items-center justify-center py-6 sm:py-8">
        <div class="w-full max-w-[520px] bg-white rounded-2xl shadow-2xl p-6 sm:p-10 lg:p-12 border border-slate-200 flex flex-col gap-0">

            {{-- Logo + judul --}}
            <div class="mb-8 text-center flex flex-col items-center">
                <div class="w-16 h-16 bg-[#0b192c] rounded-xl flex items-center justify-center p-3 mb-4">
                    <img src="/images/logo.png" alt="Logo Pengayoman" class="w-full h-full object-contain">
                </div>
                <h2 class="text-2xl font-bold text-slate-900 tracking-tight">Masuk Sistem</h2>
                <p class="text-sm text-slate-500 mt-2 leading-normal">Portal Pencarian Pasal &amp; Harmonisasi Regulasi Daerah</p>
            </div>

            {{-- Pesan error (hanya tampil jika ada) --}}
            @if (!empty($error))
                <div class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl">
                    {{ $error }}
                </div>
            @endif

            {{-- Form login. @csrf = token keamanan wajib Laravel untuk setiap form POST --}}
            <form class="space-y-5" action="/login" method="post">
                @csrf

                {{-- Username --}}
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2.5" for="username">
                        Username / NIP Pegawai
                    </label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400">
                            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                        </div>
                        <input
                            type="text"
                            id="username"
                            name="username"
                            required
                            autofocus
                            autocomplete="username"
                            placeholder="Username"
                            class="w-full pl-12 pr-4 py-3.5 bg-slate-50 border border-slate-300 text-slate-900 text-sm rounded-xl focus:ring-2 focus:ring-[#0b192c] focus:border-[#0b192c] focus:bg-white outline-none transition-all font-medium"
                        >
                    </div>
                </div>

                {{-- Kata sandi --}}
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2.5" for="kata_sandi">
                        Kata Sandi
                    </label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400">
                            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                            </svg>
                        </div>
                        <input
                            type="password"
                            id="kata_sandi"
                            name="kata_sandi"
                            required
                            autocomplete="current-password"
                            placeholder="••••••••••"
                            class="w-full pl-12 pr-4 py-3.5 bg-slate-50 border border-slate-300 text-slate-900 text-sm rounded-xl focus:ring-2 focus:ring-[#0b192c] focus:border-[#0b192c] focus:bg-white outline-none transition-all font-medium"
                        >
                    </div>
                </div>

                {{-- Ingat saya --}}
                <div class="flex items-center gap-2">
                    <input
                        id="remember_me"
                        name="remember"
                        type="checkbox"
                        value="1"
                        checked
                        class="h-4 w-4 text-[#0b192c] focus:ring-[#0b192c] border-slate-300 rounded cursor-pointer"
                    >
                    <label for="remember_me" class="text-xs font-medium text-slate-700 cursor-pointer">
                        Ingat sesi login pada perangkat kerja ini
                    </label>
                </div>

                {{-- Tombol kirim --}}
                <button
                    type="submit"
                    class="w-full py-4 px-4 bg-[#0b192c] hover:bg-[#152744] text-white font-semibold text-sm rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                    <span>Masuk ke Dashboard</span>
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path>
                    </svg>
                </button>
            </form>

            {{-- Pembatas + tautan akses tamu --}}
            <div class="pt-6 mt-6 border-t border-slate-200">
                <p class="text-xs text-slate-500 text-center mb-3">Masyarakat umum atau pemohon harmonisasi?</p>
                <a
                    href="/tamu"
                    class="w-full inline-flex items-center justify-center py-3 px-4 border border-slate-300 text-slate-700 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold rounded-xl transition-colors"
                >
                    Akses Pencarian Pasal Publik Tanpa Login
                </a>
            </div>
        </div>
    </main>

    {{-- ── Footer ── --}}
    <footer class="w-full flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pt-4 border-t border-[#1e293b] text-xs text-white">
        <div class="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-4 text-slate-300 text-xs font-normal">
            <span>&copy; 2026 Kanwil Kementerian Hukum Kalimantan Selatan.</span>
            <span class="hidden sm:inline text-slate-500">&bull;</span>
            <span>Jl. Brigjen H. Hasan Basry No. 49, Banjarmasin</span>
        </div>
        <div class="flex flex-wrap items-center gap-4 text-slate-300 text-xs font-medium">
            <a href="/pencarian" class="text-white hover:text-slate-200 hover:underline transition-colors">Pencarian Publik</a>
            <a href="#" class="text-slate-300 hover:text-white hover:underline transition-colors">Panduan Sistem</a>
        </div>
    </footer>

    <script>
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js').catch(() => {});
        }
    </script>

</body>
</html>
