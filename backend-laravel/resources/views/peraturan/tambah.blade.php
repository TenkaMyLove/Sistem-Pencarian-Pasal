{{--
    Halaman Tambah Peraturan via tautan.
    Variabel:
      $result     : array hasil proses (ok, judul, status_tautan, pasal_count, peraturan_id, error) atau null
      $formValues : array isian form sebelumnya (boleh kosong)
      $error      : pesan kesalahan (string atau null)
    Daftar pilihan dari config/p3h.php (jenis, wilayah, sektor).
--}}
@extends('layouts.app', ['title' => 'Tambah Peraturan', 'activeNav' => 'tambah-peraturan'])

@section('content')
    @php
        $v = $formValues ?? [];
        $result = $result ?? null;

        $iconAlert = 'M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
        $iconOk = 'M5 13l4 4L19 7';
    @endphp

    <div class="page-head">
        <div>
            <h2>Tambah Peraturan via Tautan</h2>
            <p>Indeks peraturan dan pasal baru dari tautan resmi portal hukum, atau lengkapi dengan teks manual.</p>
        </div>
    </div>

    {{-- Pesan kesalahan umum --}}
    @if (!empty($error))
        <div class="alert alert-danger" role="alert">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $iconAlert }}"></path>
            </svg>
            <span>{{ $error }}</span>
        </div>
    @endif

    {{-- Hasil proses penambahan (berhasil / gagal) --}}
    @if (!empty($result))
        <div class="{{ $result['ok'] ? 'alert alert-success' : 'alert alert-danger' }}" role="status">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $result['ok'] ? $iconOk : $iconAlert }}"></path>
            </svg>
            <div class="alert-body" style="flex: 1;">
                @if ($result['ok'])
                    <span class="alert-title">Peraturan berhasil ditambahkan</span>
                    <dl class="kv">
                        <dt>Judul</dt>
                        <dd>{{ $result['judul'] }}</dd>
                        <dt>Pasal Ditemukan</dt>
                        <dd>{{ $result['pasal_count'] }} pasal</dd>
                    </dl>
                    @if ($result['pasal_count'] === 0)
                        <span>
                            Isi pasal belum terbaca otomatis dari tautan. Peraturan tetap tersimpan dan dapat dicari berdasarkan judulnya. Untuk menambahkan isi pasal, tempel teks peraturan pada kolom Teks Isi Peraturan lalu tambahkan ulang.
                        </span>
                    @endif
                    @if (!empty($result['peraturan_id']))
                        <div style="margin-top: 0.5rem;">
                            {{-- rawurlencode = padanan encodeURIComponent di JavaScript --}}
                            <a
                                href="/pencarian?q={{ rawurlencode(mb_substr($result['judul'], 0, 40)) }}"
                                class="btn btn-sm btn-primary"
                            >
                                Cari di Pencarian Pasal
                            </a>
                        </div>
                    @endif
                @else
                    <span class="alert-title">Gagal menyimpan: {{ $result['error'] ?? '' }}</span>
                @endif
            </div>
        </div>
    @endif

    <div class="split">
        {{-- Form metadata peraturan --}}
        <form class="panel" action="/tambah-peraturan" method="post">
            @csrf

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
                        value="{{ $v['url'] ?? '' }}"
                        placeholder="https://peraturan.bpk.go.id/Details/12345/..."
                        required
                    >
                </div>

                <div class="grid-3">
                    <div class="field">
                        <label for="jenis_peraturan">Jenis Peraturan <span class="req">*</span></label>
                        <select id="jenis_peraturan" name="jenis_peraturan" class="select" required>
                            @foreach (config('p3h.jenis') as $j)
                                <option value="{{ $j }}" @selected(($v['jenis_peraturan'] ?? '') === $j)>{{ $j }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="field">
                        <label for="nomor">Nomor <span class="req">*</span></label>
                        <input type="text" id="nomor" name="nomor" class="input" value="{{ $v['nomor'] ?? '' }}" placeholder="23" required>
                    </div>
                    <div class="field">
                        <label for="tahun">Tahun <span class="req">*</span></label>
                        <input
                            type="number"
                            id="tahun"
                            name="tahun"
                            class="input"
                            value="{{ !empty($v['tahun']) ? $v['tahun'] : now()->year }}"
                            min="1900"
                            max="{{ now()->year + 1 }}"
                            required
                        >
                    </div>
                </div>

                <div class="field">
                    <label for="judul">Judul Peraturan <span class="label-hint">(opsional)</span></label>
                    <input
                        type="text"
                        id="judul"
                        name="judul"
                        class="input"
                        value="{{ $v['judul'] ?? '' }}"
                        placeholder="Diambil dari halaman sumber jika dikosongkan"
                    >
                </div>

                <div class="grid-2">
                    <div class="field">
                        <label for="wilayah">Wilayah <span class="req">*</span></label>
                        <select id="wilayah" name="wilayah" class="select" required>
                            @foreach (config('p3h.wilayah') as $w)
                                {{-- Jika belum ada pilihan sebelumnya, "Nasional" terpilih --}}
                                <option value="{{ $w }}" @selected(($v['wilayah'] ?? '') === $w || (empty($v['wilayah']) && $w === 'Nasional'))>{{ $w }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="field">
                        <label for="sektor">Sektor <span class="req">*</span></label>
                        <select id="sektor" name="sektor" class="select" required>
                            @foreach (config('p3h.sektor') as $s)
                                <option value="{{ $s }}" @selected(($v['sektor'] ?? '') === $s)>{{ $s }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                {{-- Teks manual: dipakai jika halaman sumber (mis. PDF) tidak bisa diurai otomatis --}}
                <div class="field">
                    <label for="teks_pasal_manual">Teks Isi Peraturan <span class="label-hint">(opsional)</span></label>
                    <textarea
                        id="teks_pasal_manual"
                        name="teks_pasal_manual"
                        class="textarea textarea-mono"
                        rows="10"
                        placeholder="Tempel teks lengkap peraturan.&#10;Baris 'Pasal N' akan dideteksi dan diekstrak otomatis."
                    ></textarea>
                </div>

                <div class="form-actions">
                    <a href="/pencarian" class="btn">Batal</a>
                    <button type="submit" class="btn btn-primary">
                        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"></path>
                        </svg>
                        Tambahkan
                    </button>
                </div>
            </div>
        </form>

        {{-- Panel petunjuk --}}
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
@endsection
