import { Hono } from 'hono';
import bcrypt from 'bcryptjs';
import { query } from '../db/index.js';
import { requireAdmin, getSession, Env } from '../middleware/auth.js';
import { AdminView } from '../views/admin.js';

export const adminRoutes = new Hono<Env>();

adminRoutes.use('*', requireAdmin);

async function fetchUserAccounts() {
  return await query<{ username: string; peran: string; diubah_terakhir_oleh: string; tanggal_kata_sandi_diubah: string }>(`
    SELECT username, peran, diubah_terakhir_oleh, tanggal_kata_sandi_diubah::text
    FROM pengguna ORDER BY id ASC;
  `);
}

// GET /kelola-akun
adminRoutes.get('/kelola-akun', async (c) => {
  const user = c.get('user');
  const userAccounts = await fetchUserAccounts();
  return c.html(<AdminView user={user} userAccounts={userAccounts} />);
});

// POST /kelola-akun
adminRoutes.post('/kelola-akun', async (c) => {
  const user = c.get('user');
  const body = await c.req.parseBody();
  const target_username = String(body.target_username || '').trim();
  const kata_sandi_baru = String(body.kata_sandi_baru || '').trim();
  const konfirmasi_kata_sandi = String(body.konfirmasi_kata_sandi || '').trim();

  const userAccounts = await fetchUserAccounts();

  if (!target_username || !kata_sandi_baru || !konfirmasi_kata_sandi) {
    return c.html(
      <AdminView user={user} error="Seluruh kolom formulir wajib diisi." userAccounts={userAccounts} />,
      400
    );
  }

  if (target_username !== 'Pengelola' && target_username !== 'Perancang') {
    return c.html(
      <AdminView user={user} error="Hanya kata sandi akun Pengelola atau Perancang yang dapat diubah." userAccounts={userAccounts} />,
      400
    );
  }

  if (kata_sandi_baru.length < 6) {
    return c.html(
      <AdminView user={user} error="Kata sandi baru minimal harus 6 karakter." userAccounts={userAccounts} />,
      400
    );
  }

  if (kata_sandi_baru !== konfirmasi_kata_sandi) {
    return c.html(
      <AdminView user={user} error="Konfirmasi kata sandi baru tidak cocok." userAccounts={userAccounts} />,
      400
    );
  }

  // Hash new password & update DB
  const hashed = await bcrypt.hash(kata_sandi_baru, 10);
  await query(`
    UPDATE pengguna
    SET kata_sandi_terenkripsi = $1, diubah_terakhir_oleh = 'Admin', tanggal_kata_sandi_diubah = NOW()
    WHERE username = $2;
  `, [hashed, target_username]);

  const updatedAccounts = await fetchUserAccounts();

  return c.html(
    <AdminView
      user={user}
      message={`Kata sandi akun ${target_username} berhasil diperbarui! Pengguna akun tersebut kini dapat login dengan kata sandi baru.`}
      userAccounts={updatedAccounts}
    />
  );
});
