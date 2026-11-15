@use('App\Support\TeksHelper')
{{--
    Popup "Detil Status Peraturan" (partial, tanpa layout).
    Variabel: $peraturan (model App\Models\Peraturan)
--}}
@php
    $json = TeksHelper::parseStatusJson($peraturan->status_detail_json);

    // Label yang mudah dibaca untuk kunci hasil crawler BPK
    $labelMap = [
        'mencabut'                => 'Mencabut',
        'mencabut_sebagian'       => 'Mencabut Sebagian',
        'diubah_dengan'           => 'Diubah Dengan',
        'dicabut_dengan'          => 'Dicabut Dengan',
        'dicabut_sebagian_dengan' => 'Dicabut Sebagian Dengan',
        'mengubah'                => 'Mengubah',
        'diubah'                  => 'Diubah',
        'perubahan'               => 'Perubahan',
        'peraturan_terkait'       => 'Peraturan Terkait',
    ];

    // Hanya kunci yang isinya daftar tidak kosong
    $keys = array_values(array_filter(array_keys($json), fn ($key) => is_array($json[$key]) && count($json[$key]) > 0));

    $adaStatusDetail = $peraturan->status_detail && trim($peraturan->status_detail) !== '';
@endphp

<div class="modal-backdrop" id="status-modal" onclick="if(event.target===this)this.remove()">
    <div class="modal-content modal-wide" role="dialog" aria-modal="true" aria-labelledby="status-modal-title">
        <div class="modal-header">
            <div>
                <span class="section-label">Pemeriksaan Yuridis</span>
                <h3 id="status-modal-title">Detil Status Peraturan</h3>
                <p>
                    {{ $peraturan->jenis_peraturan }} No. {{ $peraturan->nomor }} Tahun {{ $peraturan->tahun }}
                </p>
            </div>
            <button
                type="button"
                onclick="document.getElementById('status-modal').remove()"
                class="modal-close-btn"
                title="Tutup"
                aria-label="Tutup"
            >
                {!! TeksHelper::ikon('close', 20) !!}
            </button>
        </div>

        <p class="cell-strong" style="margin-bottom: 1rem; line-height: 24px;">{{ $peraturan->judul }}</p>

        <div>
            @if (count($keys) > 0)
                @foreach ($keys as $key)
                    <section class="rel-group">
                        <h4 class="section-label">{{ $labelMap[$key] ?? str_replace('_', ' ', $key) }}</h4>
                        <div class="rel-list">
                            @foreach ($json[$key] as $item)
                                @php
                                    $url = $item['url'] ?? '';
                                    $judul = ($item['judul'] ?? '') ?: ($item['label'] ?? '');
                                @endphp
                                <div class="rel-item">
                                    <div style="min-width: 0;">
                                        <div class="rel-title">
                                            @if ($url)
                                                <a href="{{ $url }}" target="_blank" rel="noopener noreferrer">
                                                    {{ $judul ?: 'Lihat Dokumen' }}
                                                    {!! TeksHelper::ikon('external', 12) !!}
                                                </a>
                                            @else
                                                <span>{{ $judul ?: '-' }}</span>
                                            @endif
                                        </div>
                                        @if (! empty($item['keterangan']))
                                            <div class="rel-note">{!! TeksHelper::keterangan($item['keterangan']) !!}</div>
                                        @endif
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    </section>
                @endforeach
            @elseif ($adaStatusDetail)
                {{-- Cadangan: tidak ada data JSON, pecah teks status_detail per titik koma (;) --}}
                @php
                    $segments = array_values(array_filter(array_map('trim', explode(';', $peraturan->status_detail)), fn ($s) => $s !== ''));
                @endphp
                <section class="rel-group">
                    <h4 class="section-label">Keterangan Status</h4>
                    <div class="rel-list">
                        @foreach ($segments as $seg)
                            <div class="rel-item">
                                <div style="font-size: 14px; line-height: 22px;">{!! TeksHelper::tautkanPeraturan($seg) !!}</div>
                            </div>
                        @endforeach
                    </div>
                </section>
            @else
                <p class="cell-mute" style="text-align: center; padding: 1rem;">
                    Tidak ada data status tambahan tersedia.
                </p>
            @endif
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
