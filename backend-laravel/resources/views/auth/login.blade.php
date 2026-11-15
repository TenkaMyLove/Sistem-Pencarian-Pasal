{{--
    Halaman login (STANDALONE: tidak memakai layout utama).
    Variabel: $error (string atau null) -> pesan kesalahan login.
--}}
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Masuk - P3H Kanwil Kementerian Hukum Kalsel</title>
    <link rel="icon" type="image/png" href="/images/logo.png">
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

<body class="w-full min-h-screen bg-[#0b192c] flex flex-col justify-between p-12">

    {{-- ── Header / identitas instansi ── --}}
    <header class="w-full flex items-center justify-between pb-6 border-b border-[#1e293b]">
        <div class="flex items-center gap-4">
            {{-- Kotak logo --}}
            <div class="w-14 h-14 bg-[#081220] border border-[#1e293b] rounded-xl flex items-center justify-center p-2.5">
                <img src="/images/logo.png" alt="Logo Pengayoman" class="w-full h-full object-contain">
            </div>
            <div>
                <h1 class="text-white text-xl font-bold tracking-wide leading-tight">KEMENTERIAN HUKUM REPUBLIK INDONESIA</h1>
                <p class="text-slate-300 text-sm font-medium mt-0.5">Kantor Wilayah Kalimantan Selatan &bull; Divisi Pelayanan Hukum dan HAM</p>
            </div>
        </div>
        {{-- Titik hijau "online" --}}
        <div class="flex items-center gap-2.5 text-xs text-slate-300 font-mono bg-[#081220] px-3.5 py-2 rounded-xl border border-[#1e293b]">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block"></span>
        </div>
    </header>

    {{-- ── Kartu login ── --}}
    <main class="w-full flex-1 flex items-center justify-center py-8">
        <div class="w-full max-w-[520px] bg-white rounded-2xl shadow-2xl p-12 border border-slate-200 flex flex-col gap-0">

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
                            placeholder="pengelola"
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
    <footer class="w-full flex items-center justify-between pt-4 border-t border-[#1e293b] text-xs text-white">
        <div class="flex items-center gap-6 text-white text-xs font-normal">
            <span>&copy; 2026 Kantor Wilayah Kementerian Hukum Kalimantan Selatan. Hak Cipta Dilindungi.</span>
            <span class="text-slate-400">&bull;</span>
            <span>Jl. Brigjen H. Hasan Basry No. 49, Banjarmasin</span>
        </div>
        <div class="flex items-center gap-6 text-white text-xs font-medium">
            <a href="#" class="text-white hover:text-slate-200 hover:underline transition-colors">Panduan Sistem</a>
            <a href="#" class="text-white hover:text-slate-200 hover:underline transition-colors">Bantuan Teknis</a>
            <a href="#" class="text-white hover:text-slate-200 hover:underline transition-colors">Kebijakan Privasi</a>
        </div>
    </footer>

</body>
</html>
