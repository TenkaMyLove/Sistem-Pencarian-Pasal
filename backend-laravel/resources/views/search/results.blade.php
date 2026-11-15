@use('App\Support\TeksHelper')
{{--
    Potongan HTML hasil pencarian (partial, tanpa layout) — dipakai HTMX.
    Variabel: $query, $sektor, $wilayah, $searchData, $user (global)
--}}
@php
    $isPengelola = in_array($user['peran'] ?? '', ['Pengelola', 'Admin']);

    $items = $searchData['items'] ?? [];
    $totalCount = $searchData['totalCount'] ?? 0;
    $currentPage = $searchData['currentPage'] ?? 1;
    $pageSize = $searchData['pageSize'] ?? 1;
    $totalPages = $searchData['totalPages'] ?? 1;

    // Relasi hukum yang ditampilkan sebagai penanda ringkas pada baris hasil
    $relasiTagMap = [
        'mencabut'                => ['label' => 'Mencabut', 'cls' => 'tag-dicabut'],
        'mencabut_sebagian'       => ['label' => 'Mencabut Sebagian', 'cls' => 'tag-dicabut'],
        'mengubah'                => ['label' => 'Mengubah', 'cls' => 'tag-ubah'],
        'dicabut_dengan'          => ['label' => 'Dicabut', 'cls' => 'tag-dicabut'],
        'dicabut_sebagian_dengan' => ['label' => 'Dicabut Sebagian', 'cls' => 'tag-dicabut'],
        'diubah_dengan'           => ['label' => 'Diubah', 'cls' => 'tag-ubah'],
    ];

    // URL halaman tertentu untuk tombol pagination (urlencode supaya aman di URL)
    $pageUrl = fn ($p) => '/search-results?q=' . rawurlencode($query)
        . '&sektor=' . rawurlencode($sektor)
        . '&wilayah=' . rawurlencode($wilayah)
        . '&page=' . $p;
@endphp

@if (count($items) === 0)
    <div class="panel empty-state">
        <h3>Tidak ditemukan pasal yang sesuai dengan kata kunci</h3>
        <p>Gunakan kata kunci yang lebih umum, periksa ejaan, atau atur kembali filter sektor dan wilayah.</p>
    </div>
