import { jsx } from 'hono/jsx';
import { UserSession } from '../middleware/auth.js';

interface LayoutProps {
  title: string;
  activeNav: 'pencarian' | 'jadwal' | 'kelola-akun' | 'tambah-peraturan';
  user: UserSession;
  children: any;
}

// Map peran → nama tampilan & keterangan peran yang rapi tanpa duplikasi kata
const PERAN_PROFILE: Record<string, { name: string; subtitle: string }> = {
  Admin:     { name: 'Administrator', subtitle: 'Manajemen Sistem' },
  Pengelola: { name: 'Pengelola',     subtitle: 'Data & Jadwal' },
  Perancang: { name: 'Perancang',     subtitle: 'Tim Harmonisasi' },
  Tamu:      { name: 'Tamu',          subtitle: 'Akses Publik' },
};

const TAILWIND_CONFIG = `{"darkMode":"class","theme":{"extend":{"colors":{"secondary":"#4059aa","on-secondary-fixed":"#00164e","inverse-primary":"#bac7e1","surface-dim":"#d2d9f4","on-error":"#ffffff","error":"#ba1a1a","on-primary-container":"#77849c","outline-variant":"#c5c6cd","on-primary":"#ffffff","on-surface":"#131b2e","on-surface-variant":"#44474c","outline":"#75777d","secondary-fixed-dim":"#b6c4ff","on-primary-fixed":"#0e1c2f","primary-container":"#0e1c2f","on-secondary-container":"#1d3989","primary-fixed":"#d6e3fe","surface-variant":"#dae2fd","surface-tint":"#525f75","on-secondary":"#ffffff","inverse-on-surface":"#eef0ff","inverse-surface":"#283044","secondary-fixed":"#dce1ff","primary-fixed-dim":"#bac7e1","primary":"#000000","error-container":"#ffdad6","on-background":"#131b2e","on-tertiary-container":"#c76c00","on-secondary-fixed-variant":"#264191","surface-container-lowest":"#ffffff","surface-container-low":"#f2f3ff","on-tertiary-fixed":"#2f1500","surface-bright":"#faf8ff","surface-container":"#eaedff","tertiary":"#000000","surface-container-highest":"#dae2fd","secondary-container":"#8fa7fe","tertiary-fixed-dim":"#ffb77d","tertiary-container":"#2f1500","on-tertiary":"#ffffff","surface-container-high":"#e2e7ff","background":"#faf8ff","tertiary-fixed":"#ffdcc3","surface":"#faf8ff","on-tertiary-fixed-variant":"#6e3900","on-error-container":"#93000a","on-primary-fixed-variant":"#3a475c"},"borderRadius":{"DEFAULT":"0.125rem","lg":"0.25rem","xl":"0.5rem","full":"0.75rem"},"spacing":{"margin-lg":"3rem","gutter":"1rem","space-lg":"1.5rem","margin-md":"2rem","space-xs":"0.25rem","gutter-md":"1.5rem","margin":"1rem","space-sm":"0.5rem","space-xl":"2.5rem","space-md":"1rem","gutter-lg":"2rem"},"fontFamily":{"label-sm":["Inter"],"body-md":["Inter"],"headline-xl":["Inter"],"title-md":["Inter"],"title-sm":["Inter"],"headline-sm":["Inter"],"body-sm":["Inter"],"headline-md":["Inter"],"headline-lg":["Inter"],"body-lg":["Inter"],"label-md":["Inter"],"headline-xl-mobile":["Inter"],"headline-lg-mobile":["Inter"]},"fontSize":{"label-sm":["11px",{"lineHeight":"14px","fontWeight":"500"}],"body-md":["14px",{"lineHeight":"22px","fontWeight":"400"}],"headline-xl":["36px",{"lineHeight":"44px","fontWeight":"700"}],"title-md":["16px",{"lineHeight":"22px","fontWeight":"600"}],"title-sm":["14px",{"lineHeight":"20px","fontWeight":"600"}],"headline-sm":["18px",{"lineHeight":"24px","fontWeight":"600"}],"body-sm":["13px",{"lineHeight":"18px","fontWeight":"400"}],"headline-md":["22px",{"lineHeight":"28px","fontWeight":"600"}],"headline-lg":["28px",{"lineHeight":"36px","fontWeight":"700"}],"body-lg":["16px",{"lineHeight":"26px","fontWeight":"400"}],"label-md":["12px",{"lineHeight":"16px","fontWeight":"600"}],"headline-xl-mobile":["28px",{"lineHeight":"36px","fontWeight":"700"}],"headline-lg-mobile":["24px",{"lineHeight":"32px","fontWeight":"600"}]}}}}`;

