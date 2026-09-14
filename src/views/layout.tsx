import { jsx } from 'hono/jsx';
import { UserSession } from '../middleware/auth.js';

interface LayoutProps {
  title: string;
  activeNav: 'pencarian' | 'jadwal' | 'kelola-akun' | 'tambah-peraturan';
  user: UserSession;
  children: any;
}

export function Layout({ title, activeNav, user, children }: LayoutProps) {
  const isGuest = user.peran === 'Tamu';

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
          {/* Sidebar */}
          <aside class="sidebar">
            <div class="sidebar-header">
              <img src="/images/logo.png" alt="Logo Pengayoman" class="sidebar-logo" />
              <div class="sidebar-title">
                <h1>Kementerian Hukum</h1>
                <span>Kalimantan Selatan</span>
              </div>
            </div>

            <ul class="nav-list">
              <li class={`nav-item ${activeNav === 'pencarian' ? 'active' : ''}`}>
                <a href="/pencarian">
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                  </svg>
                  Pencarian Pasal
                </a>
              </li>

              {!isGuest && (
                <li class={`nav-item ${activeNav === 'jadwal' ? 'active' : ''}`}>
                  <a href="/jadwal">
                    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                    </svg>
                    Jadwal Harmonisasi
                  </a>
                </li>
              )}

              {user.peran === 'Pengelola' && (
                <li class={`nav-item ${activeNav === 'tambah-peraturan' ? 'active' : ''}`}>
                  <a href="/tambah-peraturan">
                    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                    </svg>
                    Tambah Peraturan
                  </a>
                </li>
              )}

              {user.peran === 'Admin' && (
                <li class={`nav-item ${activeNav === 'kelola-akun' ? 'active' : ''}`}>
                  <a href="/kelola-akun">
                    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                    </svg>
                    Kelola Akun (Admin)
                  </a>
                </li>
              )}
            </ul>

            <div class="sidebar-footer">
              <div class="user-profile">
                <div class="user-info">
                  <span class="user-name">{isGuest ? 'Tamu / Publik' : user.username}</span>
                  <span class="user-role" style={isGuest ? 'background-color: #475569; color: #fff;' : ''}>
                    {isGuest ? 'Mode Tamu' : user.peran}
                  </span>
                </div>
                {isGuest ? (
                  <a href="/login" class="btn-logout" style="background-color: var(--gold-accent); color: #000; font-weight: 700;" title="Login sebagai Petugas">Masuk</a>
                ) : (
                  <a href="/logout" class="btn-logout" title="Keluar dari sistem">Keluar</a>
                )}
              </div>
            </div>
          </aside>

          {/* Main Content Area */}
          <main class="main-content">
            <header class="top-bar">
              <h2 class="top-bar-title">{title}</h2>
              {isGuest && (
                <div class="top-bar-badge" style="background-color: #e2e8f0; color: #334155; border: 1px solid #cbd5e1;">
                  Mode Tamu (Akses Publik)
                </div>
              )}
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
