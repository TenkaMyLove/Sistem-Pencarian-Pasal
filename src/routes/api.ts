import { Hono } from 'hono';
import { cors } from 'hono/cors';
import bcrypt from 'bcryptjs';
import { query } from '../db/index.js';
import { crawlFromUrl } from '../scraper/urlCrawler.js';

export const apiRoutes = new Hono();

// Enable CORS for web and mobile clients
apiRoutes.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

// 1. Health check
apiRoutes.get('/health', (c) => {
  return c.json({
    success: true,
    status: 'ok',
    app: 'P3H Kemenkum Kalsel Mobile API',
    timestamp: new Date().toISOString(),
  });
});

// 2. Auth Login
apiRoutes.post('/auth/login', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const username = String(body.username || '').trim();
    const kata_sandi = String(body.kata_sandi || '').trim();

    if (!username || !kata_sandi) {
      return c.json({ success: false, message: 'Username dan kata sandi wajib diisi' }, 400);
    }

    const users = await query<any>(
      'SELECT id, username, kata_sandi_terenkripsi, peran FROM pengguna WHERE LOWER(username) = LOWER(?)',
      [username]
    );

    if (users.length === 0) {
      return c.json({ success: false, message: 'Username atau kata sandi salah' }, 401);
    }

    const user = users[0];
    const passwordValid = await bcrypt.compare(kata_sandi, user.kata_sandi_terenkripsi);

    if (!passwordValid) {
      return c.json({ success: false, message: 'Username atau kata sandi salah' }, 401);
    }

    return c.json({
      success: true,
      message: 'Login berhasil',
      user: {
        id: user.id,
        username: user.username,
        peran: user.peran,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Internal server error' }, 500);
  }
});

// 3. Search & Filter Peraturan / Pasal
apiRoutes.get('/search', async (c) => {
  try {
    const q = (c.req.query('q') || '').trim();
    const sektor = (c.req.query('sektor') || '').trim();
    const wilayah = (c.req.query('wilayah') || '').trim();
    const page = Math.max(1, parseInt(c.req.query('page') || '1', 10));
    const pageSize = Math.min(50, Math.max(1, parseInt(c.req.query('pageSize') || '10', 10)));
    const offset = (page - 1) * pageSize;

    let baseWhere = ' FROM pasal pas JOIN peraturan per ON pas.peraturan_id = per.id WHERE 1=1';
    const params: any[] = [];

    if (q) {
      baseWhere += ` AND (
        pas.teks_pasal LIKE ? OR
        pas.nomor_pasal LIKE ? OR
        per.judul LIKE ? OR
        per.jenis_peraturan LIKE ? OR
        per.nomor LIKE ?
      )`;
      const likeVal = `%${q}%`;
      params.push(likeVal, likeVal, likeVal, likeVal, likeVal);
    }

    if (sektor) {
      baseWhere += ` AND per.sektor = ?`;
      params.push(sektor);
    }

    if (wilayah) {
      baseWhere += ` AND per.wilayah = ?`;
      params.push(wilayah);
    }

    // Total Count
    const countSql = `SELECT COUNT(*) AS total` + baseWhere;
    const countRes = await query<{ total: string }>(countSql, params);
    const totalCount = parseInt(countRes[0]?.total || '0', 10);
    const totalPages = Math.ceil(totalCount / pageSize) || 1;

    // Items
    const itemsSql = `
      SELECT 
        pas.id AS pasal_id,
        pas.nomor_pasal,
        pas.nomor_ayat,
        pas.teks_pasal,
        per.id AS peraturan_id,
        per.jenis_peraturan,
        per.nomor,
        per.tahun,
        per.judul,
        per.status,
        per.status_detail,
        per.status_detail_json,
        per.wilayah,
        per.sektor,
        per.url_dokumen_asli,
        per.status_tautan
      ` + baseWhere + ` ORDER BY per.tahun DESC, per.id DESC, pas.id ASC LIMIT ? OFFSET ?;`;

    const items = await query(itemsSql, [...params, pageSize, offset]);

    // Available filters
    const sektorRows = await query<{ sektor: string }>('SELECT DISTINCT sektor FROM peraturan WHERE sektor IS NOT NULL AND sektor != \'\' ORDER BY sektor ASC');
    const wilayahRows = await query<{ wilayah: string }>('SELECT DISTINCT wilayah FROM peraturan WHERE wilayah IS NOT NULL AND wilayah != \'\' ORDER BY wilayah ASC');

    return c.json({
      success: true,
      data: {
        items,
        totalCount,
        currentPage: page,
        pageSize,
        totalPages,
        filters: {
          sektorList: sektorRows.map((r) => r.sektor),
          wilayahList: wilayahRows.map((r) => r.wilayah),
        },
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memuat hasil pencarian' }, 500);
  }
});

// 4. Detail Peraturan & Semua Pasalnya
apiRoutes.get('/peraturan/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'), 10);
    const peraturanRows = await query('SELECT * FROM peraturan WHERE id = ?', [id]);
    if (peraturanRows.length === 0) {
      return c.json({ success: false, message: 'Peraturan tidak ditemukan' }, 404);
    }

    const peraturan = peraturanRows[0];
    const pasalRows = await query('SELECT * FROM pasal WHERE peraturan_id = ? ORDER BY id ASC', [id]);

    return c.json({
      success: true,
      data: {
        peraturan,
        pasalList: pasalRows,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memuat data peraturan' }, 500);
  }
});

// 5. Jadwal Rapat Harmonisasi CRUD
apiRoutes.get('/jadwal', async (c) => {
  try {
    const items = await query(`
      SELECT id, jenis_rancangan, tentang, tanggal, jam, nama_kompilator, tim_pokja, dibuat_oleh
      FROM jadwal_rapat_harmonisasi
      ORDER BY tanggal ASC, jam ASC;
    `);
    return c.json({ success: true, data: items });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memuat jadwal' }, 500);
  }
});

apiRoutes.post('/jadwal', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const { jenis_rancangan, tentang, tanggal, jam, nama_kompilator, tim_pokja, dibuat_oleh } = body;

    if (!jenis_rancangan || !tentang || !tanggal || !jam) {
      return c.json({ success: false, message: 'Kolom jenis, tentang, tanggal, dan jam wajib diisi' }, 400);
    }

    const res: any = await query(`
      INSERT INTO jadwal_rapat_harmonisasi (jenis_rancangan, tentang, tanggal, jam, nama_kompilator, tim_pokja, dibuat_oleh)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    `, [
      jenis_rancangan,
      tentang,
      tanggal,
      jam,
      nama_kompilator || '',
      tim_pokja || '',
      dibuat_oleh || 'Pengguna',
    ]);

    return c.json({
      success: true,
      message: 'Jadwal berhasil ditambahkan',
      insertedId: res?.insertId,
    }, 201);
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal menambahkan jadwal' }, 500);
  }
});

apiRoutes.put('/jadwal/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'), 10);
    const body = await c.req.json().catch(() => ({}));
    const { jenis_rancangan, tentang, tanggal, jam, nama_kompilator, tim_pokja } = body;

    await query(`
      UPDATE jadwal_rapat_harmonisasi
      SET jenis_rancangan = ?, tentang = ?, tanggal = ?, jam = ?, nama_kompilator = ?, tim_pokja = ?
      WHERE id = ?;
    `, [jenis_rancangan, tentang, tanggal, jam, nama_kompilator, tim_pokja, id]);

    return c.json({ success: true, message: 'Jadwal berhasil diperbarui' });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memperbarui jadwal' }, 500);
  }
});

