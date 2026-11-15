@use('App\Support\TeksHelper')
{{--
    Popup "Edit Data Peraturan" — hanya untuk Pengelola/Admin (partial, tanpa layout).
    Variabel: $peraturan (model atau stdClass), $error (teks atau null)
--}}
@php
    // Jika nilai saat ini tidak ada di daftar pilihan, tambahkan di paling atas
    // supaya data lama tidak hilang saat disimpan.
    $buatOpsi = function (array $daftar, $nilai) {
        $nilai = trim((string) $nilai);

        return ($nilai !== '' && ! in_array($nilai, $daftar, true)) ? array_merge([$nilai], $daftar) : $daftar;
    };

    $jenisList = $buatOpsi(config('p3h.jenis'), $peraturan->jenis_peraturan ?? '');
    $wilayahList = $buatOpsi(config('p3h.wilayah'), $peraturan->wilayah ?? '');
    $sektorList = $buatOpsi(config('p3h.sektor'), $peraturan->sektor ?? '');
    $statusList = $buatOpsi(['berlaku', 'diubah', 'dicabut'], $peraturan->status ?? '');
@endphp

<div class="modal-backdrop" id="edit-peraturan-modal" onclick="if(event.target===this)this.remove()">
    <div class="modal-content modal-wide" role="dialog" aria-modal="true" aria-labelledby="edit-peraturan-title">
        <div class="modal-header">
            <div>
                <h3 id="edit-peraturan-title">Edit Data Peraturan</h3>
                <p>Peraturan ID #{{ $peraturan->id }}</p>
            </div>
            <button
                type="button"
                onclick="document.getElementById('edit-peraturan-modal').remove()"
                class="modal-close-btn"
                title="Tutup"
                aria-label="Tutup"
            >
                {!! TeksHelper::ikon('close', 20) !!}
            </button>
        </div>

        @if (! empty($error))
            <div class="alert alert-danger" role="alert" style="margin-bottom: 1rem;">
                <span>{{ $error }}</span>
            </div>
        @endif

        {{-- Form dikirim lewat HTMX (POST); respons HTML mengganti isi #modal-container --}}
        <form
            hx-post="/pencarian/edit-peraturan/{{ $peraturan->id }}"
            hx-target="#modal-container"
            hx-swap="innerHTML"
        >
            @csrf
            <div class="grid-3">
                <div class="field">
                    <label for="er-jenis">Jenis Peraturan <span class="req">*</span></label>
                    <select id="er-jenis" name="jenis_peraturan" class="select" required>
                        @foreach ($jenisList as $j)
                            <option value="{{ $j }}" @selected(($peraturan->jenis_peraturan ?? '') === $j)>{{ $j }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field">
                    <label for="er-nomor">Nomor <span class="req">*</span></label>
                    <input
                        type="text"
                        id="er-nomor"
                        name="nomor"
                        class="input"
                        value="{{ $peraturan->nomor ?: '' }}"
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
                        value="{{ $peraturan->tahun ?: '' }}"
                        min="1900"
                        max="{{ date('Y') + 1 }}"
                        required
                    />
                </div>
            </div>

            <div class="field">
                <label for="er-judul">Judul Peraturan <span class="req">*</span></label>
                <textarea id="er-judul" name="judul" class="textarea" rows="2" required>{{ $peraturan->judul ?: '' }}</textarea>
            </div>

            <div class="grid-3">
                <div class="field">
                    <label for="er-status">Status</label>
                    <select id="er-status" name="status" class="select">
                        @foreach ($statusList as $st)
                            <option value="{{ $st }}" @selected((($peraturan->status ?? '') ?: 'berlaku') === $st)>{{ strtoupper($st) }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field">
                    <label for="er-wilayah">Wilayah</label>
                    <select id="er-wilayah" name="wilayah" class="select">
                        @foreach ($wilayahList as $w)
                            <option value="{{ $w }}" @selected(($peraturan->wilayah ?? '') === $w)>{{ $w }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field">
                    <label for="er-sektor">Sektor</label>
                    <select id="er-sektor" name="sektor" class="select">
                        @foreach ($sektorList as $s)
                            <option value="{{ $s }}" @selected(($peraturan->sektor ?? '') === $s)>{{ $s }}</option>
                        @endforeach
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
                    value="{{ $peraturan->url_dokumen_asli ?: '' }}"
                    required
                />
            </div>

            <div class="field">
                <label for="er-status-detail">Keterangan Status <span class="label-hint">(opsional)</span></label>
                <textarea id="er-status-detail" name="status_detail" class="textarea" rows="2">{{ $peraturan->status_detail ?: '' }}</textarea>
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
                    {!! TeksHelper::ikon('check') !!}
                    Simpan Perubahan
                </button>
            </div>
        </form>
    </div>
</div>
