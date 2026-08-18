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

export function JadwalView({ user, jadwalList, editItem = null, showModal = false }: JadwalViewProps) {
  const canEdit = user.peran === 'Pengelola';

  return (
    <Layout title="Manajemen Jadwal Rapat Harmonisasi" activeNav="jadwal" user={user}>
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem;">
        <h3 style="font-size: 1.25rem; font-weight: 700; color: var(--primary-navy);">
          Daftar Jadwal Rapat Harmonisasi Ranperda &amp; Ranperkada
        </h3>

        {canEdit && (
          <button
            class="btn-search"
            hx-get="/jadwal/modal/tambah"
            hx-target="#modal-container"
          >
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            Tambah Jadwal Baru
          </button>
        )}
      </div>

      {user.peran === 'Perancang' && (
        <div class="alert alert-success" style="margin-bottom: 1.5rem;">
          <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <span>Anda masuk sebagai <strong>Perancang (Read-Only)</strong>. Anda dapat melihat seluruh daftar jadwal rapat harmonisasi.</span>
        </div>
      )}

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
  const canEdit = user.peran === 'Pengelola';

  if (!jadwalList || jadwalList.length === 0) {
    return (
      <div class="empty-state">
        <h3>Belum Ada Jadwal Rapat Harmonisasi</h3>
        <p>Silakan tambahkan jadwal rapat baru untuk memantau proses harmonisasi Ranperda/Ranperkada.</p>
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
    <div class="card-table">
      <div class="table-header-bar">
        <h3>Agenda Rapat Terjadwal ({jadwalList.length})</h3>
        <span style="font-size: 0.85rem; color: var(--text-muted);">
          Terakhir diperbarui: Hari ini
        </span>
      </div>

      <table class="data-table">
        <thead>
          <tr>
            <th>No</th>
            <th>Jenis Rancangan</th>
            <th>Tentang</th>
            <th>Hari / Tanggal</th>
            <th>Jam (WITA)</th>
            <th>Nama Kompilator</th>
            <th>Tim Pokja</th>
            {canEdit && <th style="text-align: right; width: 140px;">Aksi</th>}
          </tr>
        </thead>
        <tbody>
          {jadwalList.map((item, idx) => (
            <tr>
              <td>{idx + 1}</td>
              <td>
                <span class="badge badge-jenis">
                  {item.jenis_rancangan}
                </span>
              </td>
              <td style="max-width: 260px; line-height: 1.45;">{item.tentang || '—'}</td>
              <td style="font-weight: 600;">{formatDate(item.tanggal)}</td>
              <td>{item.jam} WITA</td>
              <td style="font-weight: 600; color: var(--primary-navy);">{item.nama_kompilator}</td>
              <td>
                <span class={`badge ${item.tim_pokja === 'Pokja 1' ? 'badge-pokja1' : 'badge-pokja2'}`}>
                  {item.tim_pokja}
                </span>
              </td>
              {canEdit && (
                <td style="text-align: right; white-space: nowrap;">
                  <div style="display: inline-flex; gap: 0.35rem; justify-content: flex-end; align-items: center; width: 100%;">
                    <button
                      class="btn-action btn-edit"
                      hx-get={`/jadwal/modal/edit/${item.id}`}
                      hx-target="#modal-container"
                      title="Ubah Jadwal"
                      style="margin: 0;"
                    >
                      Edit
                    </button>
                    <button
                      class="btn-action btn-delete"
                      hx-post={`/jadwal/${item.id}/delete`}
                      hx-target="#jadwal-table-container"
                      hx-confirm="Apakah Anda yakin ingin menghapus jadwal rapat harmonisasi ini?"
                      title="Hapus Jadwal"
                      style="margin: 0;"
                    >
                      Hapus
                    </button>
                  </div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
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
      <div class="modal-content">
        <div class="modal-header">
          <h3>{isEdit ? 'Ubah Jadwal Rapat Harmonisasi' : 'Tambah Jadwal Rapat Harmonisasi'}</h3>
          <button
            type="button"
            onclick="document.getElementById('modal-container').innerHTML=''"
            style="background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-muted);"
          >
            &times;
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
          <div class="form-group">
            <label for="jenis_rancangan">Jenis Rancangan</label>
            <select id="jenis_rancangan" name="jenis_rancangan" class="form-control" required>
              <option value="Ranperda" selected={editItem?.jenis_rancangan === 'Ranperda'}>Ranperda (Rancangan Peraturan Daerah)</option>
              <option value="Ranperkada" selected={editItem?.jenis_rancangan === 'Ranperkada'}>Ranperkada (Rancangan Peraturan Kepala Daerah)</option>
            </select>
          </div>

          <div class="form-group">
            <label for="tentang">Tentang (Judul / Pokok Materi)</label>
            <input
              type="text"
              id="tentang"
              name="tentang"
              value={editItem?.tentang || ''}
              class="form-control"
              placeholder="Contoh: Ketertiban Umum dan Ketenteraman Masyarakat"
              required
            />
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
            <div class="form-group">
              <label for="tanggal">Hari / Tanggal</label>
              <input
                type="date"
                id="tanggal"
                name="tanggal"
                value={defaultDate}
                class="form-control"
                required
              />
            </div>

            <div class="form-group">
              <label for="jam">Jam Rapat (WITA)</label>
              <input
                type="time"
                id="jam"
                name="jam"
                value={editItem?.jam || '09:00'}
                class="form-control"
                required
              />
            </div>
          </div>

          <div class="form-group">
            <label style="font-weight: 600; margin-bottom: 0.4rem; display: block;">Nama Kompilator / Penyusun</label>
            <div style="display: flex; gap: 1rem; margin-top: 0.25rem; margin-bottom: 0.5rem; flex-wrap: wrap;">
              {standardNames.map(name => {
                const isChecked = currentNames.includes(name);
                return (
                  <label style="display: flex; align-items: center; gap: 0.35rem; font-weight: 500; cursor: pointer;">
                    <input
                      type="checkbox"
                      class="kompilator-checkbox"
                      value={name}
                      checked={isChecked}
                      style="cursor: pointer;"
                    />
                    {name}
                  </label>
                );
              })}
            </div>
            <input
              type="text"
              id="nama_kompilator_custom"
              value={customNames}
              class="form-control"
              placeholder="Nama Kompilator Lain (jika ada, pisahkan dengan koma)"
            />
            {/* The actual hidden field submitted to the server */}
            <input
              type="hidden"
              id="nama_kompilator"
              name="nama_kompilator"
              value={editItem?.nama_kompilator || ''}
            />
          </div>

          <div class="form-group">
            <label for="tim_pokja">Tim Pokja (Kelompok Kerja)</label>
            <select id="tim_pokja" name="tim_pokja" class="form-control" required>
              <option value="Pokja 1" selected={editItem?.tim_pokja === 'Pokja 1'}>Pokja 1</option>
              <option value="Pokja 2" selected={editItem?.tim_pokja === 'Pokja 2'}>Pokja 2</option>
            </select>
          </div>

          <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem;">
            <button
              type="button"
              class="btn-action"
              onclick="document.getElementById('modal-container').innerHTML=''"
              style="background-color: #f1f5f9; color: var(--text-main);"
            >
              Tutup
            </button>
            <button type="submit" class="btn-action btn-primary" style="padding: 0.6rem 1.25rem;">
              {isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
