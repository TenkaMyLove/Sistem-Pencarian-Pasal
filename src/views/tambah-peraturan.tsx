import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';
import { CrawlResult } from '../scraper/urlCrawler.js';

const JENIS_OPTIONS = [
  'UU', 'PP', 'Perpres', 'Permen', 'Perda', 'Pergub', 'Perbup', 'Perwal',
  'Inpres', 'Keppres', 'Kepmen', 'SE', 'Perppu', 'UUD 1945',
];

const WILAYAH_OPTIONS = [
  'Nasional', 'Kalimantan Selatan',
  'Kabupaten Banjar', 'Kabupaten Barito Kuala', 'Kabupaten Hulu Sungai Selatan',
  'Kabupaten Hulu Sungai Tengah', 'Kabupaten Hulu Sungai Utara',
  'Kabupaten Kotabaru', 'Kabupaten Tabalong', 'Kabupaten Tanah Bumbu',
  'Kabupaten Tanah Laut', 'Kabupaten Tapin', 'Kabupaten Balangan',
  'Kota Banjarbaru', 'Kota Banjarmasin',
];

const SEKTOR_OPTIONS = [
  'Keuangan Daerah', 'Otonomi Daerah', 'Tata Ruang', 'Lingkungan Hidup',
  'Pendidikan', 'Kesehatan', 'Ketenagakerjaan', 'Pertanahan',
  'Perpajakan', 'Perdagangan', 'Pertanian', 'Perikanan',
  'Infrastruktur', 'Pemerintahan', 'Hukum', 'Lainnya',
];

interface TambahPeraturanViewProps {
  user: UserSession;
  result?: CrawlResult | null;
  formValues?: Record<string, string>;
  error?: string;
}

