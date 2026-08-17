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
        <title>Login - P3H Kanwil Kemenkumham Kalsel</title>
        <link rel="stylesheet" href="/css/style.css" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body>
        <div class="login-container">
          <div class="login-card">
            <div class="login-logo">P3H</div>
            <div class="login-title">
              <h2>Sistem Pencarian Pasal</h2>
              <p>Divisi P3H Kanwil Kemenkumham Kalsel</p>
            </div>

            {error && (
              <div class="alert alert-danger">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                <span>{error}</span>
              </div>
            )}

            <form action="/login" method="post">
              <div class="form-group">
                <label for="username">Username</label>
                <input
                  type="text"
                  id="username"
                  name="username"
                  class="form-control"
                  placeholder="Masukkan username"
                  required
                  autofocus
                />
              </div>

              <div class="form-group">
                <label for="kata_sandi">Kata Sandi</label>
                <input
                  type="password"
                  id="kata_sandi"
                  name="kata_sandi"
                  class="form-control"
                  placeholder="Masukkan kata sandi"
                  required
                />
              </div>

              <button type="submit" class="btn-search" style="width: 100%; justify-content: center; margin-top: 1.5rem;">
                Masuk ke Aplikasi
              </button>
            </form>

            <div style="margin-top: 2rem; padding-top: 1.25rem; border-top: 1px solid var(--border-color); text-align: center; font-size: 0.8rem; color: var(--text-muted);">
              Hak Cipta &copy; 2026 Divisi P3H Kanwil Kemenkumham Kalsel
            </div>
          </div>
        </div>
      </body>
    </html>
  );
}
