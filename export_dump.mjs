import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: parseInt(process.env.PGPORT || '5432', 10),
  database: process.env.PGDATABASE || 'p3h_kemenkum_kalsel',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || '',
});

async function exportFullSql() {
  const client = await pool.connect();
  try {
    console.log('--- 1. Mengekspor Seluruh Database ke database_dump.sql ---');

    let sqlDump = `-- ========================================================\n`;
    sqlDump += `-- Database Dump: p3h_kemenkum_kalsel\n`;
    sqlDump += `-- Tanggal Ekspor: ${new Date().toISOString()}\n`;
    sqlDump += `-- ========================================================\n\n`;

    // 1. Schema Definition
    sqlDump += `-- 1. Schema Definition\n`;
    const schemaContent = fs.readFileSync(path.join(process.cwd(), 'src/db/schema.sql'), 'utf-8');
    sqlDump += `${schemaContent}\n\n`;

    // Discover all public tables
    const tableRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);

    // Prioritize tables: foreign key dependencies first
    const preferredOrder = ['pengguna', 'sumber_scraping', 'peraturan', 'pasal', 'antrian_scraping', 'log_kegagalan_crawl', 'jadwal_rapat_harmonisasi'];
    const existingTables = tableRes.rows.map(r => r.table_name);
    const sortedTables = [
      ...preferredOrder.filter(t => existingTables.includes(t)),
      ...existingTables.filter(t => !preferredOrder.includes(t))
    ];

    for (const table of sortedTables) {
      const res = await client.query(`SELECT * FROM ${table} ORDER BY id ASC`);
      if (res.rows.length === 0) {
        console.log(`Table ${table}: 0 rows (skipped insert)`);
        continue;
      }

      console.log(`Table ${table}: ${res.rows.length} rows exported`);
      sqlDump += `-- Data for ${table} (${res.rows.length} rows)\n`;
      sqlDump += `INSERT INTO ${table} (${Object.keys(res.rows[0]).join(', ')}) VALUES\n`;

      const valuesSql = res.rows.map(row => {
        const cols = Object.values(row).map(val => {
          if (val === null || val === undefined) return 'NULL';
          if (typeof val === 'number') return val;
          if (typeof val === 'boolean') return val ? 'TRUE' : 'FALSE';
          if (val instanceof Date) return `'${val.toISOString()}'`;
          if (typeof val === 'object') return `'${JSON.stringify(val).replace(/'/g, "''")}'`;
          return `'${String(val).replace(/'/g, "''")}'`;
        });
        return `  (${cols.join(', ')})`;
      }).join(',\n');

      sqlDump += `${valuesSql};\n\n`;
      sqlDump += `SELECT setval(pg_get_serial_sequence('${table}', 'id'), COALESCE((SELECT MAX(id) + 1 FROM ${table}), 1), false);\n\n`;
    }

    const outputPath = path.join(process.cwd(), 'database_dump.sql');
    fs.writeFileSync(outputPath, sqlDump, 'utf-8');
    console.log(`\nBerhasil menulis file dump ke: ${outputPath}`);

    // Summary counts
    const regCount = await client.query(`SELECT COUNT(*) FROM peraturan`);
    const pasalCount = await client.query(`SELECT COUNT(*) FROM pasal`);
    console.log(`Total Peraturan di DB: ${regCount.rows[0].count}`);
    console.log(`Total Pasal di DB: ${pasalCount.rows[0].count}`);

  } catch (err) {
    console.error('Error generating dump:', err);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

exportFullSql();