export function TambahPeraturanView({ user, result, formValues, error }: TambahPeraturanViewProps) {
  const v = formValues || {};

  return (
    <Layout title="Tambah Peraturan Manual" activeNav="tambah-peraturan" user={user}>
      <div style="max-width: 860px; margin: 0 auto;">

        <div class="search-hero" style="margin-bottom: 2rem; padding: 1.75rem 2rem;">
          <h2 style="margin-bottom: 0.4rem;">Tambah Peraturan via URL</h2>
          <p style="color: var(--text-muted); font-size: 0.9rem;">
            Masukkan URL peraturan secara absolut. Sistem akan mengambil teks pasal dan status peraturan
            secara otomatis. URL diperlakukan apa adanya tanpa modifikasi.
          </p>
        </div>

        {/* Error global */}
        {error && (
          <div class="alert alert-danger" style="margin-bottom: 1.5rem;">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span>{error}</span>
          </div>
        )}

        {/* Hasil crawl */}
        {result && (
          <div class={result.ok ? 'alert alert-success' : 'alert alert-danger'} style="margin-bottom: 1.5rem; flex-direction: column; align-items: flex-start; gap: 0.75rem;">
            <div style="display: flex; align-items: center; gap: 0.5rem; font-weight: 700; font-size: 1rem;">
              {result.ok ? (
                <>
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Peraturan berhasil ditambahkan!
                </>
              ) : (
                <>
                  <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  Gagal menyimpan: {result.error}
                </>
              )}
            </div>
            {result.ok && (
              <div style="font-size: 0.875rem; line-height: 1.6;">
                <div><strong>Judul:</strong> {result.judul}</div>
                <div>
                  <strong>Status Tautan:</strong>{' '}
                  <span class={result.status_tautan === 'normal' ? 'badge badge-sektor' : 'badge badge-status-dicabut'}>
                    {result.status_tautan === 'normal' ? 'Tautan Valid (HTTP 200)' : 'Tautan Bermasalah'}
                  </span>
                </div>
                <div><strong>Pasal Ditemukan:</strong> {result.pasal_count} pasal</div>
                {result.pasal_count === 0 && (
                  <div style="color: #92400e; margin-top: 0.25rem;">
                    ⚠ Tidak ada pasal yang berhasil di-parse secara otomatis. Anda dapat menambahkan pasal secara manual dari database jika diperlukan.
                  </div>
                )}
                {result.peraturan_id && (
                  <div style="margin-top: 0.5rem;">
                    <a href={`/pencarian?q=${encodeURIComponent(result.judul.substring(0, 40))}`}
                      class="btn-action btn-primary"
                      style="display: inline-flex; text-decoration: none; padding: 0.4rem 0.9rem; font-size: 0.85rem; margin-top: 0.25rem;">
                      Cari di Pencarian Pasal
                    </a>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Form */}
        <div class="result-card" style="padding: 2rem;">
          <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--primary-navy); margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.75rem;">
            Form Tambah Peraturan
          </h3>

          <form action="/tambah-peraturan" method="post">

            {/* URL */}
            <div class="form-group">
              <label for="url">
                URL Peraturan <span style="color: var(--danger-color);">*</span>
              </label>
              <input
                type="url"
                id="url"
                name="url"
                class="form-control"
                value={v.url || ''}
                placeholder="https://peraturan.bpk.go.id/Details/12345/..."
                required
              />
              <small style="color: var(--text-muted); font-size: 0.78rem; margin-top: 0.3rem; display: block;">
                URL diperlakukan sebagai absolut. Bisa dari BPK, JDIH, atau sumber hukum manapun.
              </small>
            </div>

            {/* Jenis & Nomor & Tahun */}
            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;">
              <div class="form-group">
                <label for="jenis_peraturan">Jenis Peraturan <span style="color: var(--danger-color);">*</span></label>
                <select id="jenis_peraturan" name="jenis_peraturan" class="form-control" required>
                  {JENIS_OPTIONS.map(j => (
                    <option value={j} selected={v.jenis_peraturan === j}>{j}</option>
                  ))}
                </select>
              </div>
              <div class="form-group">
                <label for="nomor">Nomor <span style="color: var(--danger-color);">*</span></label>
                <input
                  type="text"
                  id="nomor"
                  name="nomor"
                  class="form-control"
                  value={v.nomor || ''}
                  placeholder="Contoh: 23"
                  required
                />
              </div>
              <div class="form-group">
                <label for="tahun">Tahun <span style="color: var(--danger-color);">*</span></label>
                <input
                  type="number"
                  id="tahun"
                  name="tahun"
                  class="form-control"
                  value={v.tahun || String(new Date().getFullYear())}
                  min="1900"
                  max={String(new Date().getFullYear() + 1)}
                  required
                />
              </div>
            </div>

            {/* Judul */}
            <div class="form-group">
              <label for="judul">Judul Peraturan</label>
              <input
                type="text"
                id="judul"
                name="judul"
                class="form-control"
                value={v.judul || ''}
                placeholder="Opsional — akan diambil otomatis dari halaman jika dikosongkan"
              />
            </div>

            {/* Wilayah & Sektor */}
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
              <div class="form-group">
                <label for="wilayah">Wilayah <span style="color: var(--danger-color);">*</span></label>
                <select id="wilayah" name="wilayah" class="form-control" required>
                  {WILAYAH_OPTIONS.map(w => (
                    <option value={w} selected={v.wilayah === w || (!v.wilayah && w === 'Nasional')}>{w}</option>
                  ))}
                </select>
              </div>
              <div class="form-group">
                <label for="sektor">Sektor <span style="color: var(--danger-color);">*</span></label>
                <select id="sektor" name="sektor" class="form-control" required>
                  {SEKTOR_OPTIONS.map(s => (
                    <option value={s} selected={v.sektor === s}>{s}</option>
                  ))}
                </select>
              </div>
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem; border-top: 1px solid var(--border-color); padding-top: 1.25rem;">
              <a href="/pencarian" class="btn-action" style="background-color: #f1f5f9; color: var(--text-main); text-decoration: none; display: inline-flex; align-items: center;">
                Batal
              </a>
              <button type="submit" class="btn-search" style="gap: 0.5rem;">
                <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"></path>
                </svg>
                 Tambahkan
              </button>
            </div>
          </form>
        </div>

      </div>
    </Layout>
  );
}
