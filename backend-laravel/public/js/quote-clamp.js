// Batasi teks pasal di hasil pencarian maksimal 5 baris; tombol "Selengkapnya" muncul
// hanya bila teks benar-benar terpotong. Hasil pencarian diganti oleh HTMX, jadi dicek ulang
// setiap kali konten baru dimuat.
(function () {
  function setup(root) {
    (root || document).querySelectorAll('.quote-text').forEach(function (el) {
      if (el.dataset.clampReady) return;
      el.dataset.clampReady = '1';
      el.classList.add('clamp-5');
      if (el.scrollHeight <= el.clientHeight + 1) {
        el.classList.remove('clamp-5');
        return;
      }
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'quote-toggle';
      btn.textContent = 'Selengkapnya';
      el.insertAdjacentElement('afterend', btn);
    });
  }

  document.addEventListener('click', function (e) {
    var btn = e.target.closest('.quote-toggle');
    if (!btn) return;
    var el = btn.previousElementSibling;
    var terbuka = el.classList.toggle('clamp-5') === false;
    btn.textContent = terbuka ? 'Tutup' : 'Selengkapnya';
  });

  document.addEventListener('DOMContentLoaded', function () { setup(); });
  document.addEventListener('htmx:afterSettle', function (e) { setup(e.target); });
})();
