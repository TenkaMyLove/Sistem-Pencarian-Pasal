import { jsx } from 'hono/jsx';
import { UserSession } from '../middleware/auth.js';

interface LayoutProps {
  title: string;
  activeNav: 'pencarian' | 'jadwal' | 'kelola-akun';
  user: UserSession;
  children: any;
}

export function Layout({ title, activeNav, user, children }: LayoutProps) {
  return (
    <html lang="id">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{title} - P3H Kanwil Kemenkumham Kalsel</title>
        <link rel="stylesheet" href="/css/style.css" />
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
              <div class="sidebar-logo">P3H</div>
              <div class="sidebar-title">
                <h1>Kanwil Kemenkumham</h1>
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

              <li class={`nav-item ${activeNav === 'jadwal' ? 'active' : ''}`}>
                <a href="/jadwal">
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                  </svg>
                  Jadwal Harmonisasi
                </a>
              </li>

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
                  <span class="user-name">{user.username}</span>
                  <span class="user-role">{user.peran}</span>
                </div>
                <a href="/logout" class="btn-logout" title="Keluar dari sistem">Keluar</a>
              </div>
            </div>
          </aside>

          {/* Main Content Area */}
          <main class="main-content">
            <header class="top-bar">
              <h2 class="top-bar-title">{title}</h2>
              <div class="top-bar-badge">
                Sistem Harmonisasi Ranperda Kalsel
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
