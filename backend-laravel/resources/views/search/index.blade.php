@extends('layouts.app', ['title' => 'Pencarian Pasal Peraturan', 'activeNav' => 'pencarian'])
@use('App\Support\TeksHelper')

{{--
    Halaman Pencarian Pasal.
    Variabel: $initialQuery, $searchData, $sektorList, $wilayahList
    Cara kerja HTMX: setiap input/filter memanggil GET /search-results, lalu HTML
    yang dikembalikan dipasang ke dalam #results-container (tanpa reload halaman).
--}}
@section('content')
    <div class="panel filter-panel">
        {{-- Form GET (hanya membaca data), jadi tidak perlu @csrf --}}
        <form
            hx-get="/search-results"
            hx-target="#results-container"
            hx-trigger="submit"
            hx-indicator="#loading-indicator"
        >
            <div class="filter-row">
                <div class="search-field">
                    {!! TeksHelper::ikon('search', 20) !!}
                    <input
                        type="text"
                        name="q"
                        value="{{ $initialQuery }}"
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
                    {!! TeksHelper::ikon('search', 18) !!}
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
                        @foreach ($sektorList as $s)
                            <option value="{{ $s }}">{{ $s }}</option>
                        @endforeach
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
                        @foreach ($wilayahList as $w)
                            <option value="{{ $w }}">{{ $w }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <span id="loading-indicator" class="htmx-indicator loading-text">
                Memuat hasil pencarian...
            </span>
        </form>
    </div>

    {{-- Wadah hasil. Dimuat ulang otomatis saat server mengirim event "refreshResults" (setelah edit/hapus) --}}
    <div
        id="results-container"
        hx-get="/search-results"
        hx-trigger="refreshResults from:body"
        hx-include="[name='q'], [name='sektor'], [name='wilayah'], [name='active_page']"
        hx-indicator="#loading-indicator"
    >
        @include('search.results', ['query' => $initialQuery, 'sektor' => '', 'wilayah' => '', 'searchData' => $searchData])
    </div>

    {{-- Wadah popup (modal) yang diisi HTMX --}}
    <div id="modal-container"></div>
@endsection
