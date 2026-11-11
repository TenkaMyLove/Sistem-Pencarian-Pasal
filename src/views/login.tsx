import { jsx } from 'hono/jsx';

interface LoginProps {
  error?: string;
}

export function LoginView({ error }: LoginProps) {
  return (
    <html lang="id">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Masuk - P3H Kanwil Kementerian Hukum Kalsel</title>
        <link rel="stylesheet" href="/css/style.css" />
        <link rel="icon" type="image/png" href="/images/logo.png" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
      </head>
      <body>
        <div class="login-page">
          {/* Top navbar */}
          <header class="login-brand">
            <img src="/images/logo.png" alt="Logo Pengayoman" />
            <div>
              <h1>Kementerian Hukum Republik Indonesia</h1>
              <p>Kantor Wilayah Kalimantan Selatan &middot; Divisi Pelayanan Hukum dan HAM</p>
            </div>
            {/* Online indicator */}
            <div class="login-status-dot" title="Sistem Aktif"></div>
          </header>

          <main class="login-main">
            <div class="login-card">
              {/* Logo inside card */}
              <div class="login-card-logo">
                <img src="/images/logo.png" alt="Logo Pengayoman" />
              </div>

              <div class="login-title">
                <h2>Masuk Sistem</h2>
                <p>Portal Pencarian Pasal &amp; Harmonisasi Regulasi Daerah</p>
              </div>

              {error && (
                <div class="alert alert-danger" role="alert">
                  <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <span>{error}</span>
                </div>
              )}

              <form action="/login" method="post">
                {/* Username field with icon */}
                <div class="field">
                  <label for="username">Username / NIP Pegawai</label>
                  <div class="input-icon-wrap">
                    <svg class="input-icon" width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    <input
                      type="text"
                      id="username"
                      name="username"
                      class="input input-with-icon"
                      placeholder="pengelola"
                      autocomplete="username"
                      required
                      autofocus
                    />
                  </div>
                </div>

                {/* Password field with icon */}
                <div class="field">
                  <label for="kata_sandi">Kata Sandi</label>
                  <div class="input-icon-wrap">
                    <svg class="input-icon" width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                    </svg>
                    <input
                      type="password"
                      id="kata_sandi"
                      name="kata_sandi"
                      class="input input-with-icon"
                      placeholder="••••••••••"
                      autocomplete="current-password"
                      required
                    />
                  </div>
                </div>

                {/* Remember session */}
                <label class="check login-remember">
                  <input type="checkbox" name="remember" value="1" checked />
                  Ingat sesi login
                </label>

                <button type="submit" class="btn btn-primary btn-block login-submit">
                  Masuk ke Dashboard &rarr;
                </button>
              </form>

              <div class="divider">Masyarakat umum atau pemohon harmonisasi?</div>

              <a href="/tamu" class="btn btn-block btn-outline login-guest-btn">
                Akses Pencarian Pasal Publik Tanpa Login
              </a>
            </div>
          </main>

          <footer class="login-footer">
            <span>&copy; 2026 Kantor Wilayah Kementerian Hukum Kalimantan Selatan. Hak Cipta Dilindungi.</span>
            <span class="login-footer-addr">Jl. Brigjen H. Hasan Basry No. 49, Banjarmasin</span>
            <span class="login-footer-links">
              <a href="#">Panduan Sistem</a>
              <a href="#">Bantuan Teknis</a>
              <a href="#">Kebijakan Privasi</a>
            </span>
          </footer>
        </div>
      </body>
    </html>
  );
}
