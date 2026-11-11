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

export function Layout({ title, activeNav, user, children }: LayoutProps) {
  const isGuest = user.peran === 'Tamu';
  const profile = PERAN_PROFILE[user.peran] ?? { name: user.username, subtitle: user.peran };
  const isDefaultRoleUsername =
    isGuest || user.username.toLowerCase() === user.peran.toLowerCase();
  const displayName = isDefaultRoleUsername ? profile.name : user.username;
  const displayRole = isDefaultRoleUsername ? profile.subtitle : profile.name;

  return (
    <html lang="id">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{title} - P3H Kanwil Kementerian Hukum Kalsel </title>
        <link rel="stylesheet" href="/css/style.css" />
        <link rel="icon" type="image/png" href="/images/logo.png" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
        <script src="https://unpkg.com/htmx.org@1.9.10" integrity="sha384-D1Kt99CQMDuVetoL1lrYwg5t+9QdHe7NLX/SoJYkXDFfX37iInKRy5xLSi8nO7UC" crossOrigin="anonymous"></script>
      </head>
      <body>
        <div class="app-container">
          {/* Sidebar — fixed height, profile always visible at bottom */}
          <aside class="sidebar">
            <div class="sidebar-header">
              <img src="/images/logo.png" alt="Logo Pengayoman" class="sidebar-logo" />
              <div class="sidebar-title">
                <h1>Kementerian Hukum</h1>
                <span>Kalimantan Selatan</span>
              </div>
            </div>

            <div class="nav-section-label">Menu Yuridis</div>

            <ul class="nav-list">
              <li class={`nav-item ${activeNav === 'pencarian' ? 'active' : ''}`}>
                <a href="/pencarian">
                  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                  </svg>
                  Pencarian Pasal
                </a>
              </li>

              {!isGuest && (
                <li class={`nav-item ${activeNav === 'jadwal' ? 'active' : ''}`}>
                  <a href="/jadwal">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                    </svg>
                    Jadwal Harmonisasi
                  </a>
                </li>
              )}

              {(user.peran === 'Pengelola' || user.peran === 'Admin') && (
                <li class={`nav-item ${activeNav === 'tambah-peraturan' ? 'active' : ''}`}>
                  <a href="/tambah-peraturan">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                    </svg>
                    Tambah Peraturan
                  </a>
                </li>
              )}

              {user.peran === 'Admin' && (
                <li class={`nav-item ${activeNav === 'kelola-akun' ? 'active' : ''}`}>
                  <a href="/kelola-akun">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                    </svg>
                    Kelola Akun
                  </a>
                </li>
              )}
            </ul>

            {/* Profile always pinned at bottom — no logout here, logout is in top bar */}
            <div class="sidebar-footer">
              <div class="user-profile">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" class="user-avatar-icon">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                <div class="user-info">
                  <span class="user-name">{displayName}</span>
                  <span class="user-role">{displayRole}</span>
                </div>
              </div>
            </div>
          </aside>

          {/* Main Content Area */}
          <main class="main-content">
            <header class="top-bar">
              <h2 class="top-bar-title">{title.toUpperCase()}</h2>
              <div class="top-bar-actions">
                {/* Role badge pill */}
                <div class="top-bar-badge">
                  <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <div class="top-bar-badge-text">
                    <span class="top-bar-badge-name">{displayName}</span>
                    <span class="top-bar-badge-sub">{displayRole}</span>
                  </div>
                </div>

                {/* Masuk / Keluar button */}
                {isGuest ? (
                  <a href="/login" class="btn btn-sm top-bar-btn">
                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"></path>
                    </svg>
                    Masuk
                  </a>
                ) : (
                  <a href="/logout" class="btn btn-sm top-bar-btn">
                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                    </svg>
                    Keluar
                  </a>
                )}
              </div>
            </header>

            <div class="content-body">
              {children}
            </div>
          </main>
        </div>
      </body>
    </html>
  );
}
