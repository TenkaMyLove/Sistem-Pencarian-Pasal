import { runRecrawlCheck } from './recrawl.js';
import { pool } from '../db/index.js';

async function main() {
  console.log('Executing standalone scraper & re-crawl engine runner...');
  try {
    const result = await runRecrawlCheck();
    console.log('Execution Summary:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Scraper error:', error);
  } finally {
    await pool.end();
  }
}

main();
