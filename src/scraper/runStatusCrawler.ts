import { crawlStatusPeraturan } from './crawlStatusPeraturan.js';

crawlStatusPeraturan()
  .then(() => { console.log('\nStatus crawl complete.'); process.exit(0); })
  .catch(e => { console.error('Fatal:', e); process.exit(1); });
