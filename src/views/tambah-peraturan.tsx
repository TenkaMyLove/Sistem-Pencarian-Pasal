import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';
import { CrawlResult } from '../scraper/urlCrawler.js';

export const JENIS_OPTIONS = [
  'UU', 'PP', 'Perpres', 'Permen', 'Perda', 'Pergub', 'Perbup', 'Perwal',
  'Inpres', 'Keppres', 'Kepmen', 'SE', 'Perppu', 'UUD 1945',
];

export const WILAYAH_OPTIONS = [
  'Nasional', 'Kalimantan Selatan',
  'Kabupaten Banjar', 'Kabupaten Barito Kuala', 'Kabupaten Hulu Sungai Selatan',
  'Kabupaten Hulu Sungai Tengah', 'Kabupaten Hulu Sungai Utara',
  'Kabupaten Kotabaru', 'Kabupaten Tabalong', 'Kabupaten Tanah Bumbu',
  'Kabupaten Tanah Laut', 'Kabupaten Tapin', 'Kabupaten Balangan',
  'Kota Banjarbaru', 'Kota Banjarmasin',
];

export const SEKTOR_OPTIONS = [
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

const ALERT_ICON = 'M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
const OK_ICON = 'M5 13l4 4L19 7';

function Icon({ d, size = 18 }: { d: string; size?: number }) {
  return (
    <svg width={size} height={size} fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={d}></path>
    </svg>
  );
}

export function TambahPeraturanView({ user, result, formValues, error }: TambahPeraturanViewProps) {
  const v = formValues || {};

  return (
    <Layout title="Tambah Peraturan" activeNav="tambah-peraturan" user={user}>
      <div class="page-head">
        <div>
          <h2>Tambah Peraturan via Tautan</h2>
          <p>Indeks peraturan dan pasal baru dari tautan resmi portal hukum, atau lengkapi dengan teks manual.</p>
        </div>
      </div>

      {error && (
        <div class="alert alert-danger" role="alert">
          <Icon d={ALERT_ICON} size={20} />
          <span>{error}</span>
        </div>
      )}

      {result && (
        <div class={result.ok ? 'alert alert-success' : 'alert alert-danger'} role="status">
          <Icon d={result.ok ? OK_ICON : ALERT_ICON} size={20} />
          <div class="alert-body" style="flex: 1;">
            {result.ok ? (
              <>
                <span class="alert-title">Peraturan berhasil ditambahkan</span>
                <dl class="kv">
                  <dt>Judul</dt>
                  <dd>{result.judul}</dd>
                  <dt>Status Tautan</dt>
                  <dd>
                    <span class={result.status_tautan === 'normal' ? 'tag tag-berlaku' : 'tag tag-dicabut'}>
                      {result.status_tautan === 'normal' ? 'Tautan Valid (HTTP 200)' : 'Tautan Bermasalah'}
                    </span>
                  </dd>
                  <dt>Pasal Ditemukan</dt>
                  <dd>{result.pasal_count} pasal</dd>
                </dl>
                {result.pasal_count === 0 && (
                  <span>
                    Tidak ada pasal yang berhasil diekstrak. Tempel teks isi peraturan pada kolom Teks Isi Peraturan, lalu tambahkan ulang.
                  </span>
                )}
                {result.peraturan_id && (
                  <div style="margin-top: 0.5rem;">
                    <a
                      href={`/pencarian?q=${encodeURIComponent(result.judul.substring(0, 40))}`}
                      class="btn btn-sm btn-primary"
                    >
                      Cari di Pencarian Pasal
                    </a>
                  </div>
                )}
              </>
            ) : (
              <span class="alert-title">Gagal menyimpan: {result.error}</span>
            )}
          </div>
        </div>
      )}

      <div class="split">
        <form class="panel" action="/tambah-peraturan" method="post">
          <div class="panel-head">
            <h3>Metadata Peraturan</h3>
          </div>

          <div class="panel-pad">
            <div class="field">
              <label for="url">URL Peraturan <span class="req">*</span></label>
              <input
                type="url"
                id="url"
                name="url"
                class="input"
                value={v.url || ''}
                placeholder="https://peraturan.bpk.go.id/Details/12345/..."
                required
              />
            </div>

            <div class="grid-3">
              <div class="field">
                <label for="jenis_peraturan">Jenis Peraturan <span class="req">*</span></label>
                <select id="jenis_peraturan" name="jenis_peraturan" class="select" required>
                  {JENIS_OPTIONS.map(j => (
                    <option value={j} selected={v.jenis_peraturan === j}>{j}</option>
                  ))}
                </select>
              </div>
              <div class="field">
                <label for="nomor">Nomor <span class="req">*</span></label>
                <input type="text" id="nomor" name="nomor" class="input" value={v.nomor || ''} placeholder="23" required />
              </div>
              <div class="field">
                <label for="tahun">Tahun <span class="req">*</span></label>
                <input
                  type="number"
                  id="tahun"
                  name="tahun"
                  class="input"
                  value={v.tahun || String(new Date().getFullYear())}
                  min="1900"
                  max={String(new Date().getFullYear() + 1)}
                  required
                />
              </div>
            </div>

            <div class="field">
              <label for="judul">Judul Peraturan <span class="label-hint">(opsional)</span></label>
              <input
                type="text"
                id="judul"
                name="judul"
                class="input"
                value={v.judul || ''}
                placeholder="Diambil dari halaman sumber jika dikosongkan"
              />
            </div>

            <div class="grid-2">
              <div class="field">
                <label for="wilayah">Wilayah <span class="req">*</span></label>
                <select id="wilayah" name="wilayah" class="select" required>
                  {WILAYAH_OPTIONS.map(w => (
                    <option value={w} selected={v.wilayah === w || (!v.wilayah && w === 'Nasional')}>{w}</option>
                  ))}
                </select>
              </div>
              <div class="field">
                <label for="sektor">Sektor <span class="req">*</span></label>
                <select id="sektor" name="sektor" class="select" required>
                  {SEKTOR_OPTIONS.map(s => (
                    <option value={s} selected={v.sektor === s}>{s}</option>
                  ))}
                </select>
              </div>
            </div>

            <div class="field">
              <label for="teks_pasal_manual">Teks Isi Peraturan <span class="label-hint">(opsional)</span></label>
              <textarea
                id="teks_pasal_manual"
                name="teks_pasal_manual"
                class="textarea textarea-mono"
                rows={10}
                placeholder={"Tempel teks lengkap peraturan.\nBaris 'Pasal N' akan dideteksi dan diekstrak otomatis."}
              />
            </div>

            <div class="form-actions">
              <a href="/pencarian" class="btn">Batal</a>
              <button type="submit" class="btn btn-primary">
                <Icon d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                Tambahkan
              </button>
            </div>
          </div>
        </form>

        <aside class="panel">
          <div class="panel-head">
            <h3>Ketentuan Pengisian</h3>
          </div>
          <div class="panel-pad">
            <ul class="hint-list">
              <li>Gunakan tautan resmi JDIH BPK atau JDIH pemerintah daerah.</li>
              <li>Metadata dan relasi status diekstrak otomatis dari halaman JDIH BPK.</li>
              <li>Isi teks manual jika halaman sumber tidak dapat diurai otomatis, misalnya berkas PDF.</li>
              <li>Peraturan tanpa pasal tetap muncul di pencarian dengan tautan dokumen asli.</li>
            </ul>
          </div>
        </aside>
      </div>
    </Layout>
  );
}
