/**
 * expandRegulationsKalsel.ts
 *
 * Adds 3 Perda Provinsi Kalimantan Selatan:
 * 1. Perda Kalsel No. 6 Tahun 2023 (RTRW 2023-2042)
 * 2. Perda Kalsel No. 11 Tahun 2016 (Pembentukan & Susunan Perangkat Daerah)
 * 3. Perda Kalsel No. 11 Tahun 2021 (RPJMD 2021-2026)
 *
 * Run: npx tsx src/scraper/expandRegulationsKalsel.ts
 */

import { pool } from '../db/index.js';

interface PasalEntry {
  nomor: string;
  ayat: string;
  teks: string;
}

interface RegEntry {
  jenis: string;
  nomor: string;
  tahun: number;
  judul: string;
  status: string;
  status_detail: string;
  wilayah: string;
  sektor: string;
  url: string;
  pasalList: PasalEntry[];
}

const KALSEL_REGULATIONS: RegEntry[] = [
  {
    jenis: 'Perda',
    nomor: '6',
    tahun: 2023,
    judul: 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 6 Tahun 2023 tentang Rencana Tata Ruang Wilayah Provinsi Kalimantan Selatan Tahun 2023-2042',
    status: 'berlaku',
    status_detail: 'Mencabut Perda Provinsi Kalimantan Selatan No. 9 Tahun 2015 tentang RTRWP Kalsel 2015-2035; Menyesuaikan dengan UU Cipta Kerja dan Penyangga IKN',
    wilayah: 'Prov. Kalimantan Selatan',
    sektor: 'Tata Ruang',
    url: 'https://dpmptsp.kalselprov.go.id/web/download/peraturan-daerah-provinsi-kalimantan-selatan-nomor-6-tahun-2023-tentang-rencana-tata-ruang-wilayah-provinsi-kalimantan-selatan-tahun-2023-2042/',
    pasalList: [
      {
        nomor: 'Pasal 1',
        ayat: 'Angka 1',
        teks: 'Rencana Tata Ruang Wilayah Provinsi Kalimantan Selatan yang selanjutnya disingkat RTRW Provinsi adalah rencana tata ruang yang mengatur struktur ruang dan pola ruang wilayah Provinsi Kalimantan Selatan.'
      },
      {
        nomor: 'Pasal 3',
        ayat: '',
        teks: 'Penataan ruang wilayah Provinsi bertujuan untuk mewujudkan Kalimantan Selatan sebagai Gerbang Logistik Kalimantan dan Pintu Gerbang Ibu Kota Nusantara yang mandiri, berdaya saing, berkelanjutan, dan berbasis agribisnis serta industri kelautan.'
      },
      {
        nomor: 'Pasal 47',
        ayat: 'Ayat (1)',
        teks: 'Kesesuaian Kegiatan Pemanfaatan Ruang (KKPR) menjadi acuan utama dalam penerbitan perizinan berusaha dan perizinan nonberusaha di daerah.'
      },
      {
        nomor: 'Pasal 98',
        ayat: 'Ayat (1)',
        teks: 'Pemerintah Kabupaten/Kota di wilayah Kalimantan Selatan wajib menyesuaikan RTRW Kabupaten/Kota dengan RTRW Provinsi paling lambat 2 (dua) tahun sejak Peraturan Daerah ini diundangkan.'
      }
    ]
  },
  {
    jenis: 'Perda',
    nomor: '11',
    tahun: 2016,
    judul: 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 11 Tahun 2016 tentang Pembentukan dan Susunan Perangkat Daerah Provinsi Kalimantan Selatan',
    status: 'berlaku',
    status_detail: 'Melaksanakan PP No. 18/2016 tentang Perangkat Daerah; Mencabut Perda Kalsel No. 5/2008, Perda Kalsel No. 6/2008, dan Perda terkait lainnya',
    wilayah: 'Prov. Kalimantan Selatan',
    sektor: 'Otonomi Daerah',
    url: 'https://peraturan.bpk.go.id/Details/39797/uu-no-40-tahun-2007',
    pasalList: [
      {
        nomor: 'Pasal 1',
        ayat: 'Angka 1',
        teks: 'Perangkat Daerah Provinsi adalah unsur pembantu Gubernur dan Dewan Perwakilan Rakyat Daerah Provinsi dalam penyelenggaraan Urusan Pemerintahan yang menjadi kewenangan Daerah Provinsi.'
      },
      {
        nomor: 'Pasal 2',
        ayat: '',
        teks: 'Dengan Peraturan Daerah ini dibentuk Perangkat Daerah dengan susunan: Sekretariat Daerah, Sekretariat DPRD, Inspektorat Daerah, Dinas Daerah, dan Badan Daerah.'
      },
      {
        nomor: 'Pasal 4',
        ayat: 'Ayat (1)',
        teks: 'Dinas Daerah Provinsi merupakan unsur pelaksana Urusan Pemerintahan yang menjadi kewenangan Daerah Provinsi yang dipimpin oleh Kepala Dinas.'
      },
      {
        nomor: 'Pasal 12',
        ayat: '',
        teks: 'Ketentuan lebih lanjut mengenai kedudukan, susunan organisasi, tugas, fungsi, dan tata kerja Perangkat Daerah diatur dengan Peraturan Gubernur.'
      }
    ]
  },
  {
    jenis: 'Perda',
    nomor: '11',
    tahun: 2021,
    judul: 'Peraturan Daerah Provinsi Kalimantan Selatan Nomor 11 Tahun 2021 tentang Rencana Pembangunan Jangka Menengah Daerah Provinsi Kalimantan Selatan Tahun 2021-2026',
    status: 'berlaku',
    status_detail: 'Pedoman pembangunan daerah jangka menengah; Acuan penyusunan RKPD dan Renja SKPD Prov. Kalsel',
    wilayah: 'Prov. Kalimantan Selatan',
    sektor: 'Otonomi Daerah',
    url: 'https://bappeda.kalselprov.go.id/download/rpjmd-provinsi-kalimantan-selatan-tahun-2021-2026/',
    pasalList: [
      {
        nomor: 'Pasal 1',
        ayat: 'Angka 1',
        teks: 'Rencana Pembangunan Jangka Menengah Daerah Provinsi Kalimantan Selatan Tahun 2021-2026 yang selanjutnya disingkat RPJMD adalah dokumen perencanaan pembangunan daerah untuk periode 5 (lima) tahun.'
      },
      {
        nomor: 'Pasal 3',
        ayat: 'Ayat (1)',
        teks: 'Visi Pembangunan Jangka Menengah Daerah Provinsi Kalimantan Selatan Tahun 2021-2026 adalah Kalsel Maju (Kalimantan Selatan Makmur, Sejahtera, dan Berkelanjutan) sebagai Gerbang Ibu Kota Negara.'
      },
      {
        nomor: 'Pasal 5',
        ayat: '',
        teks: 'RPJMD menjadi pedoman dalam penyusunan Renstra Perangkat Daerah, RKPD, KUA-PPAS, APBD, dan evaluasi penyelenggaraan pemerintahan daerah.'
      }
    ]
  }
];

