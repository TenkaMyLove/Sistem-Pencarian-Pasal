import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';

interface AdminViewProps {
  user: UserSession;
  message?: string;
  error?: string;
  userAccounts: { username: string; peran: string; diubah_terakhir_oleh: string; tanggal_kata_sandi_diubah: string }[];
}

export function AdminView({ user, message, error, userAccounts }: AdminViewProps) {
  const formatDate = (dateStr: string) => {
    try {
      const d = new Date(dateStr);
      return d.toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' });
    } catch {
      return dateStr || '-';
    }
  };

  return (
    <Layout title="Kelola Akun Pengguna (Admin)" activeNav="kelola-akun" user={user}>
      <div style="max-width: 800px; margin: 0 auto;">
        <div class="search-hero" style="margin-bottom: 2rem; padding: 2rem;">
          <h2>Menu Kelola Akun Tim Perancang & Pengelola</h2>
          <p>Fitur khusus Administrator Pengembang untuk memperbarui kata sandi akun operasional tim.</p>
        </div>

        {message && (
          <div class="alert alert-success">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span>{message}</span>
          </div>
        )}

        {error && (
          <div class="alert alert-danger">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span>{error}</span>
          </div>
        )}

        {/* Change Password Card */}
        <div class="result-card" style="margin-bottom: 2rem;">
          <h3 style="font-size: 1.15rem; font-weight: 700; color: var(--primary-navy); margin-bottom: 1rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.75rem;">
            Form Ganti Kata Sandi Akun
          </h3>

          <form action="/kelola-akun" method="post">
            <div class="form-group">
              <label for="target_username">Pilih Akun yang Ingin Diubah Kata Sandinya</label>
              <select id="target_username" name="target_username" class="form-control" required>
                <option value="Pengelola">Akun Pengelola (Hak Akses Penuh Schedule & Search)</option>
                <option value="Perancang">Akun Perancang (Hak Akses Read-Only Schedule & Search)</option>
              </select>
            </div>

            <div class="form-group">
              <label for="kata_sandi_baru">Kata Sandi Baru</label>
              <input
                type="password"
                id="kata_sandi_baru"
                name="kata_sandi_baru"
                class="form-control"
                placeholder="Masukkan kata sandi baru (minimal 6 karakter)"
                minlength={6}
                required
              />
            </div>

            <div class="form-group">
              <label for="konfirmasi_kata_sandi">Konfirmasi Kata Sandi Baru</label>
              <input
                type="password"
                id="konfirmasi_kata_sandi"
                name="konfirmasi_kata_sandi"
                class="form-control"
                placeholder="Ulangi kata sandi baru"
                minlength={6}
                required
              />
            </div>

            <button type="submit" class="btn-search" style="margin-top: 1.5rem;">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
              </svg>
              Simpan Kata Sandi Baru
            </button>
          </form>
        </div>

        {/* Status Accounts List */}
        <div class="card-table">
          <div class="table-header-bar">
            <h3>Status 3 Akun Pengguna Tetap Sistem</h3>
          </div>

          <table class="data-table">
            <thead>
              <tr>
                <th>Username</th>
                <th>Peran / Level Akses</th>
                <th>Diperbarui Oleh</th>
                <th>Terakhir Diubah</th>
              </tr>
            </thead>
            <tbody>
              {userAccounts.map((acc) => (
                <tr>
                  <td style="font-weight: 700; color: var(--primary-navy);">{acc.username}</td>
                  <td>
                    <span class={`badge ${acc.peran === 'Admin' ? 'badge-jenis' : acc.peran === 'Pengelola' ? 'badge-sektor' : 'badge-wilayah'}`}>
                      {acc.peran}
                    </span>
                  </td>
                  <td>{acc.diubah_terakhir_oleh || 'System'}</td>
                  <td>{formatDate(acc.tanggal_kata_sandi_diubah)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </Layout>
  );
}