/** Nav icon: Material Symbol name per route */
const NAV_ICON: Record<string, string> = {
  pencarian:         'find_in_page',
  jadwal:            'event_available',
  'tambah-peraturan':'post_add',
  'kelola-akun':     'manage_accounts',
};

export function Layout({ title, activeNav, user, children }: LayoutProps) {
  const isGuest = user.peran === 'Tamu';
  const profile = PERAN_PROFILE[user.peran] ?? { name: user.username, subtitle: user.peran };
  const isDefaultRoleUsername =
    isGuest || user.username.toLowerCase() === user.peran.toLowerCase();
  const displayName = isDefaultRoleUsername ? profile.name : user.username;
  const displayRole = isDefaultRoleUsername ? profile.subtitle : profile.name;

  /* Helper: active / inactive nav item classes */
  const navCls = (key: string) =>
    activeNav === key
      ? 'flex items-center gap-space-md px-space-md py-3 transition-colors bg-secondary text-on-secondary rounded'
      : 'flex items-center gap-space-md px-space-md py-3 text-on-primary-container hover:bg-white/10 hover:text-on-primary transition-colors rounded';

  return (
    <html lang="id">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{title} - P3H Kanwil Kementerian Hukum Kalsel</title>
        <link rel="icon" type="image/png" href="/images/logo.png" />
        {/* Material Symbols */}
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet" />
        {/* Inter font */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap" rel="stylesheet" />
        {/* Tailwind CDN */}
        <script src="https://cdn.tailwindcss.com"></script>
        <script id="tailwind-config" dangerouslySetInnerHTML={{ __html: `tailwind.config=${TAILWIND_CONFIG.replace('tailwind.config=','')}` }}></script>
        {/* Base reset + scrollbar hide */}
        <style dangerouslySetInnerHTML={{ __html: `
          @layer base{html,body{margin:0;padding:0;}body{overscroll-behavior:none;}}
          ::-webkit-scrollbar{display:none;}
          /* Keep legacy page-content CSS working */
          .content-body{width:100%;padding:1.5rem 2rem;display:flex;flex-direction:column;gap:1.5rem;}
        `}}></style>
        {/* Legacy page CSS (search results, tables, modals, etc.) */}
        <link rel="stylesheet" href="/css/style.css" />
        {/* HTMX */}
        <script src="https://unpkg.com/htmx.org@1.9.10" integrity="sha384-D1Kt99CQMDuVetoL1lrYwg5t+9QdHe7NLX/SoJYkXDFfX37iInKRy5xLSi8nO7UC" crossOrigin="anonymous"></script>
      </head>
      <body class="bg-surface font-body-md text-on-surface antialiased">

        {/* ── Sidebar ── */}
        <aside class="fixed left-0 top-0 h-full w-80 bg-primary-container text-on-primary border-r border-outline/20 z-50 flex flex-col">

          {/* Brand header */}
          <div class="h-16 px-space-md border-b border-white/10 flex items-center gap-space-sm flex-shrink-0">
            <img src="/images/logo.png" alt="Logo Pengayoman" class="w-10 h-10 object-contain rounded-lg flex-shrink-0" />
            <div class="flex flex-col min-w-0 leading-tight">
              <span class="text-[18px] font-bold text-on-primary tracking-tight truncate">Kementerian Hukum</span>
              <span class="text-[13px] text-[#94a3b8] font-medium tracking-normal truncate">Kalimantan Selatan</span>
            </div>
          </div>

          {/* Section label */}
          <div class="px-space-md pt-space-md pb-space-xs flex-shrink-0">
            <span class="text-[11px] uppercase tracking-widest text-on-primary-container font-bold">Menu Yuridis</span>
          </div>

          {/* Nav links — flex:1 so footer sticks to bottom */}
          <nav class="flex flex-col px-space-md gap-space-xs flex-1 overflow-hidden">
            <a href="/pencarian" class={navCls('pencarian')}>
              <span class="material-symbols-outlined text-[22px]">{NAV_ICON['pencarian']}</span>
              <span class="text-[15px] font-semibold">Pencarian Pasal</span>
            </a>

            {!isGuest && (
              <a href="/jadwal" class={navCls('jadwal')}>
                <span class="material-symbols-outlined text-[22px]">{NAV_ICON['jadwal']}</span>
                <span class="text-[15px] font-semibold">Jadwal Harmonisasi</span>
              </a>
            )}

            {(user.peran === 'Pengelola' || user.peran === 'Admin') && (
              <a href="/tambah-peraturan" class={navCls('tambah-peraturan')}>
                <span class="material-symbols-outlined text-[22px]">{NAV_ICON['tambah-peraturan']}</span>
                <span class="text-[15px] font-semibold">Tambah Peraturan</span>
              </a>
            )}

            {user.peran === 'Admin' && (
              <a href="/kelola-akun" class={navCls('kelola-akun')}>
                <span class="material-symbols-outlined text-[22px]">{NAV_ICON['kelola-akun']}</span>
                <span class="text-[15px] font-semibold">Kelola Akun</span>
              </a>
            )}
          </nav>

          {/* Profile footer — always visible */}
          <div class="px-space-md py-space-md border-t border-white/10 flex-shrink-0">
            <div class="flex items-center gap-space-sm">
              <div class="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
                <span class="material-symbols-outlined text-[18px] text-on-primary-container">person</span>
              </div>
              <div class="flex flex-col min-w-0">
                <span class="text-[14px] font-semibold text-on-primary truncate leading-tight">{displayName}</span>
                <span class="text-[11px] text-on-primary-container truncate leading-tight">{displayRole}</span>
              </div>
            </div>
          </div>
        </aside>

        {/* ── Main area ── */}
        <div class="pl-80">

          {/* Top bar */}
          <header class="fixed top-0 left-80 right-0 h-16 bg-surface-container-lowest border-b border-outline-variant z-40 px-space-lg flex items-center justify-between">
            <h1 class="text-[18px] font-bold text-[#0b192c] tracking-tight uppercase">{title.toUpperCase()}</h1>

            <div class="flex items-center gap-space-md">
              {/* Role badge */}
              <div class="flex items-center gap-2 px-3 py-1.5 bg-[#0b192c] text-white rounded-lg flex-shrink-0">
                <span class="material-symbols-outlined text-[18px] text-white flex-shrink-0">person</span>
                <div class="flex flex-col min-w-0 text-left leading-tight">
                  <span class="text-[13px] font-semibold text-white truncate">{displayName}</span>
                  <span class="text-[11px] text-[#94a3b8] leading-none truncate">{displayRole}</span>
                </div>
              </div>

              {/* Masuk / Keluar */}
              {isGuest ? (
                <a href="/login" class="h-9 px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1 transition-colors rounded-lg hover:bg-surface-container-high">
                  <span class="material-symbols-outlined text-[18px]">login</span>
                  <span>Masuk</span>
                </a>
              ) : (
                <a href="/logout" class="h-9 px-space-md bg-surface-container text-on-surface border border-outline-variant font-semibold text-[13px] flex items-center gap-1 transition-colors rounded-lg hover:bg-surface-container-high">
                  <span class="material-symbols-outlined text-[18px]">logout</span>
                  <span>Keluar</span>
                </a>
              )}
            </div>
          </header>

          {/* Page content */}
          <main class="w-full pt-16 bg-surface min-h-screen">
            <div class="content-body">
              {children}
            </div>
          </main>
        </div>

      </body>
    </html>
  );
}
