import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';
import { PaginatedSearchResults } from '../routes/search.js';

export interface StatusRelationItem {
  judul: string;
  label?: string;
  url: string;
  keterangan?: string;
}

export interface StatusDetailJson {
  dicabut_sebagian_dengan?: StatusRelationItem[];
  diubah_dengan?: StatusRelationItem[];
  mencabut?: StatusRelationItem[];
  mengubah?: StatusRelationItem[];
  mencabut_sebagian?: StatusRelationItem[];
  dicabut_dengan?: StatusRelationItem[];
  [key: string]: StatusRelationItem[] | undefined;
}

export interface SearchResultItem {
  pasal_id: number;
  nomor_pasal: string;
  nomor_ayat: string;
  teks_pasal: string;
  peraturan_id: number;
  jenis_peraturan: string;
  nomor: string;
  tahun: number;
  judul: string;
  status: string;
  status_detail?: string;
  status_detail_json?: StatusDetailJson | any;
  wilayah: string;
  sektor: string;
  url_dokumen_asli: string;
  status_tautan: string;
}

interface SearchViewProps {
  user: UserSession;
  initialQuery?: string;
  searchData: PaginatedSearchResults;
  sektorList: string[];
  wilayahList: string[];
}

export function SearchView({ user, initialQuery = '', searchData, sektorList, wilayahList }: SearchViewProps) {
  return (
    <Layout title="Pencarian Pasal Peraturan" activeNav="pencarian" user={user}>
      {/* Search Hero Box */}
      <div class="search-hero">
        <h2>Pencarian Pasal untuk Harmonisasi Ranperda</h2>
        <p>Cari pasal-pasal rujukan dari Undang-Undang, Peraturan Pemerintah, Permen 9 Sektor, dan Perda/Perkada se-Kalsel.</p>

        <form
          hx-get="/search-results"
          hx-target="#results-container"
          hx-trigger="submit"
          hx-indicator="#loading-indicator"
        >
          <div class="search-box">
            <input
              type="text"
              name="q"
              value={initialQuery}
              class="search-input"
              placeholder="Ketik kata kunci pasal (contoh: tata ruang, keuangan daerah, sampah, pajak)..."
              hx-get="/search-results"
              hx-target="#results-container"
              hx-trigger="keyup changed delay:350ms"
              hx-include="[name='sektor'], [name='wilayah']"
              hx-indicator="#loading-indicator"
              autofocus
            />
            <button type="submit" class="btn-search">
              <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
              Cari Pasal
            </button>
          </div>

          <div class="filter-bar">
            <select
              name="sektor"
              class="filter-select"
              hx-get="/search-results"
              hx-target="#results-container"
              hx-trigger="change"
              hx-include="[name='q'], [name='wilayah']"
              hx-indicator="#loading-indicator"
            >
              <option value="">-- Semua Sektor (9 Sektor) --</option>
              {sektorList.map((s) => (
                <option value={s}>{s}</option>
              ))}
            </select>

            <select
              name="wilayah"
              class="filter-select"
              hx-get="/search-results"
              hx-target="#results-container"
              hx-trigger="change"
              hx-include="[name='q'], [name='sektor']"
              hx-indicator="#loading-indicator"
            >
              <option value="">-- Semua Wilayah (Nasional & Kalsel) --</option>
              {wilayahList.map((w) => (
                <option value={w}>{w}</option>
              ))}
            </select>

            <span id="loading-indicator" class="htmx-indicator" style="color: var(--gold-light); font-size: 0.85rem; display: none; align-self: center;">
              Memuat hasil pencarian...
            </span>
          </div>
        </form>
      </div>

      {/* Results Container */}
      <div id="results-container">
        <SearchResultsPartial query={initialQuery} searchData={searchData} />
      </div>

      {/* Modal Container for Dynamic HTMX Modals */}
      <div id="modal-container"></div>
    </Layout>
  );
}

