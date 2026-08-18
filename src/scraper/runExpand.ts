import { expandRegulations } from './expandRegulations.js';

expandRegulations()
  .then(() => { console.log('\nExpansion complete.'); process.exit(0); })
  .catch(e => { console.error('Fatal:', e); process.exit(1); });
