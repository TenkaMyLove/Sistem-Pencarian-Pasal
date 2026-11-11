import { Hono } from 'hono';
import { query } from '../db/index.js';
import { allowGuestOrAuth, requirePengelola, Env } from '../middleware/auth.js';
import { SearchView, SearchResultsPartial, SearchResultItem, StatusDetailModal, EditPasalModal } from '../views/search.js';

export const searchRoutes = new Hono<Env>();

searchRoutes.use('*', allowGuestOrAuth);

export interface PaginatedSearchResults {
  items: SearchResultItem[];
  totalCount: number;
  currentPage: number;
  pageSize: number;
  totalPages: number;
}

async function fetchSearchResults(
  q: string = '',
  sektor: string = '',
  wilayah: string = '',
  page: number = 1,
  pageSize: number = 5
): Promise<PaginatedSearchResults> {
  const currentPage = Math.max(1, page);
  const offset = (currentPage - 1) * pageSize;

  const params: any[] = [];

  // Build WHERE clause for filter conditions only (sektor/wilayah)
  let filterWhere = '';
  if (sektor.trim()) {
    filterWhere += ` AND per.sektor = ?`;
    params.push(sektor.trim());
  }
  if (wilayah.trim()) {
    filterWhere += ` AND per.wilayah = ?`;
    params.push(wilayah.trim());
  }

  // We use UNION of two queries:
  // Q1: pasal-level match (JOIN pasal — for content search)
  // Q2: peraturan-level match with no pasal (LEFT JOIN, IS NULL — for newly added regulations)
  // Both apply sektor/wilayah filters.

  let q1Where = '';
  let q2Where = '';
  const q1Params: any[] = [...params];
  const q2Params: any[] = [...params];

  if (q.trim()) {
    const likeVal = `%${q.trim()}%`;
    q1Where = ` AND (pas.teks_pasal LIKE ? OR pas.nomor_pasal LIKE ? OR per.judul LIKE ? OR per.jenis_peraturan LIKE ? OR per.nomor LIKE ?)`;
    q1Params.push(likeVal, likeVal, likeVal, likeVal, likeVal);

    // Q2: peraturan without pasal — only match by judul/jenis/nomor
    q2Where = ` AND (per.judul LIKE ? OR per.jenis_peraturan LIKE ? OR per.nomor LIKE ?)`;
    q2Params.push(likeVal, likeVal, likeVal);
  }

  const selectFields = `
    pas.id AS pasal_id,
    COALESCE(pas.nomor_pasal, '—') AS nomor_pasal,
    COALESCE(pas.nomor_ayat, '') AS nomor_ayat,
    COALESCE(pas.teks_pasal, '(Belum ada teks pasal — peraturan berhasil diindeks tetapi isi pasal belum berhasil diekstrak. Kunjungi dokumen asli untuk membaca isinya.)') AS teks_pasal,
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
    per.status_tautan`;

  // Q1: has pasal (INNER JOIN)
  const q1 = `SELECT ${selectFields}
    FROM pasal pas
    JOIN peraturan per ON pas.peraturan_id = per.id
    WHERE 1=1${filterWhere}${q1Where}`;

  // Q2: peraturan with no pasal at all (LEFT JOIN, pasal IS NULL)
  const q2 = `SELECT ${selectFields}
    FROM peraturan per
    LEFT JOIN pasal pas ON pas.peraturan_id = per.id
    WHERE pas.id IS NULL${filterWhere}${q2Where}`;

  const unionSql = `(${q1}) UNION ALL (${q2})`;
  const unionParams = [...q1Params, ...q2Params];

  // 1. Total count
  const countSql = `SELECT COUNT(*) AS total FROM (${unionSql}) AS combined`;
  const countRes = await query<{ total: string }>(countSql, unionParams);
  const totalCount = parseInt(countRes[0]?.total || '0', 10);
  const totalPages = Math.ceil(totalCount / pageSize) || 1;

  // 2. Paginated items
  const itemsSql = `SELECT * FROM (${unionSql}) AS combined ORDER BY tahun DESC, peraturan_id DESC, pasal_id ASC LIMIT ? OFFSET ?`;
  const itemParams = [...unionParams, pageSize, offset];
  const items = await query<SearchResultItem>(itemsSql, itemParams);

  return {
    items,
    totalCount,
    currentPage,
    pageSize,
    totalPages,
  };
}
async function getFilterLists() {
  const sektorRows = await query<{ sektor: string }>('SELECT DISTINCT sektor FROM peraturan WHERE sektor IS NOT NULL AND sektor != \'\' ORDER BY sektor ASC');
  const wilayahRows = await query<{ wilayah: string }>('SELECT DISTINCT wilayah FROM peraturan WHERE wilayah IS NOT NULL AND wilayah != \'\' ORDER BY wilayah ASC');

  return {
    sektorList: sektorRows.map((r) => r.sektor),
    wilayahList: wilayahRows.map((r) => r.wilayah),
  };
}

