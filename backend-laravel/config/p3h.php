<?php

/*
|--------------------------------------------------------------------------
| Pengaturan khusus aplikasi P3H Kemenkum Kalsel
|--------------------------------------------------------------------------
| Daftar pilihan ini dipakai bersama oleh controller dan view Blade,
| jadi cukup diubah di satu tempat ini saja.
*/

return [
    'jenis' => [
        'UU', 'PP', 'Perpres', 'Permen', 'Permendagri', 'Permenkumham',
        'Perda', 'Pergub', 'Perbup', 'Perwal',
        'Inpres', 'Keppres', 'Kepmen', 'SE', 'Perppu', 'UUD 1945',
    ],

    'wilayah' => [
        'Nasional', 'Provinsi Kalimantan Selatan', 'Kalimantan Selatan',
        'Kabupaten Banjar', 'Kabupaten Barito Kuala', 'Kabupaten Hulu Sungai Selatan',
        'Kabupaten Hulu Sungai Tengah', 'Kabupaten Hulu Sungai Utara',
        'Kabupaten Kotabaru', 'Kabupaten Tabalong', 'Kabupaten Tanah Bumbu',
        'Kabupaten Tanah Laut', 'Kabupaten Tapin', 'Kabupaten Balangan',
        'Kota Banjarbaru', 'Kota Banjarmasin',
    ],

    'sektor' => [
        'Keuangan Daerah', 'Pajak Daerah', 'Otonomi Daerah', 'Tata Ruang', 'Lingkungan Hidup',
        'Pendidikan', 'Kesehatan', 'Sosial dan Kesejahteraan', 'Ketenagakerjaan', 'Pertanahan',
        'Perpajakan', 'Perdagangan', 'Koperasi dan UMKM', 'Investasi dan Perizinan',
        'Pertanian', 'Perikanan', 'Kebencanaan', 'Jasa Konstruksi',
        'Infrastruktur', 'Pemerintahan', 'Hukum', 'Hukum Pidana', 'Lainnya',
    ],

    // Nama kompilator standar pada form jadwal rapat
    'kompilator' => ['Eryck', 'Kiki', 'Dian', 'Dame', 'Nizar', 'Wyra', 'Dudunk', 'Ryna'],

    // Akun yang boleh di-reset kata sandinya oleh Pengelola
    'akun_operasional' => ['Pengelola', 'Perancang'],

    // Jumlah hasil per halaman pada pencarian web
    'per_halaman' => 5,

    // Proxy / relay Indonesia (opsional, untuk server cloud luar negeri seperti Railway saat mengakses peraturan.bpk.go.id)
    // Mendukung format:
    //  - HTTP/SOCKS5 proxy : http://user:pass@ip-indonesia:port atau socks5h://user:pass@ip-indonesia:port
    //  - Relay endpoint    : https://relay-anda.id/?url={url}
    //  - Beberapa proxy    : pisahkan dengan koma (,) sebagai cadangan berurutan
    'crawler_proxy_url' => env('CRAWLER_PROXY_URL', env('BPK_PROXY_URL', '')),
];
