{{--
    Partial tabel jadwal (dipakai di halaman jadwal & dikirim ulang oleh HTMX).
    Variabel: $jadwalList (Collection of JadwalRapat), $user (dibagikan otomatis).
--}}
@php
    $canEdit = in_array($user['peran'], ['Pengelola', 'Perancang']);
@endphp

@if ($jadwalList->isEmpty())
    <div class="panel empty-state">
        <h3>Belum ada jadwal rapat harmonisasi</h3>
        <p>Tambahkan jadwal rapat baru untuk memantau proses harmonisasi Ranperda dan Ranpergub.</p>
    </div>
@else
    <div class="panel">
        <div class="panel-head">
            <h3>Agenda Rapat Terjadwal ({{ $jadwalList->count() }})</h3>
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
                        @if ($canEdit)
                            <th class="col-act" scope="col">Aksi</th>
                        @endif
                    </tr>
                </thead>
                <tbody>
                    @foreach ($jadwalList as $item)
                        <tr>
                            {{-- $loop->iteration = nomor urut mulai dari 1 --}}
                            <td class="col-num">{{ $loop->iteration }}</td>
                            <td><span class="tag tag-neutral">{{ $item->jenis_rancangan }}</span></td>
                            <td style="max-width: 320px;">{{ $item->tentang ?: '-' }}</td>
                            {{-- Contoh hasil: "Senin, 3 November 2025" --}}
                            <td class="cell-strong">{{ $item->tanggal->translatedFormat('l, j F Y') }}</td>
                            {{-- Jam disimpan 'HH:MM:SS', kita tampilkan 5 karakter pertama (HH:MM) --}}
                            <td>{{ substr($item->jam, 0, 5) }} WITA</td>
                            <td class="cell-strong">{{ $item->nama_kompilator }}</td>
                            <td><span class="tag tag-neutral">{{ $item->tim_pokja }}</span></td>
                            <td class="cell-mute">{{ $item->dibuat_oleh }}</td>
                            @if ($canEdit)
                                <td class="col-act">
                                    <button
                                        class="btn-icon"
                                        hx-get="/jadwal/modal/edit/{{ $item->id }}"
                                        hx-target="#modal-container"
                                        title="Ubah Jadwal"
                                        aria-label="Ubah Jadwal"
                                    >
                                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                                        </svg>
                                    </button>
                                    <button
                                        class="btn-icon"
                                        style="color: var(--danger);"
                                        hx-post="/jadwal/{{ $item->id }}/delete"
                                        hx-target="#jadwal-table-container"
                                        hx-confirm="Apakah Anda yakin ingin menghapus jadwal rapat harmonisasi ini?"
                                        title="Hapus Jadwal"
                                        aria-label="Hapus Jadwal"
                                    >
                                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                        </svg>
                                    </button>
                                </td>
                            @endif
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
@endif
