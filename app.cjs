// cPanel Phusion Passenger Wrapper Script
// Ensures Node.js v20 compatibility on shared hosting deployment

async function main() {
  try {
    await import('./dist/index.js');
  } catch (err) {
    console.error('Failed to start P3H Kemenkum Kalsel server via app.cjs:', err);
  }
}

main();
