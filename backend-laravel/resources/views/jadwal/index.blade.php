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

    {{-- Wadah tabel utama (diganti oleh HTMX setelah tambah/ubah/hapus) --}}
    <div id="jadwal-table-container">
        @include('jadwal.table')
    </div>

    {{-- Wadah modal untuk HTMX --}}
    <div id="modal-container"></div>
@endsection