export async function addKalselRegulations() {
  console.log(`\n=== MENAMBAHKAN PERDA PROVINSI KALIMANTAN SELATAN ===`);
  const client = await pool.connect();
  let added = 0;
  let skipped = 0;
  let updated = 0;

  try {
    await client.query('BEGIN');

    for (const reg of KALSEL_REGULATIONS) {
      const exists = await client.query(
        `SELECT id FROM peraturan WHERE jenis_peraturan=$1 AND nomor=$2 AND tahun=$3 AND wilayah=$4`,
        [reg.jenis, reg.nomor, reg.tahun, reg.wilayah]
      );

      if (exists.rows.length > 0) {
        console.log(`  UPDATE / EXISTS: ${reg.jenis} No.${reg.nomor}/${reg.tahun} (${reg.wilayah})`);
        await client.query(
          `UPDATE peraturan SET judul=$1, status=$2, status_detail=$3, url_dokumen_asli=$4, sektor=$5, tanggal_dicek_terakhir=NOW() WHERE id=$6`,
          [reg.judul, reg.status, reg.status_detail, reg.url, reg.sektor, exists.rows[0].id]
        );
        updated++;
        continue;
      }

      const res = await client.query(`
        INSERT INTO peraturan (jenis_peraturan, nomor, tahun, judul, status, status_detail, status_detail_json, wilayah, sektor, url_dokumen_asli, status_tautan, tanggal_diambil, tanggal_dicek_terakhir)
        VALUES ($1, $2, $3, $4, $5, $6, '{}', $7, $8, $9, 'normal', NOW(), NOW())
        RETURNING id;
      `, [reg.jenis, reg.nomor, reg.tahun, reg.judul, reg.status, reg.status_detail || '', reg.wilayah, reg.sektor, reg.url]);

      const regId = res.rows[0].id;

      for (const p of reg.pasalList) {
        await client.query(`
          INSERT INTO pasal (peraturan_id, nomor_pasal, nomor_ayat, teks_pasal)
          VALUES ($1, $2, $3, $4);
        `, [regId, p.nomor, p.ayat, p.teks]);
      }

      console.log(`  ADDED: ${reg.jenis} No.${reg.nomor}/${reg.tahun} (${reg.wilayah}) — ${reg.pasalList.length} pasal`);
      added++;
    }

    await client.query('COMMIT');
    console.log(`\nSelesai. Ditambahkan: ${added} | Diupdate: ${updated} | Total: ${KALSEL_REGULATIONS.length}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Fatal error:', err);
    throw err;
  } finally {
    client.release();
  }
}

addKalselRegulations().then(() => process.exit(0)).catch(() => process.exit(1));
