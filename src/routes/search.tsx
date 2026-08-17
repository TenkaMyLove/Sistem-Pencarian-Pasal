import { Hono } from 'hono';
import { query } from '../db/index.js';
import { requireAuth, Env } from '../middleware/auth.js';
import { SearchView, SearchResultsPartial, SearchResultItem, StatusDetailModal } from '../views/search.js';

export const searchRoutes = new Hono<Env>();

searchRoutes.use('*', requireAuth);

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

  let baseWhere = ' FROM pasal pas JOIN peraturan per ON pas.peraturan_id = per.id WHERE 1=1';
  const params: any[] = [];
  let paramIdx = 1;

  if (q.trim()) {
    baseWhere += ` AND (
      pas.teks_pasal ILIKE $${paramIdx} OR
      pas.nomor_pasal ILIKE $${paramIdx} OR
      per.judul ILIKE $${paramIdx} OR
      per.jenis_peraturan ILIKE $${paramIdx} OR
      per.nomor ILIKE $${paramIdx}
    )`;
    params.push(`%${q.trim()}%`);
    paramIdx++;
  }

  if (sektor.trim()) {
    baseWhere += ` AND per.sektor = $${paramIdx}`;
    params.push(sektor.trim());
    paramIdx++;
  }

  if (wilayah.trim()) {
    baseWhere += ` AND per.wilayah = $${paramIdx}`;
    params.push(wilayah.trim());
    paramIdx++;
  }

  // 1. Get total count
  const countSql = `SELECT COUNT(*) AS total` + baseWhere;
  const countRes = await query<{ total: string }>(countSql, params);
  const totalCount = parseInt(countRes[0]?.total || '0', 10);
  const totalPages = Math.ceil(totalCount / pageSize) || 1;

  // 2. Get paginated items
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
    ` + baseWhere + ` ORDER BY per.tahun DESC, per.id DESC, pas.id ASC LIMIT $${paramIdx} OFFSET $${paramIdx + 1};`;

  const itemParams = [...params, pageSize, offset];
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

  return c.html(<SearchResultsPartial query={q} sektor={sektor} wilayah={wilayah} searchData={searchData} />);
});

// GET /pencarian/status-modal/:peraturan_id
searchRoutes.get('/pencarian/status-modal/:peraturan_id', async (c) => {
  const regId = parseInt(c.req.param('peraturan_id'), 10);
  const rows = await query<SearchResultItem>('SELECT * FROM peraturan WHERE id = $1', [regId]);

  if (!rows || rows.length === 0) {
    return c.text('Peraturan tidak ditemukan', 404);
  }

  return c.html(<StatusDetailModal peraturan={rows[0]} />);
});
