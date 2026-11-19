@use('App\Support\TeksHelper')
{{--
    Popup "Edit Pasal" — khusus untuk Pengelola (partial, tanpa layout).
    Variabel: $pasal (model atau stdClass), $error (teks atau null)
--}}
<div class="modal-backdrop" id="edit-pasal-modal" onclick="if(event.target===this)this.remove()">
    <div class="modal-content" role="dialog" aria-modal="true" aria-labelledby="edit-pasal-title">
        <div class="modal-header">
            <div>
                <h3 id="edit-pasal-title">Edit Pasal</h3>
                <p>Pasal ID #{{ $pasal->id }} &middot; Peraturan ID #{{ $pasal->peraturan_id }}</p>
            </div>
            <button
                type="button"
                onclick="document.getElementById('edit-pasal-modal').remove()"
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
            hx-post="/pencarian/edit-pasal/{{ $pasal->id }}"
            hx-target="#modal-container"
            hx-swap="innerHTML"
        >
            @csrf
            <div class="field">
                <label for="ep-nomor-pasal">Nomor Pasal <span class="req">*</span></label>
                <input
                    type="text"
                    id="ep-nomor-pasal"
                    name="nomor_pasal"
                    class="input"
                    value="{{ $pasal->nomor_pasal ?: '' }}"
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
                    value="{{ $pasal->nomor_ayat ?: '' }}"
                    placeholder="Ayat (1)"
                />
            </div>

            <div class="field">
                <label for="ep-teks-pasal">Teks Pasal <span class="req">*</span></label>
                <textarea
                    id="ep-teks-pasal"
                    name="teks_pasal"
                    class="textarea textarea-mono"
                    rows="8"
                    required
                >{{ $pasal->teks_pasal ?: '' }}</textarea>
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
                    {!! TeksHelper::ikon('check') !!}
                    Simpan Perubahan
                </button>
            </div>
        </form>
    </div>
</div>