@else
    @php
        $startItem = ($currentPage - 1) * $pageSize + 1;
        $endItem = min($currentPage * $pageSize, $totalCount);
    @endphp

    <div class="panel">
        <input type="hidden" name="active_page" value="{{ $currentPage }}" />

        <div class="results-summary" style="padding: 1rem 1.5rem;">
            <span>
                Menampilkan <strong>{{ $startItem }} - {{ $endItem }}</strong> dari <strong>{{ $totalCount }}</strong> pasal rujukan
                @if ($query) untuk kata kunci <span class="kw-chip">{{ $query }}</span>@endif
            </span>
        </div>

        <div class="results-scroll">
            @foreach ($items as $item)
                @php
                    $json = TeksHelper::parseStatusJson($item->status_detail_json ?? null);

                    // Kumpulkan penanda relasi yang punya isi
                    $relasiTags = [];
                    foreach ($relasiTagMap as $key => $info) {
                        if (isset($json[$key]) && is_array($json[$key]) && count($json[$key]) > 0) {
                            $relasiTags[] = $info + ['jumlah' => count($json[$key])];
                        }
                    }

                    $hasKeterangan = count($relasiTags) === 0 && $item->status_detail && trim($item->status_detail) !== '';
                    $statusCls = $item->status === 'berlaku' ? 'tag-berlaku' : ($item->status === 'diubah' ? 'tag-ubah' : 'tag-dicabut');
                @endphp

                <article
                    class="result-row"
                    id="{{ $item->pasal_id ? 'card-pasal-' . $item->pasal_id : 'card-peraturan-' . $item->peraturan_id }}"
                >
                    <div class="meta-line">
                        <span class="tag {{ $statusCls }}">{{ $item->status }}</span>
                        @foreach ($relasiTags as $tag)
                            <span class="tag {{ $tag['cls'] }}" title="{{ $tag['label'] }}: {{ $tag['jumlah'] }} peraturan">
                                {{ $tag['label'] }} ({{ $tag['jumlah'] }})
                            </span>
                        @endforeach
                        @if ($hasKeterangan)
                            <span class="tag tag-neutral" title="{{ $item->status_detail }}">Ada Keterangan</span>
                        @endif
                        @if ($item->sektor)
                            <span>Sektor: {{ $item->sektor }}</span>
                            <span class="meta-sep">/</span>
                        @endif
                        <span>Wilayah: {{ $item->wilayah }}</span>
                        <span class="meta-sep">/</span>
                        @if ($item->status_tautan === 'tautan_bermasalah')
                            <span class="meta-bad" title="Tautan dokumen asli di situs sumber mengalami kendala HTTP 404/Error">
                                Tautan Bermasalah
                            </span>
                        @else
                            <span class="meta-ok">Tautan Aktif</span>
                        @endif
                    </div>

                    <h4 class="result-title">
                        {{ $item->jenis_peraturan }} Nomor {{ $item->nomor }} Tahun {{ $item->tahun }}
                    </h4>
                    <p class="result-sub">{{ $item->judul }}</p>

                    @if ($item->pasal_id)
                        <div class="quote">
                            <div class="quote-label">
                                {{ $item->nomor_pasal }} {{ $item->nomor_ayat ?: '' }}
                            </div>
                            {{-- sorot() sudah meng-escape teks, jadi aman dicetak dengan {!! !!} --}}
                            <div class="quote-text">{!! TeksHelper::sorot($item->teks_pasal, $query) !!}</div>
                        </div>
                    @endif

                    <div class="row-actions">
                        <div class="row-actions-group">
                            <button
                                type="button"
                                class="btn btn-sm btn-outline"
                                hx-get="/pencarian/status-modal/{{ $item->peraturan_id }}"
                                hx-target="#modal-container"
                            >
                                {!! TeksHelper::ikon('list') !!}
                                Lihat Detil Status
                            </button>

                            {{-- Tombol di bawah ini hanya untuk Pengelola/Admin --}}
                            @if ($isPengelola)
                                <button
                                    type="button"
                                    class="btn btn-sm"
                                    hx-get="/pencarian/edit-peraturan-modal/{{ $item->peraturan_id }}"
                                    hx-target="#modal-container"
                                    title="Edit data peraturan ini"
                                >
                                    {!! TeksHelper::ikon('edit') !!}
                                    Edit Peraturan
                                </button>

                                @if ($item->pasal_id)
                                    <button
                                        type="button"
                                        class="btn btn-sm"
                                        hx-get="/pencarian/edit-pasal-modal/{{ $item->pasal_id }}"
                                        hx-target="#modal-container"
                                        title="Edit teks pasal ini"
                                    >
                                        {!! TeksHelper::ikon('pencil') !!}
                                        Edit Pasal
                                    </button>
                                @endif

                                {{-- hx-post tanpa form: token CSRF dikirim lewat header <body hx-headers> di layout --}}
                                <button
                                    type="button"
                                    class="btn btn-sm btn-danger-outline"
                                    hx-post="/pencarian/hapus-peraturan/{{ $item->peraturan_id }}"
                                    hx-swap="none"
                                    hx-confirm="Hapus peraturan {{ $item->jenis_peraturan }} No. {{ $item->nomor }} Tahun {{ $item->tahun }} beserta seluruh pasalnya? Tindakan ini tidak dapat dibatalkan."
                                    title="Hapus peraturan ini beserta seluruh pasalnya"
                                >
                                    {!! TeksHelper::ikon('trash') !!}
                                    Hapus Peraturan
                                </button>

                                @if ($item->pasal_id)
                                    <button
                                        type="button"
                                        class="btn btn-sm btn-danger-outline"
                                        hx-post="/pencarian/hapus-pasal/{{ $item->pasal_id }}"
                                        hx-swap="none"
                                        hx-confirm="Hapus {{ $item->nomor_pasal }} dari {{ $item->jenis_peraturan }} No. {{ $item->nomor }} Tahun {{ $item->tahun }}? Tindakan ini tidak dapat dibatalkan."
                                        title="Hapus pasal ini dari database"
                                    >
                                        {!! TeksHelper::ikon('close') !!}
                                        Hapus Pasal
                                    </button>
                                @endif
                            @endif
                        </div>

                        <a
                            href="{{ $item->url_dokumen_asli }}"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="btn btn-sm"
                            title="Buka dokumen asli di situs resmi sumber"
                        >
                            {!! TeksHelper::ikon('external') !!}
                            Dokumen Asli
                        </a>
                    </div>
                </article>
            @endforeach
        </div>

        {{-- Pagination hanya muncul jika halaman lebih dari satu --}}
        @if ($totalPages > 1)
            <nav class="pager" style="border-top: 1px solid var(--border);" aria-label="Halaman hasil pencarian">
                <div class="pager-info">
                    Halaman <strong>{{ $currentPage }}</strong> dari <strong>{{ $totalPages }}</strong>
                </div>
                <div class="pager-pages">
                    <button
                        type="button"
                        class="pager-btn"
                        @disabled($currentPage === 1)
                        hx-get="{{ $pageUrl($currentPage - 1) }}"
                        hx-target="#results-container"
                        hx-indicator="#loading-indicator"
                    >
                        Sebelumnya
                    </button>

                    {{-- jendelaHalaman() mengembalikan daftar nomor; null berarti tampilkan "..." --}}
                    @foreach (TeksHelper::jendelaHalaman($currentPage, $totalPages) as $p)
                        @if ($p === null)
                            <span class="meta-sep" style="padding: 0 0.25rem;">...</span>
                        @else
                            <button
                                type="button"
                                class="pager-btn {{ $p === $currentPage ? 'is-current' : '' }}"
                                @if ($p === $currentPage) aria-current="page" @endif
                                hx-get="{{ $pageUrl($p) }}"
                                hx-target="#results-container"
                                hx-indicator="#loading-indicator"
                            >
                                {{ $p }}
                            </button>
                        @endif
                    @endforeach

                    <button
                        type="button"
                        class="pager-btn"
                        @disabled($currentPage === $totalPages)
                        hx-get="{{ $pageUrl($currentPage + 1) }}"
                        hx-target="#results-container"
                        hx-indicator="#loading-indicator"
                    >
                        Selanjutnya
                    </button>
                </div>
            </nav>
        @endif
    </div>
@endif
