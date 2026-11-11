import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';
import { PaginatedSearchResults } from '../routes/search.js';
import { JENIS_OPTIONS, WILAYAH_OPTIONS, SEKTOR_OPTIONS } from './tambah-peraturan.js';

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

// Ikon inline (stroke 2) agar tidak bergantung pada font/CDN eksternal
const ICON = {
  search: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z',
  edit: 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z',
  pencil: 'M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z',
  trash: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
  external: 'M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14',
  close: 'M6 18L18 6M6 6l12 12',
  check: 'M5 13l4 4L19 7',
  list: 'M4 6h16M4 12h16M4 18h7',
};

function Icon({ d, size = 16 }: { d: string; size?: number }) {
  return (
    <svg width={size} height={size} fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={d}></path>
    </svg>
  );
}

export function SearchView({ user, initialQuery = '', searchData, sektorList, wilayahList }: SearchViewProps) {
  return (
    <Layout title="Pencarian Pasal Peraturan" activeNav="pencarian" user={user}>
      <div class="panel filter-panel">
        <form
          hx-get="/search-results"
          hx-target="#results-container"
          hx-trigger="submit"
          hx-indicator="#loading-indicator"
        >
          <div class="filter-row">
            <div class="search-field">
              <Icon d={ICON.search} size={20} />
              <input
                type="text"
                name="q"
                value={initialQuery}
                class="input"
                aria-label="Kata kunci pencarian"
                placeholder="Nomor Undang-Undang atau Kata Kunci"
                hx-get="/search-results"
                hx-target="#results-container"
                hx-trigger="keyup changed delay:350ms"
                hx-include="[name='sektor'], [name='wilayah']"
                hx-indicator="#loading-indicator"
                autofocus
              />
            </div>
            <button type="submit" class="btn btn-primary">
              <Icon d={ICON.search} size={18} />
              Cari Pasal
            </button>
          </div>

          <div class="filter-grid">
            <div class="field">
              <label for="filter-sektor">Sektor Regulasi</label>
              <select
                id="filter-sektor"
                name="sektor"
                class="select"
                hx-get="/search-results"
                hx-target="#results-container"
                hx-trigger="change"
                hx-include="[name='q'], [name='wilayah']"
                hx-indicator="#loading-indicator"
              >
                <option value="">Semua Sektor</option>
                {sektorList.map((s) => (
                  <option value={s}>{s}</option>
                ))}
              </select>
            </div>

            <div class="field">
              <label for="filter-wilayah">Wilayah Kewenangan</label>
              <select
                id="filter-wilayah"
                name="wilayah"
                class="select"
                hx-get="/search-results"
                hx-target="#results-container"
                hx-trigger="change"
                hx-include="[name='q'], [name='sektor']"
                hx-indicator="#loading-indicator"
              >
                <option value="">Semua Wilayah</option>
                {wilayahList.map((w) => (
                  <option value={w}>{w}</option>
                ))}
              </select>
            </div>
          </div>

          <span id="loading-indicator" class="htmx-indicator loading-text">
            Memuat hasil pencarian...
          </span>
        </form>
      </div>

      {/* Results Container */}
      <div
        id="results-container"
        hx-get="/search-results"
        hx-trigger="refreshResults from:body"
        hx-include="[name='q'], [name='sektor'], [name='wilayah'], [name='active_page']"
        hx-indicator="#loading-indicator"
      >
        <SearchResultsPartial query={initialQuery} searchData={searchData} user={user} />
      </div>

      {/* Modal Container for Dynamic HTMX Modals */}
      <div id="modal-container"></div>
    </Layout>
  );
}

// Relasi hukum yang ditampilkan sebagai penanda ringkas pada baris hasil
const RELASI_TAG_MAP: Record<string, { label: string; cls: string }> = {
  mencabut: { label: 'Mencabut', cls: 'tag-dicabut' },
  mencabut_sebagian: { label: 'Mencabut Sebagian', cls: 'tag-dicabut' },
  mengubah: { label: 'Mengubah', cls: 'tag-ubah' },
  dicabut_dengan: { label: 'Dicabut', cls: 'tag-dicabut' },
  dicabut_sebagian_dengan: { label: 'Dicabut Sebagian', cls: 'tag-dicabut' },
  diubah_dengan: { label: 'Diubah', cls: 'tag-ubah' },
};

