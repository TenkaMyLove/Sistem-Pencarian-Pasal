import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';

interface AdminViewProps {
  user: UserSession;
  message?: string;
  error?: string;
  userAccounts: { username: string; peran: string; diubah_terakhir_oleh: string; tanggal_kata_sandi_diubah: string }[];
}

function Icon({ d, size = 18 }: { d: string; size?: number }) {
  return (
    <svg width={size} height={size} fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={d}></path>
    </svg>
  );
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
    <Layout title="Kelola Akun" activeNav="kelola-akun" user={user}>
      <div class="page-head">
        <div>
          <h2>Kelola Akun Pengguna</h2>
          <p>Perbarui kata sandi akun operasional Pengelola dan Perancang. Khusus Administrator.</p>
        </div>
      </div>

      {message && (
        <div class="alert alert-success" role="status">
          <Icon d="M5 13l4 4L19 7" size={20} />
          <span>{message}</span>
        </div>
      )}

      {error && (
        <div class="alert alert-danger" role="alert">
          <Icon d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" size={20} />
          <span>{error}</span>
        </div>
      )}

      <div class="split">
        <div class="panel">
          <div class="panel-head">
            <h3>Daftar Akun Sistem</h3>
          </div>

          <div class="table-wrap">
            <table class="data-table">
              <thead>
                <tr>
                  <th scope="col">Username</th>
                  <th scope="col">Peran</th>
                  <th scope="col">Diubah Oleh</th>
                  <th scope="col">Perubahan Terakhir</th>
                </tr>
              </thead>
              <tbody>
                {userAccounts.map((acc) => (
                  <tr>
                    <td class="cell-strong">{acc.username}</td>
                    <td><span class="tag tag-neutral">{acc.peran}</span></td>
                    <td>{acc.diubah_terakhir_oleh || 'System'}</td>
                    <td>{formatDate(acc.tanggal_kata_sandi_diubah)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <form class="panel" action="/kelola-akun" method="post">
          <div class="panel-head">
            <h3>Reset Kata Sandi</h3>
          </div>

          <div class="panel-pad">
            <div class="field">
              <label for="target_username">Nama Pengguna</label>
              <select id="target_username" name="target_username" class="select" required>
                <option value="Pengelola">Pengelola</option>
                <option value="Perancang">Perancang</option>
              </select>
            </div>

            <div class="field">
              <label for="kata_sandi_baru">Kata Sandi Baru</label>
              <input
                type="password"
                id="kata_sandi_baru"
                name="kata_sandi_baru"
                class="input"
                placeholder="Minimal 6 karakter"
                autocomplete="new-password"
                minlength={6}
                required
              />
            </div>

            <div class="field">
              <label for="konfirmasi_kata_sandi">Konfirmasi Kata Sandi Baru</label>
              <input
                type="password"
                id="konfirmasi_kata_sandi"
                name="konfirmasi_kata_sandi"
                class="input"
                placeholder="Ulangi kata sandi"
                autocomplete="new-password"
                minlength={6}
                required
              />
            </div>

            <button type="submit" class="btn btn-primary btn-block">
              <Icon d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
              Simpan Kata Sandi
            </button>
          </div>
        </form>
      </div>
    </Layout>
  );
}
