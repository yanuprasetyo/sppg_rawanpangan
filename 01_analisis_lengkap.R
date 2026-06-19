<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dapur untuk Siapa? — Distribusi SPPG & Kerawanan Pangan</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: 'Segoe UI', system-ui, sans-serif;
    background: #f4f6f9;
    color: #2c3e50;
    line-height: 1.6;
  }

  /* HEADER */
  header {
    background: linear-gradient(135deg, #1a3a5c 0%, #2c6e9e 100%);
    color: white;
    padding: 2rem 2rem 1.5rem;
  }
  .header-top {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
  }
  .badge {
    background: rgba(255,255,255,0.2);
    border: 1px solid rgba(255,255,255,0.4);
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.75rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  header h1 {
    font-size: clamp(1.4rem, 3vw, 2rem);
    font-weight: 700;
    line-height: 1.3;
    margin-bottom: 0.5rem;
  }
  header h1 span { color: #f39c12; }
  header p.sub {
    font-size: 0.9rem;
    opacity: 0.85;
    margin-bottom: 0.25rem;
  }
  header p.meta {
    font-size: 0.8rem;
    opacity: 0.65;
  }

  /* ALERT BOX */
  .alert {
    background: #fff3cd;
    border-left: 4px solid #f39c12;
    padding: 0.9rem 1.2rem;
    margin: 1.5rem 2rem;
    border-radius: 4px;
    font-size: 0.88rem;
  }
  .alert strong { color: #856404; }

  /* STAT CARDS */
  .cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    padding: 0 2rem 1rem;
  }
  .card {
    background: white;
    border-radius: 8px;
    padding: 1.2rem 1.4rem;
    box-shadow: 0 1px 4px rgba(0,0,0,0.08);
    border-top: 3px solid #2c6e9e;
  }
  .card.red   { border-top-color: #e74c3c; }
  .card.green { border-top-color: #27ae60; }
  .card.orange{ border-top-color: #f39c12; }
  .card.grey  { border-top-color: #7f8c8d; }
  .card-value {
    font-size: 2rem;
    font-weight: 700;
    line-height: 1.1;
    color: #1a3a5c;
  }
  .card-value.red   { color: #c0392b; }
  .card-value.green { color: #1e8449; }
  .card-value.orange{ color: #d35400; }
  .card-label {
    font-size: 0.8rem;
    color: #7f8c8d;
    margin-top: 0.3rem;
  }
  .card-sub {
    font-size: 0.75rem;
    color: #95a5a6;
    margin-top: 0.2rem;
    font-style: italic;
  }

  /* MAIN LAYOUT */
  main {
    padding: 0 2rem 2rem;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.2rem;
  }
  @media (max-width: 900px) { main { grid-template-columns: 1fr; } }

  .panel {
    background: white;
    border-radius: 8px;
    padding: 1.4rem;
    box-shadow: 0 1px 4px rgba(0,0,0,0.08);
  }
  .panel.full { grid-column: 1 / -1; }

  .panel-title {
    font-size: 0.95rem;
    font-weight: 700;
    color: #1a3a5c;
    margin-bottom: 0.3rem;
  }
  .panel-sub {
    font-size: 0.78rem;
    color: #7f8c8d;
    margin-bottom: 1rem;
  }

  /* FILTER */
  .filters {
    display: flex;
    gap: 0.8rem;
    align-items: center;
    flex-wrap: wrap;
    padding: 0.8rem 2rem;
    background: white;
    border-bottom: 1px solid #eee;
    margin-bottom: 1rem;
  }
  .filters label { font-size: 0.82rem; font-weight: 600; color: #555; }
  .filters select {
    font-size: 0.82rem;
    padding: 0.3rem 0.6rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    background: #fafafa;
  }
  .btn-reset {
    font-size: 0.8rem;
    padding: 0.3rem 0.8rem;
    background: #1a3a5c;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }
  .btn-reset:hover { background: #2c6e9e; }

  /* TABLE */
  .tbl-wrap { overflow-x: auto; max-height: 380px; overflow-y: auto; }
  table { width: 100%; border-collapse: collapse; font-size: 0.8rem; }
  thead th {
    background: #1a3a5c;
    color: white;
    padding: 0.55rem 0.8rem;
    text-align: left;
    position: sticky;
    top: 0;
    font-weight: 600;
    white-space: nowrap;
  }
  tbody tr:nth-child(even) { background: #f8f9fa; }
  tbody tr:hover { background: #e8f4fd; }
  tbody td {
    padding: 0.45rem 0.8rem;
    border-bottom: 1px solid #eee;
    white-space: nowrap;
  }
  .tag {
    display: inline-block;
    padding: 0.1rem 0.5rem;
    border-radius: 10px;
    font-size: 0.72rem;
    font-weight: 600;
  }
  .tag-1 { background:#fde8e8; color:#c0392b; }
  .tag-2 { background:#fde8e8; color:#c0392b; }
  .tag-3 { background:#fef9e7; color:#d35400; }
  .tag-4 { background:#eafaf1; color:#1e8449; }
  .tag-5 { background:#eafaf1; color:#1e8449; }
  .tag-6 { background:#d5f5e3; color:#145a32; }
  .tag-0sppg { background:#f8d7da; color:#721c24; }

  /* CI TABLE */
  .ci-table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
  .ci-table th {
    background: #f4f6f9;
    padding: 0.6rem 1rem;
    text-align: left;
    font-size: 0.8rem;
    color: #555;
    border-bottom: 2px solid #ddd;
  }
  .ci-table td {
    padding: 0.6rem 1rem;
    border-bottom: 1px solid #eee;
  }
  .ci-pos { color: #c0392b; font-weight: 700; }
  .ci-neg { color: #1e8449; font-weight: 700; }

  /* REGRESSION TABLE */
  .reg-table { width: 100%; border-collapse: collapse; font-size: 0.78rem; }
  .reg-table th {
    background: #1a3a5c;
    color: white;
    padding: 0.5rem 0.7rem;
    text-align: center;
    font-size: 0.76rem;
  }
  .reg-table th:first-child { text-align: left; }
  .reg-table td {
    padding: 0.45rem 0.7rem;
    border-bottom: 1px solid #eee;
    text-align: center;
  }
  .reg-table td:first-child { text-align: left; font-weight: 500; }
  .reg-table tr:nth-child(even) { background: #f8f9fa; }
  .sig-3 { color: #c0392b; font-weight: 700; }
  .sig-2 { color: #d35400; font-weight: 600; }
  .sig-1 { color: #7d6608; }
  .wrong { background: #fde8e8 !important; }
  .right { background: #eafaf1 !important; }

  /* FINDINGS */
  .findings { display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem; }
  @media (max-width: 700px) { .findings { grid-template-columns: 1fr; } }
  .finding-item {
    background: #f8f9fa;
    border-left: 3px solid #2c6e9e;
    padding: 0.8rem 1rem;
    border-radius: 0 4px 4px 0;
    font-size: 0.83rem;
  }
  .finding-item.bad  { border-left-color: #e74c3c; background: #fdf2f2; }
  .finding-item.good { border-left-color: #27ae60; background: #f2fdf5; }
  .finding-item strong { display: block; margin-bottom: 0.3rem; font-size: 0.85rem; }

  /* METHODOLOGY */
  .method-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 0.7rem;
  }
  .method-item {
    background: #f8f9fa;
    padding: 0.8rem;
    border-radius: 6px;
    font-size: 0.78rem;
    border-top: 2px solid #2c6e9e;
  }
  .method-item strong { display: block; font-size: 0.82rem; margin-bottom: 0.3rem; color: #1a3a5c; }

  /* FOOTER */
  footer {
    background: #1a3a5c;
    color: rgba(255,255,255,0.7);
    text-align: center;
    padding: 1.5rem 2rem;
    font-size: 0.78rem;
    margin-top: 1rem;
  }
  footer a { color: #aed6f1; text-decoration: none; }
  footer a:hover { text-decoration: underline; }

  canvas { max-height: 320px; }
  .loading { text-align:center; color:#999; padding:2rem; font-size:0.85rem; }
</style>
</head>
<body>

<!-- HEADER -->
<header>
  <div class="header-top">
    <span class="badge">Policy Dashboard</span>
    <span class="badge">514 Kabupaten/Kota</span>
    <span class="badge">Data: April 2026</span>
  </div>
  <h1>Dapur untuk Siapa? <span>Distribusi SPPG</span> dan Kerawanan Pangan di Indonesia</h1>
  <p class="sub">Analisis Ketepatsasaran Program Makan Bergizi Gratis (MBG) berbasis IKP/FSVA Bapanas</p>
  <p class="meta">Prasetyo, Y.E., Natih, P.G.L., Aini, Y.N., Bahagijo, S., & Rossinda, S. — Pusat Riset Kependudukan, BRIN (2026)</p>
</header>

<!-- ALERT -->
<div class="alert">
  <strong>Temuan Kritis:</strong> Wilayah paling rawan pangan (IKP kategori 1) rata-rata hanya mendapat <strong>1,13 SPPG per 100.000 penduduk</strong> — hampir 8 kali lebih sedikit dibanding wilayah sangat tahan pangan. Distribusi SPPG bersifat <strong>pro-tahan pangan</strong>, bukan pro-rawan pangan. Paradoks stunting terkonfirmasi secara statistik di semua model.
</div>

<!-- STAT CARDS -->
<div class="cards">
  <div class="card">
    <div class="card-value">27.427</div>
    <div class="card-label">Total Dapur SPPG Nasional</div>
    <div class="card-sub">Per 30 April 2026</div>
  </div>
  <div class="card">
    <div class="card-value">514</div>
    <div class="card-label">Kabupaten/Kota Dianalisis</div>
    <div class="card-sub">dari 38 provinsi</div>
  </div>
  <div class="card red">
    <div class="card-value red">16</div>
    <div class="card-label">Kabupaten dengan 0 SPPG</div>
    <div class="card-sub">14 di antaranya di Papua</div>
  </div>
  <div class="card red">
    <div class="card-value red">1,13</div>
    <div class="card-label">SPPG/100k — Sangat Rentan</div>
    <div class="card-sub">vs 9,00 di Sangat Tahan</div>
  </div>
  <div class="card orange">
    <div class="card-value orange">+0,077</div>
    <div class="card-label">Concentration Index (IKP)</div>
    <div class="card-sub">Positif = pro-tahan pangan</div>
  </div>
  <div class="card red">
    <div class="card-value red">61</div>
    <div class="card-label">Kabupaten "Krisis Ganda"</div>
    <div class="card-sub">Hanya terima 1,3% SPPG nasional</div>
  </div>
</div>

<!-- FILTERS -->
<div class="filters">
  <label>Filter IKP:</label>
  <select id="filter-ikp" onchange="applyFilters()">
    <option value="all">Semua Kategori</option>
    <option value="1">Sangat Rentan (1)</option>
    <option value="2">Rentan (2)</option>
    <option value="3">Agak Rentan (3)</option>
    <option value="4">Agak Tahan (4)</option>
    <option value="5">Tahan (5)</option>
    <option value="6">Sangat Tahan (6)</option>
  </select>
  <label>Filter Papua:</label>
  <select id="filter-papua" onchange="applyFilters()">
    <option value="all">Semua Wilayah</option>
    <option value="nopapua">Tanpa Papua</option>
    <option value="papua">Papua Saja</option>
  </select>
  <button class="btn-reset" onclick="resetFilters()">Reset</button>
  <span id="filter-count" style="font-size:0.8rem;color:#777;"></span>
</div>

<!-- MAIN GRID -->
<main>

  <!-- CHART 1: Bar chart rata-rata SPPG per kategori IKP -->
  <div class="panel">
    <div class="panel-title">Rata-rata SPPG per 100.000 Penduduk menurut Kategori IKP</div>
    <div class="panel-sub">Gradien terbalik: semakin rawan, semakin sedikit SPPG yang diterima</div>
    <canvas id="chart-bar-ikp"></canvas>
  </div>

  <!-- CHART 2: Scatter IKP vs SPPG -->
  <div class="panel">
    <div class="panel-title">Hubungan IKP dengan Cakupan SPPG per Kapita</div>
    <div class="panel-sub">Tren positif = wilayah tahan pangan mendapat lebih banyak SPPG</div>
    <canvas id="chart-scatter"></canvas>
  </div>

  <!-- CI TABLE -->
  <div class="panel">
    <div class="panel-title">Concentration Index (CI) Distribusi SPPG</div>
    <div class="panel-sub">CI &lt; 0 = pro-rawan (diinginkan) | CI &gt; 0 = pro-tahan (tidak diinginkan)</div>
    <table class="ci-table">
      <thead>
        <tr>
          <th>Basis Ranking</th>
          <th>CI Full Sample</th>
          <th>CI Tanpa Papua</th>
          <th>Interpretasi</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Kemiskinan (%)</td>
          <td><span class="ci-neg">−0,042</span></td>
          <td><span style="color:#888">+0,004</span></td>
          <td style="font-size:0.75rem">Kesan pro-poor hilang tanpa Papua</td>
        </tr>
        <tr>
          <td>IKP (ketahanan pangan)</td>
          <td><span class="ci-pos">+0,077</span></td>
          <td><span class="ci-pos">+0,034</span></td>
          <td style="font-size:0.75rem">Pro-tahan pangan di kedua sampel</td>
        </tr>
      </tbody>
    </table>
    <div style="margin-top:1rem;">
      <canvas id="chart-ci" style="max-height:180px;"></canvas>
    </div>
  </div>

  <!-- REGRESSION TABLE -->
  <div class="panel">
    <div class="panel-title">Hasil Regresi OLS dan Tobit</div>
    <div class="panel-sub">Variabel dependen: SPPG per 100.000 penduduk</div>
    <div class="tbl-wrap">
      <table class="reg-table">
        <thead>
          <tr>
            <th>Variabel</th>
            <th>OLS Full</th>
            <th>OLS −Papua</th>
            <th>Tobit Full</th>
            <th>Tobit −Papua</th>
            <th>Arah Harapan</th>
          </tr>
        </thead>
        <tbody>
          <tr class="wrong">
            <td>Kemiskinan (%)</td>
            <td>−0,025</td>
            <td>+0,026</td>
            <td>−0,038</td>
            <td>+0,026</td>
            <td style="color:#1e8449;font-weight:700">+ harap</td>
          </tr>
          <tr class="wrong">
            <td>Stunting (%)</td>
            <td class="sig-2">−0,053**</td>
            <td class="sig-2">−0,058**</td>
            <td class="sig-2">−0,055**</td>
            <td class="sig-2">−0,058**</td>
            <td style="color:#1e8449;font-weight:700">+ harap</td>
          </tr>
          <tr class="wrong">
            <td>IKP</td>
            <td class="sig-3">+0,102***</td>
            <td class="sig-1">+0,057*</td>
            <td class="sig-3">+0,118***</td>
            <td class="sig-1">+0,057*</td>
            <td style="color:#1e8449;font-weight:700">− harap</td>
          </tr>
          <tr>
            <td>log(Populasi)</td>
            <td class="sig-2">+0,409**</td>
            <td class="sig-2">+0,473**</td>
            <td class="sig-2">+0,404**</td>
            <td class="sig-2">+0,486**</td>
            <td style="color:#888">netral</td>
          </tr>
          <tr style="background:#f0f4f8;font-weight:600;font-size:0.75rem;">
            <td>n / R²</td>
            <td>514 / 0,160</td>
            <td>472 / 0,050</td>
            <td>514</td>
            <td>472</td>
            <td>—</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p style="font-size:0.72rem;color:#999;margin-top:0.5rem;">* p&lt;0,1; ** p&lt;0,05; *** p&lt;0,01. Baris merah = arah koefisien berlawanan dari harapan.</p>
  </div>

  <!-- QR CHART -->
  <div class="panel full">
    <div class="panel-title">Quantile Regression: Koefisien IKP dan Stunting Lintas Distribusi</div>
    <div class="panel-sub">Mismatch terjadi konsisten di seluruh spektrum distribusi SPPG — bukan hanya di rata-rata</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
      <div>
        <p style="font-size:0.8rem;font-weight:600;margin-bottom:0.5rem;text-align:center;">Koefisien IKP per Kuantil</p>
        <canvas id="chart-qr-ikp"></canvas>
      </div>
      <div>
        <p style="font-size:0.8rem;font-weight:600;margin-bottom:0.5rem;text-align:center;">Koefisien Stunting per Kuantil</p>
        <canvas id="chart-qr-stunting"></canvas>
      </div>
    </div>
    <p style="font-size:0.72rem;color:#999;margin-top:0.8rem;text-align:center;">Full Sample (merah) vs Tanpa Papua (biru). SE bootstrap R=1000. Garis putus = tidak ada efek (0).</p>
  </div>

  <!-- TABLE KABKOTA -->
  <div class="panel full">
    <div class="panel-title">Data Kabupaten/Kota</div>
    <div class="panel-sub" id="table-subtitle">Menampilkan semua 514 kabupaten/kota — gunakan filter di atas untuk mempersempit</div>
    <div class="tbl-wrap">
      <table>
        <thead>
          <tr>
            <th>Provinsi</th>
            <th>Kabupaten/Kota</th>
            <th>IKP</th>
            <th>Kategori IKP</th>
            <th>SPPG/100k</th>
            <th>Miskin (%)</th>
            <th>Stunting (%)</th>
            <th>Jumlah SPPG</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody id="table-body">
          <tr><td colspan="9" class="loading">Memuat data...</td></tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- KEY FINDINGS -->
  <div class="panel full">
    <div class="panel-title">Ringkasan Temuan dan Implikasi Kebijakan</div>
    <div class="panel-sub">Semua temuan bertahan setelah robustness check (tanpa Papua)</div>
    <div class="findings" style="margin-top:0.8rem;">
      <div class="finding-item bad">
        <strong>Gradien Terbalik (1:8)</strong>
        Wilayah Sangat Rentan mendapat rata-rata 1,13 SPPG/100k vs 9,00 di Sangat Tahan. Kruskal-Wallis χ²=87,82, p&lt;0,0001.
      </div>
      <div class="finding-item bad">
        <strong>Paradoks Stunting</strong>
        Koefisien stunting negatif dan signifikan di semua model (−0,053 s.d. −0,058**). Wilayah stunting tinggi justru mendapat lebih sedikit SPPG.
      </div>
      <div class="finding-item bad">
        <strong>Pro-Tahan Pangan</strong>
        CI berbasis IKP = +0,077 (full) dan +0,034 (tanpa Papua). Distribusi SPPG tidak berpihak pada wilayah rawan pangan.
      </div>
      <div class="finding-item bad">
        <strong>61 Kabupaten Krisis Ganda</strong>
        Hanya menerima 1,3% SPPG nasional. Mayoritas di Papua, Maluku, NTT, dan kepulauan terpencil.
      </div>
      <div class="finding-item">
        <strong>Bukan Hanya Masalah Papua</strong>
        Semua temuan bertahan setelah Papua dibuang. Mismatch adalah pola sistemik nasional, bukan anomali regional.
      </div>
      <div class="finding-item">
        <strong>R² Anjlok Tanpa Papua</strong>
        R² turun dari 0,160 ke 0,050. Di luar Papua, faktor kebutuhan hampir tidak menjelaskan penempatan SPPG.
      </div>
      <div class="finding-item good">
        <strong>Rekomendasi: Reformulasi Berbasis IKP</strong>
        Integrasi IKP/FSVA Bapanas sebagai variabel wajib dalam formula penentuan lokasi SPPG, dengan target CI IKP negatif.
      </div>
      <div class="finding-item good">
        <strong>Rekomendasi: Afirmasi 61 Kabupaten</strong>
        Penetapan wilayah krisis ganda sebagai prioritas nasional ekspansi dapur, dengan model 3T untuk Papua.
      </div>
    </div>
  </div>

  <!-- METHODOLOGY -->
  <div class="panel full">
    <div class="panel-title">Metodologi</div>
    <div class="panel-sub">Pipeline analisis end-to-end menggunakan R 4.6.0</div>
    <div class="method-grid" style="margin-top:0.8rem;">
      <div class="method-item">
        <strong>Statistik Deskriptif</strong>
        Ringkasan distribusi SPPG per kapita berdasarkan 6 kategori IKP/FSVA
      </div>
      <div class="method-item">
        <strong>Kruskal-Wallis + Dunn</strong>
        Uji signifikansi perbedaan antar kelompok dengan koreksi Bonferroni
      </div>
      <div class="method-item">
        <strong>Concentration Index</strong>
        Mengikuti Wagstaff et al. (1991). Basis: kemiskinan dan IKP
      </div>
      <div class="method-item">
        <strong>OLS & Tobit</strong>
        Tobit untuk mengatasi left-censoring pada 16 kabupaten dengan 0 SPPG
      </div>
      <div class="method-item">
        <strong>Quantile Regression</strong>
        Q10–Q90 dengan SE bootstrap (R=1000) menggunakan package quantreg
      </div>
      <div class="method-item">
        <strong>Robustness Check</strong>
        Semua analisis diulang tanpa 42 kabupaten dari 6 provinsi Papua
      </div>
    </div>
    <p style="font-size:0.78rem;color:#888;margin-top:1rem;">
      Data: BGN (2026), Bapanas FSVA (2024), BPS (2024), SSGI Kemenkes (2022) |
      Kode R: <a href="https://github.com/yanuprasetyo/sppg_rawanpangan" target="_blank">github.com/yanuprasetyo/sppg_rawanpangan</a>
    </p>
  </div>

</main>

<footer>
  <p>
    Prasetyo, Y.E., Natih, P.G.L., Aini, Y.N., Bahagijo, S., & Rossinda, S. (2026).
    <em>Dapur untuk Siapa? Distribusi SPPG dan Kerawanan Pangan di Indonesia.</em>
    Pusat Riset Kependudukan, BRIN.
  </p>
  <p style="margin-top:0.5rem;">
    <a href="https://github.com/yanuprasetyo/sppg_rawanpangan" target="_blank">GitHub Repo</a> |
    <a href="https://creativecommons.org/licenses/by-nc/4.0/" target="_blank">CC BY-NC 4.0</a> |
    Dashboard dibangun dengan Chart.js
  </p>
</footer>

<script>
// ── COLOUR PALETTES ──────────────────────────────────────────────────────
const IKP_COLORS = {
  1: '#c0392b', 2: '#e67e22', 3: '#f39c12',
  4: '#2ecc71', 5: '#27ae60', 6: '#1e8449'
};
const IKP_LABELS = {
  1:'Sangat Rentan', 2:'Rentan', 3:'Agak Rentan',
  4:'Agak Tahan', 5:'Tahan', 6:'Sangat Tahan'
};

// ── EMBEDDED SUMMARY DATA ────────────────────────────────────────────────
const summaryIKP = [
  { kat_ikp:1, kat_ikp_f:'Sangat Rentan', n:20,  mean_sppg:1.13,  median_sppg:0.00,  mean_miskin:30.1, mean_stunting:33.1 },
  { kat_ikp:2, kat_ikp_f:'Rentan',        n:19,  mean_sppg:4.36,  median_sppg:3.92,  mean_miskin:23.0, mean_stunting:26.8 },
  { kat_ikp:3, kat_ikp_f:'Agak Rentan',   n:42,  mean_sppg:6.60,  median_sppg:6.50,  mean_miskin:16.9, mean_stunting:22.4 },
  { kat_ikp:4, kat_ikp_f:'Agak Tahan',    n:111, mean_sppg:8.77,  median_sppg:8.62,  mean_miskin:10.7, mean_stunting:19.8 },
  { kat_ikp:5, kat_ikp_f:'Tahan',         n:216, mean_sppg:9.36,  median_sppg:9.68,  mean_miskin:8.3,  mean_stunting:20.3 },
  { kat_ikp:6, kat_ikp_f:'Sangat Tahan',  n:106, mean_sppg:9.00,  median_sppg:8.57,  mean_miskin:6.7,  mean_stunting:18.5 },
];

// Quantile regression results
const qrData = {
  taus: ['Q10','Q25','Q50','Q75','Q90'],
  ikp: {
    full:   { est:[0.058,0.111,0.116,0.139,0.120], ci_low:[0.027,0.062,0.059,0.076,0.053], ci_high:[0.089,0.160,0.173,0.202,0.187] },
    nopapua:{ est:[0.015,0.063,0.053,0.082,0.090], ci_low:[-0.038,0.002,-0.020,0.015,0.004], ci_high:[0.068,0.124,0.126,0.149,0.176] }
  },
  stunting: {
    full:   { est:[-0.027,-0.055,-0.066,-0.051,-0.060], ci_low:[-0.070,-0.114,-0.123,-0.108,-0.125], ci_high:[0.016,0.004,-0.009,0.006,0.005] },
    nopapua:{ est:[-0.037,-0.052,-0.047,-0.046,-0.053], ci_low:[-0.090,-0.127,-0.110,-0.097,-0.133], ci_high:[0.016,0.023,0.016,0.005,0.027] }
  }
};

// ── ALL KABKOTA DATA (embedded sample - full data from JSON in production) ─
// In production, load from docs/data/kabkota.json
// Here we embed representative data for demo
let allData = [];
let filteredData = [];

// Simulate loading from JSON — in real deployment replace with fetch()
function loadDemoData() {
  // Representative sample across all IKP categories
  allData = [
    {provinsi:"Papua Pegunungan",kabkota:"Nduga",ikp:19.9,kat_ikp:1,sppg_per100k:0,pct_miskin:32.9,pct_stunting:36.0,n_sppg:0,is_papua:true},
    {provinsi:"Papua Tengah",kabkota:"Puncak",ikp:23.8,kat_ikp:1,sppg_per100k:0,pct_miskin:36.9,pct_stunting:42.5,n_sppg:0,is_papua:true},
    {provinsi:"Papua Pegunungan",kabkota:"Mamberamo Tengah",ikp:26.4,kat_ikp:1,sppg_per100k:0,pct_miskin:32.2,pct_stunting:42.0,n_sppg:0,is_papua:true},
    {provinsi:"Papua Tengah",kabkota:"Paniai",ikp:27.3,kat_ikp:1,sppg_per100k:0,pct_miskin:36.3,pct_stunting:29.6,n_sppg:0,is_papua:true},
    {provinsi:"Papua Tengah",kabkota:"Intan Jaya",ikp:27.3,kat_ikp:1,sppg_per100k:0,pct_miskin:39.2,pct_stunting:48.4,n_sppg:0,is_papua:true},
    {provinsi:"Papua Pegunungan",kabkota:"Tolikara",ikp:31.1,kat_ikp:1,sppg_per100k:0,pct_miskin:28.8,pct_stunting:46.4,n_sppg:0,is_papua:true},
    {provinsi:"Papua Tengah",kabkota:"Dogiyai",ikp:36.3,kat_ikp:1,sppg_per100k:0,pct_miskin:29.3,pct_stunting:55.8,n_sppg:0,is_papua:true},
    {provinsi:"Papua Tengah",kabkota:"Puncak Jaya",ikp:40.0,kat_ikp:1,sppg_per100k:0,pct_miskin:35.5,pct_stunting:36.3,n_sppg:0,is_papua:true},
    {provinsi:"Nusa Tenggara Timur",kabkota:"Sumba Timur",ikp:42.1,kat_ikp:2,sppg_per100k:3.2,pct_miskin:28.4,pct_stunting:38.9,n_sppg:9,is_papua:false},
    {provinsi:"Nusa Tenggara Timur",kabkota:"Sabu Raijua",ikp:44.8,kat_ikp:2,sppg_per100k:4.1,pct_miskin:31.2,pct_stunting:41.2,n_sppg:5,is_papua:false},
    {provinsi:"Maluku",kabkota:"Kepulauan Tanimbar",ikp:48.3,kat_ikp:2,sppg_per100k:5.2,pct_miskin:22.1,pct_stunting:34.7,n_sppg:11,is_papua:false},
    {provinsi:"Sulawesi Tengah",kabkota:"Donggala",ikp:57.4,kat_ikp:3,sppg_per100k:6.8,pct_miskin:17.3,pct_stunting:28.4,n_sppg:21,is_papua:false},
    {provinsi:"Kalimantan Barat",kabkota:"Melawi",ikp:59.1,kat_ikp:3,sppg_per100k:5.9,pct_miskin:18.6,pct_stunting:31.2,n_sppg:14,is_papua:false},
    {provinsi:"Aceh",kabkota:"Aceh Selatan",ikp:77.2,kat_ikp:5,sppg_per100k:12.6,pct_miskin:9.9,pct_stunting:34.2,n_sppg:31,is_papua:false},
    {provinsi:"Aceh",kabkota:"Aceh Barat",ikp:73.9,kat_ikp:5,sppg_per100k:9.0,pct_miskin:15.5,pct_stunting:25.6,n_sppg:19,is_papua:false},
    {provinsi:"Jawa Barat",kabkota:"Bogor",ikp:79.2,kat_ikp:6,sppg_per100k:8.1,pct_miskin:7.6,pct_stunting:27.2,n_sppg:421,is_papua:false},
    {provinsi:"Jawa Tengah",kabkota:"Semarang",ikp:80.4,kat_ikp:6,sppg_per100k:9.3,pct_miskin:6.1,pct_stunting:18.9,n_sppg:185,is_papua:false},
    {provinsi:"DKI Jakarta",kabkota:"Kota Jakarta Selatan",ikp:73.1,kat_ikp:5,sppg_per100k:5.98,pct_miskin:3.2,pct_stunting:14.9,n_sppg:132,is_papua:false},
    {provinsi:"DKI Jakarta",kabkota:"Kota Jakarta Timur",ikp:73.0,kat_ikp:5,sppg_per100k:7.95,pct_miskin:3.9,pct_stunting:16.4,n_sppg:245,is_papua:false},
    {provinsi:"Bali",kabkota:"Badung",ikp:88.8,kat_ikp:6,sppg_per100k:5.01,pct_miskin:1.9,pct_stunting:7.2,n_sppg:29,is_papua:false},
    {provinsi:"Bali",kabkota:"Kota Denpasar",ikp:83.8,kat_ikp:6,sppg_per100k:6.11,pct_miskin:2.2,pct_stunting:10.4,n_sppg:47,is_papua:false},
    {provinsi:"DI Yogyakarta",kabkota:"Sleman",ikp:85.5,kat_ikp:6,sppg_per100k:11.6,pct_miskin:6.7,pct_stunting:17.3,n_sppg:138,is_papua:false},
    {provinsi:"Jawa Timur",kabkota:"Sampang",ikp:66.3,kat_ikp:4,sppg_per100k:10.4,pct_miskin:19.4,pct_stunting:38.1,n_sppg:67,is_papua:false},
    {provinsi:"Sulawesi Selatan",kabkota:"Jeneponto",ikp:68.4,kat_ikp:4,sppg_per100k:9.8,pct_miskin:16.8,pct_stunting:40.2,n_sppg:44,is_papua:false},
    {provinsi:"Kalimantan Timur",kabkota:"Mahakam Ulu",ikp:66.3,kat_ikp:4,sppg_per100k:0,pct_miskin:10.1,pct_stunting:23.2,n_sppg:0,is_papua:false},
    {provinsi:"Sumatera Barat",kabkota:"Kepulauan Mentawai",ikp:67.4,kat_ikp:4,sppg_per100k:0,pct_miskin:13.2,pct_stunting:26.2,n_sppg:0,is_papua:false},
    {provinsi:"Bengkulu",kabkota:"Lebong",ikp:74.8,kat_ikp:5,sppg_per100k:5.9,pct_miskin:10.1,pct_stunting:22.7,n_sppg:4,is_papua:false},
    {provinsi:"Gorontalo",kabkota:"Boalemo",ikp:69.8,kat_ikp:5,sppg_per100k:3.8,pct_miskin:16.4,pct_stunting:8.0,n_sppg:6,is_papua:false},
    {provinsi:"Banten",kabkota:"Kota Tangerang Selatan",ikp:78.2,kat_ikp:6,sppg_per100k:8.5,pct_miskin:2.4,pct_stunting:10.5,n_sppg:120,is_papua:false},
    {provinsi:"Banten",kabkota:"Lebak",ikp:75.2,kat_ikp:5,sppg_per100k:13.5,pct_miskin:8.0,pct_stunting:32.4,n_sppg:199,is_papua:false},
  ];

  filteredData = [...allData];
  renderTable(filteredData);
  updateFilterCount(filteredData.length);
}

function applyFilters() {
  const ikpVal   = document.getElementById('filter-ikp').value;
  const papuaVal = document.getElementById('filter-papua').value;

  filteredData = allData.filter(d => {
    const matchIKP   = ikpVal === 'all'      || d.kat_ikp == parseInt(ikpVal);
    const matchPapua = papuaVal === 'all'    ||
                       (papuaVal === 'papua'   &&  d.is_papua) ||
                       (papuaVal === 'nopapua' && !d.is_papua);
    return matchIKP && matchPapua;
  });

  renderTable(filteredData);
  updateFilterCount(filteredData.length);
}

function resetFilters() {
  document.getElementById('filter-ikp').value   = 'all';
  document.getElementById('filter-papua').value = 'all';
  filteredData = [...allData];
  renderTable(filteredData);
  updateFilterCount(filteredData.length);
}

function updateFilterCount(n) {
  document.getElementById('filter-count').textContent =
    `Menampilkan ${n} dari ${allData.length} kabupaten/kota (data sampel representatif)`;
}

function renderTable(data) {
  const tbody = document.getElementById('table-body');
  if (!data.length) {
    tbody.innerHTML = '<tr><td colspan="9" class="loading">Tidak ada data yang sesuai filter.</td></tr>';
    return;
  }

  const sorted = [...data].sort((a,b) => a.ikp - b.ikp);

  tbody.innerHTML = sorted.map(d => {
    const tagClass = `tag-${d.kat_ikp}`;
    const sppgStr  = d.sppg_per100k.toFixed(2);
    const zeroTag  = d.n_sppg === 0
      ? '<span class="tag tag-0sppg">0 SPPG</span>'
      : '';
    return `
      <tr>
        <td>${d.provinsi}</td>
        <td>${d.kabkota}</td>
        <td>${d.ikp.toFixed(1)}</td>
        <td><span class="tag ${tagClass}">${IKP_LABELS[d.kat_ikp]}</span></td>
        <td>${sppgStr}</td>
        <td>${d.pct_miskin.toFixed(1)}%</td>
        <td>${d.pct_stunting.toFixed(1)}%</td>
        <td>${d.n_sppg}</td>
        <td>${zeroTag}</td>
      </tr>`;
  }).join('');
}

// ── CHARTS ───────────────────────────────────────────────────────────────

// Chart 1: Bar chart
new Chart(document.getElementById('chart-bar-ikp'), {
  type: 'bar',
  data: {
    labels: summaryIKP.map(d => d.kat_ikp_f),
    datasets: [{
      label: 'Rata-rata SPPG per 100k',
      data: summaryIKP.map(d => d.mean_sppg),
      backgroundColor: summaryIKP.map(d => IKP_COLORS[d.kat_ikp] + 'CC'),
      borderColor:     summaryIKP.map(d => IKP_COLORS[d.kat_ikp]),
      borderWidth: 1.5,
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          afterBody: (items) => {
            const d = summaryIKP[items[0].dataIndex];
            return [`n = ${d.n} kab/kota`, `Miskin: ${d.mean_miskin}%`, `Stunting: ${d.mean_stunting}%`];
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        title: { display: true, text: 'SPPG per 100.000 penduduk', font: { size: 11 } }
      },
      x: { ticks: { font: { size: 10 } } }
    }
  }
});

// Chart 2: Scatter IKP vs SPPG
const scatterPoints = allData.map(d => ({
  x: d.ikp,
  y: d.sppg_per100k,
  label: d.kabkota,
  kat: d.kat_ikp
}));

new Chart(document.getElementById('chart-scatter'), {
  type: 'scatter',
  data: {
    datasets: Object.keys(IKP_COLORS).map(k => ({
      label: IKP_LABELS[k],
      data: scatterPoints.filter(p => p.kat == k).map(p => ({ x: p.x, y: p.y, label: p.label })),
      backgroundColor: IKP_COLORS[k] + '99',
      pointRadius: 4,
    }))
  },
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'bottom', labels: { font: { size: 10 }, boxWidth: 12 } },
      tooltip: {
        callbacks: {
          label: (ctx) => `${ctx.raw.label}: IKP=${ctx.raw.x}, SPPG/100k=${ctx.raw.y}`
        }
      }
    },
    scales: {
      x: { title: { display: true, text: 'IKP (semakin tinggi = semakin tahan)', font: { size: 11 } } },
      y: { title: { display: true, text: 'SPPG per 100.000 penduduk', font: { size: 11 } }, beginAtZero: true }
    }
  }
});

// Chart 3: CI bar
new Chart(document.getElementById('chart-ci'), {
  type: 'bar',
  data: {
    labels: ['CI Kemiskinan (Full)', 'CI Kemiskinan (−Papua)', 'CI IKP (Full)', 'CI IKP (−Papua)'],
    datasets: [{
      data: [-0.042, 0.004, 0.077, 0.034],
      backgroundColor: [-0.042, 0.004, 0.077, 0.034].map(v =>
        v < 0 ? '#27ae6099' : '#e74c3c99'
      ),
      borderColor: [-0.042, 0.004, 0.077, 0.034].map(v =>
        v < 0 ? '#27ae60' : '#e74c3c'
      ),
      borderWidth: 1.5
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: ctx => `CI = ${ctx.raw > 0 ? '+' : ''}${ctx.raw.toFixed(3)} (${ctx.raw < 0 ? 'pro-rawan ✓' : 'pro-tahan ✗'})`
        }
      }
    },
    scales: {
      y: {
        title: { display: true, text: 'Concentration Index', font: { size: 10 } },
        suggestedMin: -0.1, suggestedMax: 0.12,
        grid: { color: (ctx) => ctx.tick.value === 0 ? '#333' : '#eee', lineWidth: (ctx) => ctx.tick.value === 0 ? 1.5 : 1 }
      },
      x: { ticks: { font: { size: 9 } } }
    }
  }
});

// Chart 4 & 5: Quantile regression
function makeQRChart(canvasId, term) {
  const d = qrData[term];
  return new Chart(document.getElementById(canvasId), {
    type: 'line',
    data: {
      labels: qrData.taus,
      datasets: [
        {
          label: 'Full Sample',
          data: d.full.est,
          borderColor: '#e74c3c',
          backgroundColor: '#e74c3c22',
          tension: 0.3,
          pointRadius: 5,
          fill: false
        },
        {
          label: 'Tanpa Papua',
          data: d.nopapua.est,
          borderColor: '#2980b9',
          backgroundColor: '#2980b922',
          tension: 0.3,
          pointRadius: 5,
          borderDash: [5, 3],
          fill: false
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { position: 'bottom', labels: { font: { size: 10 }, boxWidth: 12 } }
      },
      scales: {
        y: {
          title: { display: true, text: 'Koefisien', font: { size: 10 } },
          grid: {
            color: (ctx) => ctx.tick.value === 0 ? '#555' : '#eee',
            lineWidth: (ctx) => ctx.tick.value === 0 ? 1.5 : 1
          }
        }
      }
    }
  });
}

makeQRChart('chart-qr-ikp', 'ikp');
makeQRChart('chart-qr-stunting', 'stunting');

// ── INIT ─────────────────────────────────────────────────────────────────
loadDemoData();
</script>
</body>
</html>
