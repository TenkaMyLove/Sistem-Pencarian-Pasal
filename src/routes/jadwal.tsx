import { Hono } from 'hono';
import { query } from '../db/index.js';
import { requireAuth, getSession, Env } from '../middleware/auth.js';
import { JadwalView, JadwalTablePartial, JadwalModalPartial, JadwalItem } from '../views/jadwal.js';

export const jadwalRoutes = new Hono<Env>();

jadwalRoutes.use('*', requireAuth);

async function fetchJadwalList(): Promise<JadwalItem[]> {
  return await query<JadwalItem>(`
    SELECT id, jenis_rancangan, tanggal::text, jam::text, nama_kompilator, tim_pokja, dibuat_oleh
    FROM jadwal_rapat_harmonisasi
    ORDER BY tanggal ASC, jam ASC;
  `);
}

// GET /jadwal
jadwalRoutes.get('/jadwal', async (c) => {
  const user = c.get('user');
  const jadwalList = await fetchJadwalList();
  return c.html(<JadwalView user={user} jadwalList={jadwalList} />);
});

// GET /jadwal/modal/tambah (HTMX modal partial)
jadwalRoutes.get('/jadwal/modal/tambah', (c) => {
  const user = c.get('user');
  if (user.peran !== 'Pengelola') {
    return c.html('<div class="alert alert-danger">Akses ditolak: Hanya Pengelola yang dapat menambah jadwal.</div>', 403);
  }
  return c.html(<JadwalModalPartial />);
});

// GET /jadwal/modal/edit/:id (HTMX modal partial)
jadwalRoutes.get('/jadwal/modal/edit/:id', async (c) => {
  const user = c.get('user');
  if (user.peran !== 'Pengelola') {
    return c.html('<div class="alert alert-danger">Akses ditolak: Hanya Pengelola yang dapat mengubah jadwal.</div>', 403);
  }
  const id = parseInt(c.req.param('id'), 10);
  const rows = await query<JadwalItem>(`
    SELECT id, jenis_rancangan, tanggal::text, jam::text, nama_kompilator, tim_pokja, dibuat_oleh
    FROM jadwal_rapat_harmonisasi WHERE id = $1;
  `, [id]);

  if (rows.length === 0) {
    return c.html('<div class="alert alert-danger">Jadwal tidak ditemukan</div>', 404);
  }

  return c.html(<JadwalModalPartial editItem={rows[0]} />);
});

// POST /jadwal (Add Schedule - Pengelola only)
jadwalRoutes.post('/jadwal', async (c) => {
  const user = c.get('user');
  if (user.peran !== 'Pengelola') {
    return c.html('<div class="alert alert-danger">Akses ditolak</div>', 403);
  }

  const body = await c.req.parseBody();
  const jenis_rancangan = String(body.jenis_rancangan || '');
  const tanggal = String(body.tanggal || '');
  const jam = String(body.jam || '');
  const nama_kompilator = String(body.nama_kompilator || '');
  const tim_pokja = String(body.tim_pokja || '');

  await query(`
    INSERT INTO jadwal_rapat_harmonisasi (jenis_rancangan, tanggal, jam, nama_kompilator, tim_pokja, dibuat_oleh)
    VALUES ($1, $2, $3, $4, $5, $6);
  `, [jenis_rancangan, tanggal, jam, nama_kompilator, tim_pokja, user.username]);

  const jadwalList = await fetchJadwalList();
  return c.html(<JadwalTablePartial user={user} jadwalList={jadwalList} />);
});

// POST /jadwal/:id/edit (Update Schedule - Pengelola only)
jadwalRoutes.post('/jadwal/:id/edit', async (c) => {
  const user = c.get('user');
  if (user.peran !== 'Pengelola') {
    return c.html('<div class="alert alert-danger">Akses ditolak</div>', 403);
  }

  const id = parseInt(c.req.param('id'), 10);
  const body = await c.req.parseBody();
  const jenis_rancangan = String(body.jenis_rancangan || '');
  const tanggal = String(body.tanggal || '');
  const jam = String(body.jam || '');
  const nama_kompilator = String(body.nama_kompilator || '');
  const tim_pokja = String(body.tim_pokja || '');

  await query(`
    UPDATE jadwal_rapat_harmonisasi
    SET jenis_rancangan = $1, tanggal = $2, jam = $3, nama_kompilator = $4, tim_pokja = $5, updated_at = NOW()
    WHERE id = $6;
  `, [jenis_rancangan, tanggal, jam, nama_kompilator, tim_pokja, id]);

  const jadwalList = await fetchJadwalList();
  return c.html(<JadwalTablePartial user={user} jadwalList={jadwalList} />);
});

// POST /jadwal/:id/delete (Delete Schedule - Pengelola only)
jadwalRoutes.post('/jadwal/:id/delete', async (c) => {
  const user = c.get('user');
  if (user.peran !== 'Pengelola') {
    return c.html('<div class="alert alert-danger">Akses ditolak</div>', 403);
  }

  const id = parseInt(c.req.param('id'), 10);
  await query('DELETE FROM jadwal_rapat_harmonisasi WHERE id = $1;', [id]);

  const jadwalList = await fetchJadwalList();
  return c.html(<JadwalTablePartial user={user} jadwalList={jadwalList} />);
});
