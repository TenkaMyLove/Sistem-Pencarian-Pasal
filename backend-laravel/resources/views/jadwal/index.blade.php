{{--
    Halaman Jadwal Rapat Harmonisasi.
    Variabel: $jadwalList (Collection of JadwalRapat), $user (dibagikan otomatis).
--}}
@extends('layouts.app', ['title' => 'Jadwal Rapat Harmonisasi', 'activeNav' => 'jadwal'])

@section('content')
    @php
        // Hanya Pengelola & Perancang yang boleh menambah/ubah/hapus jadwal
        $canEdit = in_array($user['peran'], ['Pengelola', 'Perancang']);
    @endphp

    <div class="page-head">
        <div>
            <h2>Agenda Rapat Harmonisasi</h2>
            <p>Daftar jadwal rapat harmonisasi Ranperda dan Ranpergub.</p>
        </div>

        @if ($canEdit)
            {{-- hx-get: HTMX mengambil form modal dari server lalu menaruhnya di #modal-container --}}
            <button class="btn btn-primary" hx-get="/jadwal/modal/tambah" hx-target="#modal-container">
                <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Tambah Jadwal
            </button>
        @endif
    </div>

    {{-- Filter tab: Terjadwal / Berlalu --}}
    <div class="jadwal-filter-bar">
        <button class="jadwal-filter-btn active" onclick="filterJadwal(this,'aktif')">
            Terjadwal <span class="jadwal-filter-count" id="count-aktif">0</span>
        </button>
        <button class="jadwal-filter-btn" onclick="filterJadwal(this,'berlalu')">
            Berlalu <span class="jadwal-filter-count" id="count-berlalu">0</span>
        </button>
    </div>

    {{-- Wadah tabel utama (diganti oleh HTMX setelah tambah/ubah/hapus) --}}
    <div id="jadwal-table-container">
        @include('jadwal.table')
    </div>

    {{-- Wadah modal untuk HTMX --}}
    <div id="modal-container"></div>

    <style>
        .jadwal-filter-bar {
            display: flex;
            gap: 0.25rem;
            margin-bottom: 1rem;
            background: #e2e8f0;
            border-radius: 0.5rem;
            padding: 0.25rem;
            width: fit-content;
        }
        .jadwal-filter-btn {
            display: inline-flex;
            align-items: center;
            gap: 0.375rem;
            padding: 0.4rem 0.875rem;
            border: none;
            border-radius: 0.375rem;
            background: transparent;
            color: #64748b;
            font-size: 0.8125rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s;
            white-space: nowrap;
        }
        .jadwal-filter-btn:hover { color: #334155; }
        .jadwal-filter-btn.active {
            background: #fff;
            color: #0f172a;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        }
        .jadwal-filter-count {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 1.25rem;
            height: 1.25rem;
            padding: 0 0.325rem;
            border-radius: 999px;
            font-size: 0.6875rem;
            font-weight: 700;
            background: #cbd5e1;
            color: #475569;
        }
        .jadwal-filter-btn.active .jadwal-filter-count {
            background: #1e3a5f;
            color: #fff;
        }
        [data-jadwal].jadwal-hidden { display: none !important; }
    </style>

    <script>
    (function() {
        var cur = 'aktif';

        window.filterJadwal = function(btn, filter) {
            cur = filter;
            document.querySelectorAll('.jadwal-filter-btn').forEach(function(b) { b.classList.remove('active'); });
            btn.classList.add('active');
            apply();
        };

        function apply() {
            document.querySelectorAll('[data-jadwal]').forEach(function(el) {
                el.classList.toggle('jadwal-hidden', el.dataset.jadwal !== cur);
            });
            counts();
            heading();
        }

        function counts() {
            var a = document.querySelectorAll('tr[data-jadwal="aktif"]').length;
            var b = document.querySelectorAll('tr[data-jadwal="berlalu"]').length;
            var ca = document.getElementById('count-aktif');
            var cb = document.getElementById('count-berlalu');
            if (ca) ca.textContent = a;
            if (cb) cb.textContent = b;
        }

        function heading() {
            var h = document.querySelector('.panel-head h3');
            if (!h) return;
            var n = document.querySelectorAll('tr[data-jadwal="' + cur + '"]').length;
            h.textContent = (cur === 'aktif' ? 'Agenda Rapat Terjadwal' : 'Agenda Rapat Berlalu') + ' (' + n + ')';
        }

        // Re-apply filter after HTMX swaps the table
        document.body.addEventListener('htmx:afterSwap', function(e) {
            if (e.detail.target && e.detail.target.id === 'jadwal-table-container') apply();
        });

        // Init on load
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', apply);
        } else {
            apply();
        }
    })();
    </script>
@endsection
