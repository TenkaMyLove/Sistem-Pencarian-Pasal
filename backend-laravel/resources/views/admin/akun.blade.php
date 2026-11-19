{{--
    Halaman Kelola Akun (khusus Pengelola).
    Variabel: $userAccounts (Collection of Pengguna), $message, $error (string atau null).
--}}
@extends('layouts.app', ['title' => 'Kelola Akun', 'activeNav' => 'kelola-akun'])

@section('content')
    <div class="page-head">
        <div>
            <h2>Kelola Akun Pengguna</h2>
            <p>Perbarui kata sandi akun operasional Pengelola dan Perancang. Khusus Pengelola.</p>
        </div>
    </div>

    {{-- Pesan sukses --}}
    @if (!empty($message))
        <div class="alert alert-success" role="status">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span>{{ $message }}</span>
        </div>
    @endif

    {{-- Pesan gagal --}}
    @if (!empty($error))
        <div class="alert alert-danger" role="alert">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span>{{ $error }}</span>
        </div>
    @endif

    <div class="split">
        {{-- Tabel daftar akun --}}
        <div class="panel">
            <div class="panel-head">
                <h3>Daftar Akun Sistem</h3>
            </div>

            {{-- Tampilan kartu responsif khusus Mobile / PWA (< 768px) --}}
            <div class="md:hidden divide-y divide-[#e2e8f0]">
                @foreach ($userAccounts as $acc)
                    <div class="p-4 flex flex-col gap-2">
                        <div class="flex items-center justify-between gap-2">
                            <span class="text-[15px] font-bold text-[#0f172a]">{{ $acc->username }}</span>
                            <span class="tag tag-neutral">{{ $acc->peran }}</span>
                        </div>
                        <div class="flex flex-wrap items-center justify-between gap-2 text-[12.5px] text-[#64748b] bg-[#f8fafc] border border-[#e2e8f0] rounded px-3 py-2">
                            <span>Diubah oleh: <strong class="text-[#1e293b]">{{ $acc->diubah_terakhir_oleh ?: 'System' }}</strong></span>
                            <span>{{ $acc->tanggal_kata_sandi_diubah ? $acc->tanggal_kata_sandi_diubah->locale('id')->translatedFormat('j M Y H.i') : '-' }}</span>
                        </div>
                    </div>
                @endforeach
            </div>

            {{-- Tampilan tabel penuh untuk Tablet / Desktop (>= 768px) --}}
            <div class="hidden md:block table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th scope="col">Username</th>
                            <th scope="col">Peran</th>
                            <th scope="col">Diubah Oleh</th>
                            <th scope="col">Perubahan Terakhir</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($userAccounts as $acc)
                            <tr>
                                <td class="cell-strong">{{ $acc->username }}</td>
                                <td><span class="tag tag-neutral">{{ $acc->peran }}</span></td>
                                <td>{{ $acc->diubah_terakhir_oleh ?: 'System' }}</td>
                                {{-- Contoh hasil: "3 Nov 2025 14.30" --}}
                                <td>{{ $acc->tanggal_kata_sandi_diubah ? $acc->tanggal_kata_sandi_diubah->locale('id')->translatedFormat('j M Y H.i') : '-' }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Form reset kata sandi --}}
        <form class="panel" action="/kelola-akun" method="post">
            @csrf

            <div class="panel-head">
                <h3>Reset Kata Sandi</h3>
            </div>

            <div class="panel-pad">
                <div class="field">
                    <label for="target_username">Nama Pengguna</label>
                    <select id="target_username" name="target_username" class="select" required>
                        {{-- Daftar akun yang boleh di-reset diambil dari config/p3h.php --}}
                        @foreach (config('p3h.akun_operasional') as $nama)
                            <option value="{{ $nama }}">{{ $nama }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="kata_sandi_baru">Kata Sandi Baru</label>
                    <input
                        type="password"
                        id="kata_sandi_baru"
                        name="kata_sandi_baru"
                        class="input"
                        placeholder="Minimal 6 karakter"
                        autocomplete="new-password"
                        minlength="6"
                        required
                    >
                </div>

                <div class="field">
                    <label for="konfirmasi_kata_sandi">Konfirmasi Kata Sandi Baru</label>
                    <input
                        type="password"
                        id="konfirmasi_kata_sandi"
                        name="konfirmasi_kata_sandi"
                        class="input"
                        placeholder="Ulangi kata sandi"
                        autocomplete="new-password"
                        minlength="6"
                        required
                    >
                </div>

                <button type="submit" class="btn btn-primary btn-block">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
                    </svg>
                    Simpan Kata Sandi
                </button>
            </div>
        </form>
    </div>
@endsection
