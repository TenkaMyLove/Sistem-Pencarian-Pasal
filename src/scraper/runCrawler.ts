import { runRealCrawler } from './realCrawler.js';

runRealCrawler()
  .then(() => {
    console.log('\nCrawler finished.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
