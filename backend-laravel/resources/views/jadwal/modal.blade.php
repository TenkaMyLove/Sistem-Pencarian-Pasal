{{--
    Partial modal tambah/ubah jadwal (dimuat oleh HTMX ke #modal-container).
    Variabel: $editItem (JadwalRapat atau null; null = mode tambah).
--}}
@php
    $isEdit = !empty($editItem);

    // Nilai awal tanggal & jam
    $defaultDate = $isEdit ? $editItem->tanggal->format('Y-m-d') : now()->format('Y-m-d');
    $defaultJam  = $isEdit ? substr($editItem->jam, 0, 5) : '09:00';

    // Nama kompilator standar (dari config/p3h.php)
    $standardNames = config('p3h.kompilator');

    // Nama kompilator yang tersimpan -> array, mis. "Eryck, Kiki" => ['Eryck', 'Kiki']
    $currentNames = ($isEdit && $editItem->nama_kompilator)
        ? array_map('trim', explode(',', $editItem->nama_kompilator))
        : [];

    // Nama yang BUKAN nama standar masuk ke kolom "kompilator lain"
    $customNames = implode(', ', array_filter($currentNames, fn ($n) => !in_array($n, $standardNames)));

    $jenis = $isEdit ? $editItem->jenis_rancangan : null;
    $pokja = $isEdit ? $editItem->tim_pokja : null;
@endphp

<div class="modal-backdrop">
    <div class="modal-content" role="dialog" aria-modal="true" aria-labelledby="jadwal-modal-title">
        <div class="modal-header">
            <h3 id="jadwal-modal-title">{{ $isEdit ? 'Ubah Jadwal Rapat Harmonisasi' : 'Tambah Jadwal Rapat Harmonisasi' }}</h3>
            <button
                type="button"
                class="modal-close-btn"
                onclick="document.getElementById('modal-container').innerHTML=''"
                title="Tutup"
                aria-label="Tutup"
            >
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>

        {{--
            Form dikirim lewat HTMX (hx-post). Token CSRF sudah ada di hx-headers layout,
            @csrf ditambahkan juga supaya form tetap aman.
            onsubmit: sebelum dikirim, nama yang dicentang + kolom "lain" digabung
            menjadi satu teks (dipisah koma) ke input hidden #nama_kompilator.
        --}}
        <form
            hx-post="{{ $isEdit ? '/jadwal/' . $editItem->id . '/edit' : '/jadwal' }}"
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
            @csrf

            <div class="field">
                <label for="jenis_rancangan">Jenis Rancangan</label>
                <select id="jenis_rancangan" name="jenis_rancangan" class="select" required>
                    <option value="Ranperda" @selected($jenis === 'Ranperda')>Ranperda (Rancangan Peraturan Daerah)</option>
                    <option value="Ranpergub" @selected($jenis === 'Ranpergub' || $jenis === 'Ranperkada')>Ranpergub (Rancangan Peraturan Gubernur)</option>
                </select>
            </div>

            <div class="field">
                <label for="tentang">Tentang (Pokok Materi)</label>
                <input
                    type="text"
                    id="tentang"
                    name="tentang"
                    value="{{ $isEdit ? $editItem->tentang : '' }}"
                    class="input"
                    placeholder="Ketertiban Umum dan Ketenteraman Masyarakat"
                    required
                >
            </div>

            <div class="grid-2">
                <div class="field">
                    <label for="tanggal">Hari / Tanggal</label>
                    <input type="date" id="tanggal" name="tanggal" value="{{ $defaultDate }}" class="input" required>
                </div>

                <div class="field">
                    <label for="jam">Jam Rapat (WITA)</label>
                    <input type="time" id="jam" name="jam" value="{{ $defaultJam }}" class="input" required>
                </div>
            </div>

            <div class="field">
                <span class="label">Nama Kompilator</span>
                <div class="check-row">
                    @foreach ($standardNames as $name)
                        <label class="check">
                            <input
                                type="checkbox"
                                class="kompilator-checkbox"
                                value="{{ $name }}"
                                @checked(in_array($name, $currentNames))
                            >
                            {{ $name }}
                        </label>
                    @endforeach
                </div>
                <input
                    type="text"
                    id="nama_kompilator_custom"
                    value="{{ $customNames }}"
                    class="input"
                    aria-label="Nama kompilator lain"
                    placeholder="Kompilator lain, pisahkan dengan koma"
                >
                {{-- Input tersembunyi yang sebenarnya dikirim ke server --}}
                <input type="hidden" id="nama_kompilator" name="nama_kompilator" value="{{ $isEdit ? $editItem->nama_kompilator : '' }}">
            </div>

            <div class="field">
                <label for="tim_pokja">Tim Pokja</label>
                <select id="tim_pokja" name="tim_pokja" class="select" required>
                    <option value="Pokja 1" @selected($pokja === 'Pokja 1')>Pokja 1</option>
                    <option value="Pokja 2" @selected($pokja === 'Pokja 2')>Pokja 2</option>
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
                    {{ $isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal' }}
                </button>
            </div>
        </form>
    </div>
</div>