// GET / or GET /pencarian
searchRoutes.get('/pencarian', async (c) => {
  const user = c.get('user');
  const q = c.req.query('q') || '';
  const sektor = c.req.query('sektor') || '';
  const wilayah = c.req.query('wilayah') || '';
  const page = parseInt(c.req.query('page') || '1', 10);

  const searchData = await fetchSearchResults(q, sektor, wilayah, page, 5);
  const { sektorList, wilayahList } = await getFilterLists();

  return c.html(
    <SearchView
      user={user}
      initialQuery={q}
      searchData={searchData}
      sektorList={sektorList}
      wilayahList={wilayahList}
    />
  );
});

searchRoutes.get('/', (c) => c.redirect('/pencarian'));

// GET /search-results (HTMX partial response with pagination)
searchRoutes.get('/search-results', async (c) => {
  const q = c.req.query('q') || '';
  const sektor = c.req.query('sektor') || '';
  const wilayah = c.req.query('wilayah') || '';
  const page = parseInt(c.req.query('page') || '1', 10);

  const searchData = await fetchSearchResults(q, sektor, wilayah, page, 5);
  const user = c.get('user');

  return c.html(<SearchResultsPartial query={q} sektor={sektor} wilayah={wilayah} searchData={searchData} user={user} />);
});

// GET /pencarian/status-modal/:peraturan_id
searchRoutes.get('/pencarian/status-modal/:peraturan_id', async (c) => {
  const regId = parseInt(c.req.param('peraturan_id'), 10);
  const rows = await query<SearchResultItem>('SELECT * FROM peraturan WHERE id = ?', [regId]);

  if (!rows || rows.length === 0) {
    return c.text('Peraturan tidak ditemukan', 404);
  }

  return c.html(<StatusDetailModal peraturan={rows[0]} />);
});

// GET /pencarian/edit-pasal-modal/:pasal_id — Pengelola/Admin only
searchRoutes.get('/pencarian/edit-pasal-modal/:pasal_id', requirePengelola, async (c) => {
  const pasalId = parseInt(c.req.param('pasal_id') ?? '0', 10);
  const rows = await query<any>('SELECT * FROM pasal WHERE id = ?', [pasalId]);

  if (!rows || rows.length === 0) {
    return c.text('Pasal tidak ditemukan', 404);
  }

  return c.html(<EditPasalModal pasal={rows[0]} />);
});

// POST /pencarian/edit-pasal/:pasal_id — Pengelola/Admin only
searchRoutes.post('/pencarian/edit-pasal/:pasal_id', requirePengelola, async (c) => {
  const pasalId = parseInt(c.req.param('pasal_id') ?? '0', 10);
  const body = await c.req.parseBody();
  const nomor_pasal = (body['nomor_pasal'] as string || '').trim();
  const nomor_ayat  = (body['nomor_ayat']  as string || '').trim();
  const teks_pasal  = (body['teks_pasal']  as string || '').trim();

  if (!nomor_pasal || !teks_pasal) {
    return c.text('Nomor pasal dan teks pasal tidak boleh kosong', 400);
  }

  await query(
    'UPDATE pasal SET nomor_pasal = ?, nomor_ayat = ?, teks_pasal = ? WHERE id = ?',
    [nomor_pasal, nomor_ayat, teks_pasal, pasalId]
  );

  // Return HTMX trigger to close modal and refresh results
  return c.html(
    <div id="edit-success-toast" hx-swap-oob="true">
      <span style="display:none" id="close-edit-modal" data-close="true"></span>
    </div>,
    200,
    {
      'HX-Trigger': JSON.stringify({ closeEditModal: pasalId, refreshResults: true }),
    }
  );
});

// POST /pencarian/hapus-pasal/:pasal_id — Pengelola/Admin only
searchRoutes.post('/pencarian/hapus-pasal/:pasal_id', requirePengelola, async (c) => {
  const pasalId = parseInt(c.req.param('pasal_id') ?? '0', 10);

  const rows = await query<any>('SELECT id FROM pasal WHERE id = ?', [pasalId]);
  if (!rows || rows.length === 0) {
    return c.text('Pasal tidak ditemukan', 404);
  }

  await query('DELETE FROM pasal WHERE id = ?', [pasalId]);

  return c.html(
    <div style="display:none"></div>,
    200,
    { 'HX-Trigger': JSON.stringify({ pasalDeleted: pasalId }) }
  );
});