apiRoutes.delete('/jadwal/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'), 10);
    await query('DELETE FROM jadwal_rapat_harmonisasi WHERE id = ?;', [id]);
    return c.json({ success: true, message: 'Jadwal berhasil dihapus' });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal menghapus jadwal' }, 500);
  }
});

// 6. Admin User Management
apiRoutes.get('/admin/users', async (c) => {
  try {
    const users = await query(`
      SELECT id, username, peran, diubah_terakhir_oleh, tanggal_kata_sandi_diubah
      FROM pengguna ORDER BY id ASC;
    `);
    return c.json({ success: true, data: users });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memuat pengguna' }, 500);
  }
});

apiRoutes.post('/admin/reset-password', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const { target_username, kata_sandi_baru, admin_username } = body;

    if (!target_username || !kata_sandi_baru) {
      return c.json({ success: false, message: 'Target username dan kata sandi baru wajib diisi' }, 400);
    }

    if (kata_sandi_baru.length < 6) {
      return c.json({ success: false, message: 'Kata sandi minimal 6 karakter' }, 400);
    }

    const hashed = await bcrypt.hash(kata_sandi_baru, 10);
    await query(`
      UPDATE pengguna
      SET kata_sandi_terenkripsi = ?, diubah_terakhir_oleh = ?, tanggal_kata_sandi_diubah = NOW()
      WHERE username = ?;
    `, [hashed, admin_username || 'Admin', target_username]);

    return c.json({ success: true, message: `Kata sandi akun ${target_username} berhasil diperbarui` });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal mereset kata sandi' }, 500);
  }
});

// 7. Scraper / Tambah Peraturan
apiRoutes.post('/tambah-peraturan', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const { url, jenis_peraturan, nomor, tahun, judul, wilayah, sektor, teks_manual, ditambahkan_oleh } = body;

    if (!url || !jenis_peraturan || !nomor || !tahun) {
      return c.json({ success: false, message: 'URL, Jenis Peraturan, Nomor, dan Tahun wajib diisi' }, 400);
    }

    const result = await crawlFromUrl({
      url,
      jenis_peraturan,
      nomor,
      tahun: parseInt(String(tahun), 10),
      judul: judul || '',
      wilayah: wilayah || 'Nasional',
      sektor: sektor || 'Lainnya',
      ditambahkan_oleh: ditambahkan_oleh || 'Pengelola',
      teks_manual: teks_manual || undefined,
    });

    return c.json({ success: true, data: result });
  } catch (err: any) {
    return c.json({ success: false, message: err.message || 'Gagal memproses crawling peraturan' }, 500);
  }
});
