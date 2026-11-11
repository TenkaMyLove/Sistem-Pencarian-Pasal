import { jsx } from 'hono/jsx';
import { Layout } from './layout.js';
import { UserSession } from '../middleware/auth.js';

export interface JadwalItem {
  id: number;
  jenis_rancangan: string;
  tentang: string;
  tanggal: string;
  jam: string;
  nama_kompilator: string;
  tim_pokja: string;
  dibuat_oleh: string;
}

interface JadwalViewProps {
  user: UserSession;
  jadwalList: JadwalItem[];
  editItem?: JadwalItem | null;
  showModal?: boolean;
}

function Icon({ d, size = 16 }: { d: string; size?: number }) {
  return (
    <svg width={size} height={size} fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={d}></path>
    </svg>
  );
}

const ICON_PLUS = 'M12 4v16m8-8H4';
const ICON_EDIT = 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z';
const ICON_TRASH = 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16';
const ICON_CLOSE = 'M6 18L18 6M6 6l12 12';

export function JadwalView({ user, jadwalList, editItem = null, showModal = false }: JadwalViewProps) {
  const canEdit = user.peran === 'Pengelola' || user.peran === 'Perancang';

  return (
    <Layout title="Jadwal Rapat Harmonisasi" activeNav="jadwal" user={user}>
      <div class="page-head">
        <div>
          <h2>Agenda Rapat Harmonisasi</h2>
          <p>Daftar jadwal rapat harmonisasi Ranperda dan Ranpergub.</p>
        </div>

        {canEdit && (
          <button class="btn btn-primary" hx-get="/jadwal/modal/tambah" hx-target="#modal-container">
            <Icon d={ICON_PLUS} size={18} />
            Tambah Jadwal
          </button>
        )}
      </div>

      {/* Main Table Container */}
      <div id="jadwal-table-container">
        <JadwalTablePartial user={user} jadwalList={jadwalList} />
      </div>

      {/* Modal Container for HTMX */}
      <div id="modal-container">
        {showModal && <JadwalModalPartial editItem={editItem} />}
      </div>
    </Layout>
  );
}

