import { jsx } from 'hono/jsx';

interface LoginProps {
  error?: string;
}

const TAILWIND_CONFIG = `{"darkMode":"class","theme":{"extend":{"colors":{"secondary":"#4059aa","on-secondary-fixed":"#00164e","inverse-primary":"#bac7e1","surface-dim":"#d2d9f4","on-error":"#ffffff","error":"#ba1a1a","on-primary-container":"#77849c","outline-variant":"#c5c6cd","on-primary":"#ffffff","on-surface":"#131b2e","on-surface-variant":"#44474c","outline":"#75777d","secondary-fixed-dim":"#b6c4ff","on-primary-fixed":"#0e1c2f","primary-container":"#0e1c2f","on-secondary-container":"#1d3989","primary-fixed":"#d6e3fe","surface-variant":"#dae2fd","surface-tint":"#525f75","on-secondary":"#ffffff","inverse-on-surface":"#eef0ff","inverse-surface":"#283044","secondary-fixed":"#dce1ff","primary-fixed-dim":"#bac7e1","primary":"#000000","error-container":"#ffdad6","on-background":"#131b2e","on-tertiary-container":"#c76c00","on-secondary-fixed-variant":"#264191","surface-container-lowest":"#ffffff","surface-container-low":"#f2f3ff","on-tertiary-fixed":"#2f1500","surface-bright":"#faf8ff","surface-container":"#eaedff","tertiary":"#000000","surface-container-highest":"#dae2fd","secondary-container":"#8fa7fe","tertiary-fixed-dim":"#ffb77d","tertiary-container":"#2f1500","on-tertiary":"#ffffff","surface-container-high":"#e2e7ff","background":"#faf8ff","tertiary-fixed":"#ffdcc3","surface":"#faf8ff","on-tertiary-fixed-variant":"#6e3900","on-error-container":"#93000a","on-primary-fixed-variant":"#3a475c"},"borderRadius":{"DEFAULT":"0.125rem","lg":"0.25rem","xl":"0.5rem","full":"0.75rem"},"spacing":{"margin-lg":"3rem","gutter":"1rem","space-lg":"1.5rem","margin-md":"2rem","space-xs":"0.25rem","gutter-md":"1.5rem","margin":"1rem","space-sm":"0.5rem","space-xl":"2.5rem","space-md":"1rem","gutter-lg":"2rem"},"fontFamily":{"label-sm":["Inter"],"body-md":["Inter"],"headline-xl":["Inter"],"title-md":["Inter"],"title-sm":["Inter"],"headline-sm":["Inter"],"body-sm":["Inter"],"headline-md":["Inter"],"headline-lg":["Inter"],"body-lg":["Inter"],"label-md":["Inter"],"headline-xl-mobile":["Inter"],"headline-lg-mobile":["Inter"]},"fontSize":{"label-sm":["11px",{"lineHeight":"14px","fontWeight":"500"}],"body-md":["14px",{"lineHeight":"22px","fontWeight":"400"}],"headline-xl":["36px",{"lineHeight":"44px","fontWeight":"700"}],"title-md":["16px",{"lineHeight":"22px","fontWeight":"600"}],"title-sm":["14px",{"lineHeight":"20px","fontWeight":"600"}],"headline-sm":["18px",{"lineHeight":"24px","fontWeight":"600"}],"body-sm":["13px",{"lineHeight":"18px","fontWeight":"400"}],"headline-md":["22px",{"lineHeight":"28px","fontWeight":"600"}],"headline-lg":["28px",{"lineHeight":"36px","fontWeight":"700"}],"body-lg":["16px",{"lineHeight":"26px","fontWeight":"400"}],"label-md":["12px",{"lineHeight":"16px","fontWeight":"600"}],"headline-xl-mobile":["28px",{"lineHeight":"36px","fontWeight":"700"}],"headline-lg-mobile":["24px",{"lineHeight":"32px","fontWeight":"600"}]}}}}`; 

export function LoginView({ error }: LoginProps) {
  return (
    <html lang="id">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Masuk - P3H Kanwil Kementerian Hukum Kalsel</title>
        <link rel="icon" type="image/png" href="/images/logo.png" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
        <script src="https://cdn.tailwindcss.com"></script>
        <script id="tailwind-config" dangerouslySetInnerHTML={{ __html: `tailwind.config=${TAILWIND_CONFIG}` }}></script>
        <style dangerouslySetInnerHTML={{ __html: `
          body { font-family: 'Inter', sans-serif; margin: 0; padding: 0; background-color: #0b192c; color: #1e293b; -webkit-font-smoothing: antialiased; }
        `}}></style>
      </head>

      <body class="w-full min-h-screen bg-[#0b192c] flex flex-col justify-between p-12">

        {/* ── Top Navigation / Brand Header ── */}
        <header class="w-full flex items-center justify-between pb-6 border-b border-[#1e293b]">
          <div class="flex items-center gap-4">
            {/* Logo box */}
            <div class="w-14 h-14 bg-[#081220] border border-[#1e293b] rounded-xl flex items-center justify-center p-2.5">
              <img src="/images/logo.png" alt="Logo Pengayoman" class="w-full h-full object-contain" />
            </div>
            <div>
              <h1 class="text-white text-xl font-bold tracking-wide leading-tight">KEMENTERIAN HUKUM REPUBLIK INDONESIA</h1>
              <p class="text-slate-300 text-sm font-medium mt-0.5">Kantor Wilayah Kalimantan Selatan &bull; Divisi Pelayanan Hukum dan HAM</p>
            </div>
          </div>
          {/* Online dot */}
          <div class="flex items-center gap-2.5 text-xs text-slate-300 font-mono bg-[#081220] px-3.5 py-2 rounded-xl border border-[#1e293b]">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block"></span>
          </div>
        </header>

        {/* ── Login Card ── */}
        <main class="w-full flex-1 flex items-center justify-center py-8">
          <div class="w-full max-w-[520px] bg-white rounded-2xl shadow-2xl p-12 border border-slate-200 flex flex-col gap-0">

            {/* Logo + heading */}
            <div class="mb-8 text-center flex flex-col items-center">
              <div class="w-16 h-16 bg-[#0b192c] rounded-xl flex items-center justify-center p-3 mb-4">
                <img src="/images/logo.png" alt="Logo Pengayoman" class="w-full h-full object-contain" />
              </div>
              <h2 class="text-2xl font-bold text-slate-900 tracking-tight">Masuk Sistem</h2>
              <p class="text-sm text-slate-500 mt-2 leading-normal">Portal Pencarian Pasal &amp; Harmonisasi Regulasi Daerah</p>
            </div>

            {/* Error alert */}
            {error && (
              <div class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl">
                {error}
              </div>
            )}

            {/* Form */}
            <form class="space-y-5" action="/login" method="post">

              {/* Username */}
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
                  />
                </div>
              </div>

              {/* Password */}
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
                  />
                </div>
              </div>

              {/* Remember */}
              <div class="flex items-center gap-2">
                <input
                  id="remember_me"
                  name="remember"
                  type="checkbox"
                  value="1"
                  checked
                  class="h-4 w-4 text-[#0b192c] focus:ring-[#0b192c] border-slate-300 rounded cursor-pointer"
                />
                <label for="remember_me" class="text-xs font-medium text-slate-700 cursor-pointer">
                  Ingat sesi login pada perangkat kerja ini
                </label>
              </div>

              {/* Submit */}
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

            {/* Divider + guest link */}
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

        {/* ── Footer ── */}
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
  );
}