export function SearchResultsPartial({
  query = '',
  sektor = '',
  wilayah = '',
  searchData,
}: {
  query?: string;
  sektor?: string;
  wilayah?: string;
  searchData: PaginatedSearchResults;
}) {
  const { items, totalCount, currentPage, pageSize, totalPages } = searchData;

  if (!items || items.length === 0) {
    return (
      <div class="empty-state">
        <h3>Tidak ditemukan pasal yang cocok dengan kata kunci tersebut</h3>
        <p>
          Saran: Coba gunakan kata kunci yang lebih umum, periksa ejaan, atau atur kembali filter sektor dan wilayah Anda.
        </p>
      </div>
    );
  }

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalCount);

  // Precise Word-Boundary Keyword Highlighting
  const highlightText = (text: string, kw: string) => {
    if (!kw || !kw.trim()) return text;
    const terms = kw.trim().split(/\s+/).filter((t) => t.length > 0);
    if (terms.length === 0) return text;

    const escapedTerms = terms.map((t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));

    const patterns = escapedTerms.map((t) => {
      if (t.length < 3) {
        return `\\b${t}\\b`;
      }
      return `\\b${t}`;
    });

    const regex = new RegExp(`(${patterns.join('|')})`, 'gi');
    const parts = text.split(regex);

    return parts.map((part) => {
      const isMatch = terms.some((t) => {
        if (t.length < 3) {
          return part.toLowerCase() === t.toLowerCase();
        }
        return part.toLowerCase().startsWith(t.toLowerCase());
      });

      return isMatch ? <mark>{part}</mark> : part;
    });
  };

  const pages: number[] = [];
  for (let i = 1; i <= totalPages; i++) {
    pages.push(i);
  }

  return (
    <div class="search-results-wrapper">
      <div class="results-header">
        <span class="results-count">
          Menampilkan {startItem} - {endItem} dari total {totalCount} pasal rujukan {query ? `untuk kata kunci "${query}"` : ''}
        </span>
      </div>

      {/* Scrollable Container Box for Cards */}
      <div class="results-scroll-container">
        <div class="results-list">
          {items.map((item) => (
            <div class="result-card">
              <div class="result-card-header">
                <h4 class="result-title">
                  {item.jenis_peraturan} No. {item.nomor} Tahun {item.tahun}
                </h4>

                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: center;">
                  <span class={`badge ${item.status === 'berlaku' ? 'badge-status-berlaku' : 'badge-status-dicabut'}`}>
                    {item.status.toUpperCase()}
                  </span>

                  {(() => {
                    const json: Record<string, any[]> = typeof item.status_detail_json === 'string'
                      ? (() => { try { return JSON.parse(item.status_detail_json); } catch { return {}; } })()
                      : (item.status_detail_json || {});

                    const relasiBadgeMap: Record<string, { label: string; cls: string }> = {
                      mencabut:             { label: 'Mencabut',          cls: 'badge-rel-mencabut' },
                      mencabut_sebagian:    { label: 'Mencabut Sebagian', cls: 'badge-rel-mencabut' },
                      mengubah:             { label: 'Mengubah',          cls: 'badge-rel-mengubah' },
                      dicabut_dengan:       { label: 'Dicabut',           cls: 'badge-rel-dicabut' },
                      dicabut_sebagian_dengan: { label: 'Dicabut Sebagian', cls: 'badge-rel-dicabut' },
                      diubah_dengan:        { label: 'Diubah',            cls: 'badge-rel-diubah' },
                    };

                    const relasiBadges = Object.entries(relasiBadgeMap)
                      .filter(([key]) => Array.isArray(json[key]) && json[key].length > 0)
                      .map(([key, { label, cls }]) => (
                        <span
                          class={`badge ${cls}`}
                          title={`${label}: ${json[key].length} peraturan`}
                        >
                          {label} ({json[key].length})
                        </span>
                      ));

                    // Fallback: jika JSON kosong tapi ada teks status_detail
                    if (relasiBadges.length === 0 && item.status_detail && item.status_detail.trim()) {
                      return (
                        <span
                          class="badge badge-rel-keterangan"
                          title={item.status_detail}
                        >
                          Ada Keterangan
                        </span>
                      );
                    }

                    return relasiBadges;
                  })()}

                  {item.status_tautan === 'tautan_bermasalah' ? (
                    <span class="badge badge-tautan-bermasalah" title="Tautan dokumen asli di situs sumber mengalami kendala HTTP 404/Error">
                      Tautan Bermasalah
                    </span>
                  ) : (
                    <span class="badge badge-tautan-normal">
                      Tautan Aktif
                    </span>
                  )}
                </div>
              </div>

              <p style="font-size: 0.95rem; color: var(--text-main); font-weight: 600; margin-top: 0.4rem; margin-bottom: 0.95rem; line-height: 1.65; letter-spacing: 0.2px;">
                {item.judul}
              </p>

              <div class="result-meta">
                <span class="badge badge-jenis">{item.jenis_peraturan}</span>
                {item.sektor && <span class="badge badge-sektor">Sektor: {item.sektor}</span>}
                <span class="badge badge-wilayah">Wilayah: {item.wilayah}</span>
                <span class="badge" style="background-color: #f1f5f9; color: var(--text-main); font-weight: 700;">
                  {item.nomor_pasal} {item.nomor_ayat ? item.nomor_ayat : ''}
                </span>
              </div>

              <div class="result-snippet">
                <strong>Kutipan Pasal:</strong>
                <div style="margin-top: 0.4rem;">
                  {highlightText(item.teks_pasal, query)}
                </div>
              </div>

              <div class="result-actions" style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 0.75rem;">
                <button
                  type="button"
                  class="btn-edit"
                  style="padding: 0.45rem 0.85rem; font-size: 0.825rem; font-weight: 600; background-color: #fff; color: var(--primary-navy); border: 1px solid var(--primary-navy); cursor: pointer; border-radius: var(--radius-md); transition: all 0.2s ease;"
                  hx-get={`/pencarian/status-modal/${item.peraturan_id}`}
                  hx-target="#modal-container"
                >
                  Lihat Detil Status Peraturan &raquo;
                </button>

                <a
                  href={item.url_dokumen_asli}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn-link-pdf"
                  title="Buka PDF Asli di Situs Resmi Sumber"
                >
                  <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
                  </svg>
                  Lihat Dokumen PDF Asli
                </a>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Pinned Numbered Pagination Control Bar */}
      {totalPages > 1 && (
        <div style="display: flex; align-items: center; justify-content: center; gap: 0.5rem; pt: 1rem; border-top: 1px solid var(--border-color); flex-wrap: wrap;">
          {/* Previous Page Button */}
          <button
            class="btn-action"
            style={`background-color: #fff; border: 1px solid var(--border-color); color: var(--text-main); opacity: ${currentPage === 1 ? '0.5' : '1'};`}
            disabled={currentPage === 1}
            hx-get={`/search-results?q=${encodeURIComponent(query)}&sektor=${encodeURIComponent(sektor)}&wilayah=${encodeURIComponent(wilayah)}&page=${currentPage - 1}`}
            hx-target="#results-container"
            hx-indicator="#loading-indicator"
          >
            &laquo; Sebelumnya
          </button>

          {/* Page Numbers */}
          {pages.map((p) => (
            <button
              class="btn-action"
              style={p === currentPage ? 'background-color: var(--gold-accent); color: #fff; font-weight: 700;' : 'background-color: #fff; border: 1px solid var(--border-color); color: var(--text-main);'}
              hx-get={`/search-results?q=${encodeURIComponent(query)}&sektor=${encodeURIComponent(sektor)}&wilayah=${encodeURIComponent(wilayah)}&page=${p}`}
              hx-target="#results-container"
              hx-indicator="#loading-indicator"
            >
              {p}
            </button>
          ))}

          {/* Next Page Button */}
          <button
            class="btn-action"
            style={`background-color: #fff; border: 1px solid var(--border-color); color: var(--text-main); opacity: ${currentPage === totalPages ? '0.5' : '1'};`}
            disabled={currentPage === totalPages}
            hx-get={`/search-results?q=${encodeURIComponent(query)}&sektor=${encodeURIComponent(sektor)}&wilayah=${encodeURIComponent(wilayah)}&page=${currentPage + 1}`}
            hx-target="#results-container"
            hx-indicator="#loading-indicator"
          >
            Selanjutnya &raquo;
          </button>
        </div>
      )}
    </div>
  );
}

// Modal View for Detailed Regulation Legal Status Relationships
export function StatusDetailModal({ peraturan }: { peraturan: any }) {
  const json: Record<string, any[]> = typeof peraturan.status_detail_json === 'string'
    ? JSON.parse(peraturan.status_detail_json)
    : (peraturan.status_detail_json || {});

  // Mapping readable labels for known BPK crawler keys
  const labelMap: Record<string, string> = {
    mencabut: 'MENCABUT',
    mencabut_sebagian: 'MENCABUT SEBAGIAN',
    diubah_dengan: 'DIUBAH DENGAN',
    dicabut_dengan: 'DICABUT DENGAN',
    dicabut_sebagian_dengan: 'DICABUT SEBAGIAN DENGAN',
    mengubah: 'MENGUBAH',
    diubah: 'DIUBAH',
    perubahan: 'PERUBAHAN',
    peraturan_terkait: 'PERATURAN TERKAIT'
  };

  const keys = Object.keys(json).filter((key) => Array.isArray(json[key]) && json[key].length > 0);

  return (
    <div class="modal-backdrop" id="status-modal">
      <div class="modal-content" style="max-width: 750px; max-height: 85vh; overflow-y: auto;">
        <div class="modal-header" style="border-bottom: 1px solid var(--border-color); padding-bottom: 0.85rem; margin-bottom: 1rem;">
          <div>
            <h3 style="font-size: 1.15rem; color: var(--primary-navy); font-weight: 800;">
              Detil Status Peraturan
            </h3>
            <p style="font-size: 0.875rem; color: var(--text-muted); margin-top: 0.2rem;">
              {peraturan.jenis_peraturan} No. {peraturan.nomor} Tahun {peraturan.tahun}
            </p>
          </div>
        </div>

        <p style="font-size: 0.95rem; font-weight: 600; color: var(--text-main); margin-bottom: 1.25rem; line-height: 1.65; letter-spacing: 0.2px;">
          {peraturan.judul}
        </p>

        <div style="display: flex; flex-direction: column; gap: 1.25rem;">
          {keys.length > 0 ? (
            keys.map((key) => (
              <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; padding: 1.25rem; border-radius: var(--radius-md);">
                <h4 style="font-size: 0.9rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; text-transform: uppercase; letter-spacing: 0.5px;">
                  {labelMap[key] ? `${labelMap[key]}:` : `${key.replace(/_/g, ' ').toUpperCase()}:`}
                </h4>
                <ul style="list-style-type: disc; padding-left: 1.25rem; display: flex; flex-direction: column; gap: 0.75rem; margin: 0;">
                  {json[key].map((item: any) => (
                    <li style="font-size: 0.875rem; color: #0f172a; line-height: 1.5;">
                      <a
                        href={item.url || `/pencarian?q=${encodeURIComponent(item.label || item.judul)}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style="color: #0f172a; font-weight: 700; text-decoration: underline;"
                      >
                        {item.judul || item.label || 'Lihat Dokumen'}
                      </a>
                      {item.keterangan && (
                        <div style="margin-top: 0.5rem; border: 1px dashed #cbd5e1; border-radius: 6px; padding: 0.65rem 0.85rem; background-color: #ffffff; color: #334155; font-size: 0.825rem; line-height: 1.6;">
                          {renderKeteranganWithLinks(item.keterangan)}
                        </div>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))
          ) : peraturan.status_detail && peraturan.status_detail.trim() ? (
            // Fallback: parse teks status_detail jadi segmen-segmen
            <FallbackStatusDetail statusDetail={peraturan.status_detail} />
          ) : (
            <p style="font-size: 0.9rem; color: var(--text-muted); text-align: center; padding: 1rem;">
              Tidak ada data status tambahan tersedia.
            </p>
          )}
        </div>

        <div style="margin-top: 1.5rem; text-align: right;">
          <button
            type="button"
            class="btn-action"
            style="background-color: var(--primary-navy); color: #fff; padding: 0.5rem 1.25rem;"
            onclick="document.getElementById('status-modal').remove()"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}

// Render keterangan dengan mengubah pasal-pasal yang disebutkan menjadi link yang bisa diklik
function renderKeteranganWithLinks(keterangan: string) {
  if (!keterangan) return null;

  // Regex mencari pola sebutan pasal (misal: "Pasal 238", "Pasal 15", "Pasal 21 s.d. Pasal 25", "Pasal 1 angka 30")
  const regex = /(Pasal\s+\d+(?:\s*(?:s\.d\.|sampai dengan|-)\s*(?:Pasal\s*)?\d+)?(?:\s+ayat\s*\(\d+\))?(?:\s+huruf\s+[a-z])?(?:\s+angka\s+\d+)?)/gi;
  const parts = keterangan.split(regex);

  return parts.map((part) => {
    if (/^Pasal\s+\d+/i.test(part.trim())) {
      return (
        <a
          href={`/pencarian?q=${encodeURIComponent(part.trim())}`}
          target="_blank"
          rel="noopener noreferrer"
          title={`Cari ${part.trim()} di sistem`}
          style="color: var(--primary-navy); font-weight: 700; text-decoration: underline; background-color: #f1f5f9; padding: 0.1rem 0.35rem; border-radius: 4px; display: inline-block; margin: 0 0.15rem;"
        >
          {part}
        </a>
      );
    }
    return part;
  });
}

// Komponen fallback: parse teks status_detail menjadi segmen terstruktur dengan link pencarian
function FallbackStatusDetail({ statusDetail }: { statusDetail: string }) {
  const segments = statusDetail
    .split(/[;]/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  return (
    <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; padding: 1.25rem; border-radius: var(--radius-md);">
      <h4 style="font-size: 0.9rem; font-weight: 800; color: #0f172a; margin-bottom: 0.75rem; text-transform: uppercase; letter-spacing: 0.5px;">
        KETERANGAN STATUS:
      </h4>
      <ul style="list-style-type: disc; padding-left: 1.25rem; display: flex; flex-direction: column; gap: 0.65rem; margin: 0;">
        {segments.map((seg) => (
          <li style="font-size: 0.875rem; color: #0f172a; line-height: 1.6;">
            {renderKeteranganWithLinks(seg)}
          </li>
        ))}
      </ul>
    </div>
  );
}