export function JadwalTablePartial({ user, jadwalList }: { user: UserSession; jadwalList: JadwalItem[] }) {
  const canEdit = user.peran === 'Pengelola' || user.peran === 'Perancang';

  if (!jadwalList || jadwalList.length === 0) {
    return (
      <div class="panel empty-state">
        <h3>Belum ada jadwal rapat harmonisasi</h3>
        <p>Tambahkan jadwal rapat baru untuk memantau proses harmonisasi Ranperda dan Ranpergub.</p>
      </div>
    );
  }

  const formatDate = (dateStr: string) => {
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
    } catch {
      return dateStr;
    }
  };

  return (
    <div class="panel">
      <div class="panel-head">
        <h3>Agenda Rapat Terjadwal ({jadwalList.length})</h3>
      </div>

      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th class="col-num" scope="col">No</th>
              <th scope="col">Jenis</th>
              <th scope="col">Pokok Materi</th>
              <th scope="col">Hari / Tanggal</th>
              <th scope="col">Jam (WITA)</th>
              <th scope="col">Kompilator</th>
              <th scope="col">Tim Pokja</th>
              <th scope="col">Pembuat</th>
              {canEdit && <th class="col-act" scope="col">Aksi</th>}
            </tr>
          </thead>
          <tbody>
            {jadwalList.map((item, idx) => (
              <tr>
                <td class="col-num">{idx + 1}</td>
                <td><span class="tag tag-neutral">{item.jenis_rancangan}</span></td>
                <td style="max-width: 320px;">{item.tentang || '-'}</td>
                <td class="cell-strong">{formatDate(item.tanggal)}</td>
                <td>{item.jam} WITA</td>
                <td class="cell-strong">{item.nama_kompilator}</td>
                <td><span class="tag tag-neutral">{item.tim_pokja}</span></td>
                <td class="cell-mute">{item.dibuat_oleh}</td>
                {canEdit && (
                  <td class="col-act">
                    <button
                      class="btn-icon"
                      hx-get={`/jadwal/modal/edit/${item.id}`}
                      hx-target="#modal-container"
                      title="Ubah Jadwal"
                      aria-label="Ubah Jadwal"
                    >
                      <Icon d={ICON_EDIT} />
                    </button>
                    <button
                      class="btn-icon"
                      style="color: var(--danger);"
                      hx-post={`/jadwal/${item.id}/delete`}
                      hx-target="#jadwal-table-container"
                      hx-confirm="Apakah Anda yakin ingin menghapus jadwal rapat harmonisasi ini?"
                      title="Hapus Jadwal"
                      aria-label="Hapus Jadwal"
                    >
                      <Icon d={ICON_TRASH} />
                    </button>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function JadwalModalPartial({ editItem = null }: { editItem?: JadwalItem | null }) {
  const isEdit = !!editItem;

  let defaultDate = '';
  if (editItem && editItem.tanggal) {
    const d = new Date(editItem.tanggal);
    defaultDate = d.toISOString().split('T')[0];
  } else {
    defaultDate = new Date().toISOString().split('T')[0];
  }

  const standardNames = ['Eryck', 'Kiki', 'Dian', 'Dame', 'Nizar', 'Wyra', 'Dudunk', 'Ryna'];
  const currentNames = editItem?.nama_kompilator
    ? editItem.nama_kompilator.split(',').map((s: string) => s.trim())
    : [];

  const customNames = currentNames.filter(name => !standardNames.includes(name)).join(', ');

  return (
    <div class="modal-backdrop">
      <div class="modal-content" role="dialog" aria-modal="true" aria-labelledby="jadwal-modal-title">
        <div class="modal-header">
          <h3 id="jadwal-modal-title">{isEdit ? 'Ubah Jadwal Rapat Harmonisasi' : 'Tambah Jadwal Rapat Harmonisasi'}</h3>
          <button
            type="button"
            class="modal-close-btn"
            onclick="document.getElementById('modal-container').innerHTML=''"
            title="Tutup"
            aria-label="Tutup"
          >
            <Icon d={ICON_CLOSE} size={20} />
          </button>
        </div>

        <form
          hx-post={isEdit ? `/jadwal/${editItem!.id}/edit` : '/jadwal'}
          hx-target="#jadwal-table-container"
          hx-on="htmx:afterOnLoad: document.getElementById('modal-container').innerHTML=''"
          onsubmit="
            const checked = Array.from(this.querySelectorAll('.kompilator-checkbox:checked')).map(el => el.value);
            const customVal = this.querySelector('#nama_kompilator_custom').value.trim();
            const list = [...checked];
            if (customVal) {
              list.push(...customVal.split(',').map(s => s.trim()));
            }
            this.querySelector('#nama_kompilator').value = list.filter(Boolean).join(', ');
          "
        >
          <div class="field">
            <label for="jenis_rancangan">Jenis Rancangan</label>
            <select id="jenis_rancangan" name="jenis_rancangan" class="select" required>
              <option value="Ranperda" selected={editItem?.jenis_rancangan === 'Ranperda'}>Ranperda (Rancangan Peraturan Daerah)</option>
              <option value="Ranpergub" selected={editItem?.jenis_rancangan === 'Ranpergub' || editItem?.jenis_rancangan === 'Ranperkada'}>Ranpergub (Rancangan Peraturan Gubernur)</option>
            </select>
          </div>

          <div class="field">
            <label for="tentang">Tentang (Pokok Materi)</label>
            <input
              type="text"
              id="tentang"
              name="tentang"
              value={editItem?.tentang || ''}
              class="input"
              placeholder="Ketertiban Umum dan Ketenteraman Masyarakat"
              required
            />
          </div>

          <div class="grid-2">
            <div class="field">
              <label for="tanggal">Hari / Tanggal</label>
              <input type="date" id="tanggal" name="tanggal" value={defaultDate} class="input" required />
            </div>

            <div class="field">
              <label for="jam">Jam Rapat (WITA)</label>
              <input type="time" id="jam" name="jam" value={editItem?.jam || '09:00'} class="input" required />
            </div>
          </div>

          <div class="field">
            <span class="label">Nama Kompilator</span>
            <div class="check-row">
              {standardNames.map(name => (
                <label class="check">
                  <input
                    type="checkbox"
                    class="kompilator-checkbox"
                    value={name}
                    checked={currentNames.includes(name)}
                  />
                  {name}
                </label>
              ))}
            </div>
            <input
              type="text"
              id="nama_kompilator_custom"
              value={customNames}
              class="input"
              aria-label="Nama kompilator lain"
              placeholder="Kompilator lain, pisahkan dengan koma"
            />
            {/* The actual hidden field submitted to the server */}
            <input type="hidden" id="nama_kompilator" name="nama_kompilator" value={editItem?.nama_kompilator || ''} />
          </div>

          <div class="field">
            <label for="tim_pokja">Tim Pokja</label>
            <select id="tim_pokja" name="tim_pokja" class="select" required>
              <option value="Pokja 1" selected={editItem?.tim_pokja === 'Pokja 1'}>Pokja 1</option>
              <option value="Pokja 2" selected={editItem?.tim_pokja === 'Pokja 2'}>Pokja 2</option>
            </select>
          </div>

          <div class="form-actions">
            <button
              type="button"
              class="btn"
              onclick="document.getElementById('modal-container').innerHTML=''"
            >
              Batal
            </button>
            <button type="submit" class="btn btn-primary">
              {isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