function parseStatusJson(raw: any): Record<string, any[]> {
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw) || {};
    } catch {
      return {};
    }
  }
  return raw || {};
}

// Daftar nomor halaman ringkas: 1 ... n-1 n n+1 ... last
function pageWindow(current: number, total: number): (number | null)[] {
  const set = new Set<number>([1, total, current - 1, current, current + 1]);
  const nums = [...set].filter((n) => n >= 1 && n <= total).sort((a, b) => a - b);
  const out: (number | null)[] = [];
  nums.forEach((n, i) => {
    if (i > 0 && n - nums[i - 1] > 1) out.push(null);
    out.push(n);
  });
  return out;
}

export function SearchResultsPartial({
  query = '',
  sektor = '',
  wilayah = '',
  searchData,
  user,
}: {
  query?: string;
  sektor?: string;
  wilayah?: string;
  searchData: PaginatedSearchResults;
  user?: UserSession;
}) {
  const isPengelola = user?.peran === 'Pengelola' || user?.peran === 'Admin';
  const { items, totalCount, currentPage, pageSize, totalPages } = searchData;

  if (!items || items.length === 0) {
    return (
      <div class="panel empty-state">
        <h3>Tidak ditemukan pasal yang sesuai dengan kata kunci</h3>
        <p>Gunakan kata kunci yang lebih umum, periksa ejaan, atau atur kembali filter sektor dan wilayah.</p>
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

  const pageUrl = (p: number) =>
    `/search-results?q=${encodeURIComponent(query)}&sektor=${encodeURIComponent(sektor)}&wilayah=${encodeURIComponent(wilayah)}&page=${p}`;

  return (
    <div class="panel">
      <input type="hidden" name="active_page" value={String(currentPage)} />

      <div class="results-summary" style="padding: 1rem 1.5rem;">
        <span>
          Menampilkan <strong>{startItem} - {endItem}</strong> dari <strong>{totalCount}</strong> pasal rujukan
          {query ? <> untuk kata kunci <span class="kw-chip">{query}</span></> : ''}
        </span>
      </div>

      <div class="results-scroll">
        {items.map((item) => {
          const json = parseStatusJson(item.status_detail_json);
          const relasiTags = Object.entries(RELASI_TAG_MAP)
            .filter(([key]) => Array.isArray(json[key]) && json[key].length > 0)
            .map(([key, { label, cls }]) => (
              <span class={`tag ${cls}`} title={`${label}: ${json[key].length} peraturan`}>
                {label} ({json[key].length})
              </span>
            ));
          const hasKeterangan = relasiTags.length === 0 && item.status_detail && item.status_detail.trim();
          const statusCls =
            item.status === 'berlaku' ? 'tag-berlaku' : item.status === 'diubah' ? 'tag-ubah' : 'tag-dicabut';

          return (
            <article
              class="result-row"
              id={item.pasal_id ? `card-pasal-${item.pasal_id}` : `card-peraturan-${item.peraturan_id}`}
            >
              <div class="meta-line">
                <span class={`tag ${statusCls}`}>{item.status}</span>
                {relasiTags}
                {hasKeterangan && (
                  <span class="tag tag-neutral" title={item.status_detail}>Ada Keterangan</span>
                )}
                {item.sektor && <span>Sektor: {item.sektor}</span>}
                {item.sektor && <span class="meta-sep">/</span>}
                <span>Wilayah: {item.wilayah}</span>
                <span class="meta-sep">/</span>
                {item.status_tautan === 'tautan_bermasalah' ? (
                  <span class="meta-bad" title="Tautan dokumen asli di situs sumber mengalami kendala HTTP 404/Error">
                    Tautan Bermasalah
                  </span>
                ) : (
                  <span class="meta-ok">Tautan Aktif</span>
                )}
              </div>

              <h4 class="result-title">
                {item.jenis_peraturan} Nomor {item.nomor} Tahun {item.tahun}
              </h4>
              <p class="result-sub">{item.judul}</p>

              {item.pasal_id ? (
                <div class="quote">
                  <div class="quote-label">
                    {item.nomor_pasal} {item.nomor_ayat ? item.nomor_ayat : ''}
                  </div>
                  <div class="quote-text">{highlightText(item.teks_pasal, query)}</div>
                </div>
              ) : (
                <div class="note-box">
                  <strong>Dokumen Peraturan Terindeks</strong>
                  Peraturan ini belum memiliki entri pasal. Naskah utuh dapat ditelaah melalui dokumen resmi.
                </div>
              )}

              <div class="row-actions">
                <div class="row-actions-group">
                  <button
                    type="button"
                    class="btn btn-sm btn-outline"
                    hx-get={`/pencarian/status-modal/${item.peraturan_id}`}
                    hx-target="#modal-container"
                  >
                    <Icon d={ICON.list} />
                    Lihat Detil Status
                  </button>

                  {isPengelola && (
                    <>
                      <button
                        type="button"
                        class="btn btn-sm"
                        hx-get={`/pencarian/edit-peraturan-modal/${item.peraturan_id}`}
                        hx-target="#modal-container"
                        title="Edit data peraturan ini"
                      >
                        <Icon d={ICON.edit} />
                        Edit Peraturan
                      </button>

                      {item.pasal_id && (
                        <button
                          type="button"
                          class="btn btn-sm"
                          hx-get={`/pencarian/edit-pasal-modal/${item.pasal_id}`}
                          hx-target="#modal-container"
                          title="Edit teks pasal ini"
                        >
                          <Icon d={ICON.pencil} />
                          Edit Pasal
                        </button>
                      )}

                      <button
                        type="button"
                        class="btn btn-sm btn-danger-outline"
                        hx-post={`/pencarian/hapus-peraturan/${item.peraturan_id}`}
                        hx-swap="none"
                        hx-confirm={`Hapus peraturan ${item.jenis_peraturan} No. ${item.nomor} Tahun ${item.tahun} beserta seluruh pasalnya? Tindakan ini tidak dapat dibatalkan.`}
                        title="Hapus peraturan ini beserta seluruh pasalnya"
                      >
                        <Icon d={ICON.trash} />
                        Hapus Peraturan
                      </button>

                      {item.pasal_id && (
                        <button
                          type="button"
                          class="btn btn-sm btn-danger-outline"
                          hx-post={`/pencarian/hapus-pasal/${item.pasal_id}`}
                          hx-swap="none"
                          hx-confirm={`Hapus ${item.nomor_pasal} dari ${item.jenis_peraturan} No. ${item.nomor} Tahun ${item.tahun}? Tindakan ini tidak dapat dibatalkan.`}
                          title="Hapus pasal ini dari database"
                        >
                          <Icon d={ICON.close} />
                          Hapus Pasal
                        </button>
                      )}
                    </>
                  )}
                </div>

                <a
                  href={item.url_dokumen_asli}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-sm"
                  title="Buka dokumen asli di situs resmi sumber"
                >
                  <Icon d={ICON.external} />
                  Dokumen Asli
                </a>
              </div>
            </article>
          );
        })}
      </div>

      {totalPages > 1 && (
        <nav class="pager" style="border-top: 1px solid var(--border);" aria-label="Halaman hasil pencarian">
          <div class="pager-info">
            Halaman <strong>{currentPage}</strong> dari <strong>{totalPages}</strong>
          </div>
          <div class="pager-pages">
            <button
              type="button"
              class="pager-btn"
              disabled={currentPage === 1}
              hx-get={pageUrl(currentPage - 1)}
              hx-target="#results-container"
              hx-indicator="#loading-indicator"
            >
              Sebelumnya
            </button>

            {pageWindow(currentPage, totalPages).map((p) =>
              p === null ? (
                <span class="meta-sep" style="padding: 0 0.25rem;">...</span>
              ) : (
                <button
                  type="button"
                  class={`pager-btn ${p === currentPage ? 'is-current' : ''}`}
                  aria-current={p === currentPage ? 'page' : undefined}
                  hx-get={pageUrl(p)}
                  hx-target="#results-container"
                  hx-indicator="#loading-indicator"
                >
                  {p}
                </button>
              )
            )}

            <button
              type="button"
              class="pager-btn"
              disabled={currentPage === totalPages}
              hx-get={pageUrl(currentPage + 1)}
              hx-target="#results-container"
              hx-indicator="#loading-indicator"
            >
              Selanjutnya
            </button>
          </div>
        </nav>
      )}
    </div>
  );
}

// Modal View for Detailed Regulation Legal Status Relationships
export function StatusDetailModal({ peraturan }: { peraturan: any }) {
  const json = parseStatusJson(peraturan.status_detail_json);

  // Mapping readable labels for known BPK crawler keys
  const labelMap: Record<string, string> = {
    mencabut: 'Mencabut',
    mencabut_sebagian: 'Mencabut Sebagian',
    diubah_dengan: 'Diubah Dengan',
    dicabut_dengan: 'Dicabut Dengan',
    dicabut_sebagian_dengan: 'Dicabut Sebagian Dengan',
    mengubah: 'Mengubah',
    diubah: 'Diubah',
    perubahan: 'Perubahan',
    peraturan_terkait: 'Peraturan Terkait',
  };

  const keys = Object.keys(json).filter((key) => Array.isArray(json[key]) && json[key].length > 0);

  return (
    <div class="modal-backdrop" id="status-modal" onclick="if(event.target===this)this.remove()">
      <div class="modal-content modal-wide" role="dialog" aria-modal="true" aria-labelledby="status-modal-title">
        <div class="modal-header">
          <div>
            <span class="section-label">Pemeriksaan Yuridis</span>
            <h3 id="status-modal-title">Detil Status Peraturan</h3>
            <p>
              {peraturan.jenis_peraturan} No. {peraturan.nomor} Tahun {peraturan.tahun}
            </p>
          </div>
          <button
            type="button"
            onclick="document.getElementById('status-modal').remove()"
            class="modal-close-btn"
            title="Tutup"
            aria-label="Tutup"
          >
            <Icon d={ICON.close} size={20} />
          </button>
        </div>

        <p class="cell-strong" style="margin-bottom: 1rem; line-height: 24px;">{peraturan.judul}</p>

        <div>
          {keys.length > 0 ? (
            keys.map((key) => (
              <section class="rel-group">
                <h4 class="section-label">{labelMap[key] ?? key.replace(/_/g, ' ')}</h4>
                <div class="rel-list">
                  {json[key].map((item: any) => (
                    <div class="rel-item">
                      <div style="min-width: 0;">
                        <div class="rel-title">
                          {item.url ? (
                            <a href={item.url} target="_blank" rel="noopener noreferrer">
                              {item.judul || item.label || 'Lihat Dokumen'}
                              {' '}
                              <Icon d={ICON.external} size={12} />
                            </a>
                          ) : (
                            <span>{item.judul || item.label || '-'}</span>
                          )}
                        </div>
                        {item.keterangan && (
                          <div class="rel-note">{renderKeteranganWithLinks(item.keterangan)}</div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            ))
          ) : peraturan.status_detail && peraturan.status_detail.trim() ? (
            <FallbackStatusDetail statusDetail={peraturan.status_detail} />
          ) : (
            <p class="cell-mute" style="text-align: center; padding: 1rem;">
              Tidak ada data status tambahan tersedia.
            </p>
          )}
        </div>

        <div class="form-actions">
          <button
            type="button"
            class="btn btn-primary"
            onclick="document.getElementById('status-modal').remove()"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}

// Render keterangan dengan menghighlight referensi pasal (bukan clickable link)
function renderKeteranganWithLinks(keterangan: string) {
  if (!keterangan) return null;

  // Regex mencari pola sebutan pasal (misal: "Pasal 238", "Pasal 15", "Pasal 21 s.d. Pasal 25", "Pasal 1 angka 30")
  const regex = /(Pasal\s+\d+(?:\s*(?:s\.d\.|sampai dengan|-)\s*(?:Pasal\s*)?\d+)?(?:\s+ayat\s*\(\d+\))?(?:\s+huruf\s+[a-z])?(?:\s+angka\s+\d+)?)/gi;
  const parts = keterangan.split(regex);

  return parts.map((part) => {
    if (/^Pasal\s+\d+/i.test(part.trim())) {
      return <span class="pasal-ref">{part}</span>;
    }
    return part;
  });
}

/**
 * Linkify regulation references in plain text, and highlight Pasal references as non-clickable spans.
 */
function linkifyRegRefs(text: string) {
  const regPattern = /((?:UU|PP|Perpres|Permen|Perda|Pergub|Perbup|Perwal|Perppu|Inpres|Keppres|Kepmen)\b[^;.\n]*?No\.?\s*\d+\s+Tahun\s+\d{4})/g;
  const parts: any[] = [];
  let last = 0;
  let m: RegExpExecArray | null;

  const re = new RegExp(regPattern.source, 'g');
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) {
      parts.push(renderKeteranganWithLinks(text.slice(last, m.index)));
    }
    const ref = m[1].trim();
    parts.push(
      <a
        href={`/pencarian?q=${encodeURIComponent(ref)}`}
        target="_blank"
        rel="noopener noreferrer"
        title={`Cari "${ref}" di sistem`}
        class="reg-link"
      >
        {ref}
      </a>
    );
    last = m.index + m[0].length;
  }
  if (last < text.length) {
    parts.push(renderKeteranganWithLinks(text.slice(last)));
  }
  return parts.length > 0 ? parts : [renderKeteranganWithLinks(text)];
}

// Komponen fallback: parse teks status_detail menjadi segmen terstruktur
function FallbackStatusDetail({ statusDetail }: { statusDetail: string }) {
  const segments = statusDetail
    .split(/[;]/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  return (
    <section class="rel-group">
      <h4 class="section-label">Keterangan Status</h4>
      <div class="rel-list">
        {segments.map((seg) => (
          <div class="rel-item">
            <div style="font-size: 14px; line-height: 22px;">{linkifyRegRefs(seg)}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

// Modal Edit Pasal — hanya untuk Pengelola/Admin
export function EditPasalModal({ pasal, error }: { pasal: any; error?: string }) {
  return (
    <div class="modal-backdrop" id="edit-pasal-modal" onclick="if(event.target===this)this.remove()">
      <div class="modal-content" role="dialog" aria-modal="true" aria-labelledby="edit-pasal-title">
        <div class="modal-header">
          <div>
            <h3 id="edit-pasal-title">Edit Pasal</h3>
            <p>Pasal ID #{pasal.id} &middot; Peraturan ID #{pasal.peraturan_id}</p>
          </div>
          <button
            type="button"
            onclick="document.getElementById('edit-pasal-modal').remove()"
            class="modal-close-btn"
            title="Tutup"
            aria-label="Tutup"
          >
            <Icon d={ICON.close} size={20} />
          </button>
        </div>

        {error && (
          <div class="alert alert-danger" role="alert" style="margin-bottom: 1rem;">
            <span>{error}</span>
          </div>
        )}

        <form
          hx-post={`/pencarian/edit-pasal/${pasal.id}`}
          hx-target="#modal-container"
          hx-swap="innerHTML"
        >
          <div class="field">
            <label for="ep-nomor-pasal">Nomor Pasal <span class="req">*</span></label>
            <input
              type="text"
              id="ep-nomor-pasal"
              name="nomor_pasal"
              class="input"
              value={pasal.nomor_pasal || ''}
              placeholder="Pasal 1"
              required
            />
          </div>

          <div class="field">
            <label for="ep-nomor-ayat">Nomor Ayat <span class="label-hint">(opsional)</span></label>
            <input
              type="text"
              id="ep-nomor-ayat"
              name="nomor_ayat"
              class="input"
              value={pasal.nomor_ayat || ''}
              placeholder="Ayat (1)"
            />
          </div>

          <div class="field">
            <label for="ep-teks-pasal">Teks Pasal <span class="req">*</span></label>
            <textarea
              id="ep-teks-pasal"
              name="teks_pasal"
              class="textarea textarea-mono"
              rows={8}
              required
            >{pasal.teks_pasal || ''}</textarea>
          </div>

          <div class="form-actions">
            <button
              type="button"
              class="btn"
              onclick="document.getElementById('edit-pasal-modal').remove()"
            >
              Batal
            </button>
            <button type="submit" class="btn btn-primary">
              <Icon d={ICON.check} />
              Simpan Perubahan
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Modal Edit Peraturan — hanya untuk Pengelola/Admin
export function EditPeraturanModal({ peraturan, error }: { peraturan: any; error?: string }) {
  const buildOptions = (baseList: string[], currentVal?: string) => {
    const val = (currentVal || '').trim();
    return val && !baseList.includes(val) ? [val, ...baseList] : baseList;
  };

  const jenisList = buildOptions(JENIS_OPTIONS, peraturan.jenis_peraturan);
  const wilayahList = buildOptions(WILAYAH_OPTIONS, peraturan.wilayah);
  const sektorList = buildOptions(SEKTOR_OPTIONS, peraturan.sektor);
  const statusOptions = ['berlaku', 'diubah', 'dicabut'];

  return (
    <div class="modal-backdrop" id="edit-peraturan-modal" onclick="if(event.target===this)this.remove()">
      <div class="modal-content modal-wide" role="dialog" aria-modal="true" aria-labelledby="edit-peraturan-title">
        <div class="modal-header">
          <div>
            <h3 id="edit-peraturan-title">Edit Data Peraturan</h3>
            <p>Peraturan ID #{peraturan.id}</p>
          </div>
          <button
            type="button"
            onclick="document.getElementById('edit-peraturan-modal').remove()"
            class="modal-close-btn"
            title="Tutup"
            aria-label="Tutup"
          >
            <Icon d={ICON.close} size={20} />
          </button>
        </div>

        {error && (
          <div class="alert alert-danger" role="alert" style="margin-bottom: 1rem;">
            <span>{error}</span>
          </div>
        )}

        <form
          hx-post={`/pencarian/edit-peraturan/${peraturan.id}`}
          hx-target="#modal-container"
          hx-swap="innerHTML"
        >
          <div class="grid-3">
            <div class="field">
              <label for="er-jenis">Jenis Peraturan <span class="req">*</span></label>
              <select id="er-jenis" name="jenis_peraturan" class="select" required>
                {jenisList.map((j) => (
                  <option value={j} selected={peraturan.jenis_peraturan === j}>{j}</option>
                ))}
              </select>
            </div>
            <div class="field">
              <label for="er-nomor">Nomor <span class="req">*</span></label>
              <input
                type="text"
                id="er-nomor"
                name="nomor"
                class="input"
                value={peraturan.nomor || ''}
                required
              />
            </div>
            <div class="field">
              <label for="er-tahun">Tahun <span class="req">*</span></label>
              <input
                type="number"
                id="er-tahun"
                name="tahun"
                class="input"
                value={peraturan.tahun || ''}
                min="1900"
                max={String(new Date().getFullYear() + 1)}
                required
              />
            </div>
          </div>

          <div class="field">
            <label for="er-judul">Judul Peraturan <span class="req">*</span></label>
            <textarea id="er-judul" name="judul" class="textarea" rows={2} required>{peraturan.judul || ''}</textarea>
          </div>

          <div class="grid-3">
            <div class="field">
              <label for="er-status">Status</label>
              <select id="er-status" name="status" class="select">
                {buildOptions(statusOptions, peraturan.status).map((st) => (
                  <option value={st} selected={(peraturan.status || 'berlaku') === st}>{st.toUpperCase()}</option>
                ))}
              </select>
            </div>
            <div class="field">
              <label for="er-wilayah">Wilayah</label>
              <select id="er-wilayah" name="wilayah" class="select">
                {wilayahList.map((w) => (
                  <option value={w} selected={peraturan.wilayah === w}>{w}</option>
                ))}
              </select>
            </div>
            <div class="field">
              <label for="er-sektor">Sektor</label>
              <select id="er-sektor" name="sektor" class="select">
                {sektorList.map((s) => (
                  <option value={s} selected={peraturan.sektor === s}>{s}</option>
                ))}
              </select>
            </div>
          </div>

          <div class="field">
            <label for="er-url">URL Dokumen Asli <span class="req">*</span></label>
            <input
              type="url"
              id="er-url"
              name="url_dokumen_asli"
              class="input"
              value={peraturan.url_dokumen_asli || ''}
              required
            />
          </div>

          <div class="field">
            <label for="er-status-detail">Keterangan Status <span class="label-hint">(opsional)</span></label>
            <textarea id="er-status-detail" name="status_detail" class="textarea" rows={2}>{peraturan.status_detail || ''}</textarea>
          </div>

          <div class="form-actions">
            <button
              type="button"
              class="btn"
              onclick="document.getElementById('edit-peraturan-modal').remove()"
            >
              Batal
            </button>
            <button type="submit" class="btn btn-primary">
              <Icon d={ICON.check} />
              Simpan Perubahan
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
