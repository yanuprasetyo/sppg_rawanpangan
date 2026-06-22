# Dapur untuk Siapa? Distribusi SPPG dan Kerawanan Pangan di Indonesia

[![Data](https://img.shields.io/badge/Data-BGN%20%7C%20Bapanas%20%7C%20BPS%20%7C%20Kemenkes-blue)](https://www.bgn.go.id)
[![Status](https://img.shields.io/badge/Status-Peer%20Review-orange)](https://github.com/yanuprasetyo/sppg_rawanpangan)
[![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-green)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Dashboard](https://img.shields.io/badge/Dashboard-Live-brightgreen)](https://yanuprasetyo.github.io/sppg_rawanpangan)

> **Temuan kritis:** Wilayah paling rawan pangan (IKP kategori 1) rata-rata hanya mendapat **1,13 SPPG per 100.000 penduduk** — hampir 8× lebih sedikit dibanding wilayah sangat tahan pangan (9,00). Distribusi SPPG bersifat *pro-tahan pangan*, bukan pro-rawan pangan. Paradoks stunting terkonfirmasi statistik di semua model.

---

## Tentang Penelitian

Repositori ini berisi seluruh pipeline analisis untuk paper:

> Prasetyo, Y.E., Aini, Y.N., Bahagijo, S., & Rossinda, S. (2026). *Dapur untuk Siapa? Distribusi Satuan Pelayanan Pemenuhan Gizi (SPPG) Program Makan Bergizi Gratis dan Kerawanan Pangan di Indonesia.* Pusat Riset Kependudukan, BRIN.

Program Makan Bergizi Gratis (MBG) beroperasi melalui **27.427 Satuan Pelayanan Pemenuhan Gizi (SPPG/dapur)** yang tersebar di seluruh Indonesia per 1 Mei 2026. Studi ini menguji apakah distribusi dapur tersebut berpihak pada wilayah yang paling membutuhkan — diukur menggunakan Indeks Ketahanan & Kerentanan Pangan (IKP/FSVA) Bapanas — atau justru sebaliknya.

**Catatan verifikasi data:** Seluruh nilai jumlah SPPG per kabupaten/kota dalam analisis ini telah direkonsiliasi dan diverifikasi terhadap data mentah BGN. Total 27.427 SPPG dari 514 kabupaten/kota telah dikonfirmasi cocok persis dengan sumber asli. Seluruh hasil statistik (OLS, Tobit, Quantile Regression, Concentration Index) telah dijalankan ulang menggunakan data terverifikasi ini dan dikonfirmasi akurat.

---

## Struktur Repositori

```
sppg_rawanpangan/
├── data/
│   └── sppg_ikp.xlsx          # Data analisis utama (514 kab/kota, terverifikasi)
├── docs/
│   ├── index.html             # Dashboard: Dapur untuk Siapa?
│   └── data/
│       ├── kabkota.json       # Data lengkap 514 kab/kota
│       ├── summary_ikp.json   # Ringkasan per kategori IKP
│       ├── ci_results.json    # Concentration Index
│       ├── regression_coef.json  # Koefisien OLS & Tobit
│       └── quantile_coef.json    # Koefisien Quantile Regression
├── output/
│   ├── fig1_boxplot_ikp.png
│   ├── fig2_scatter_ikp.png
│   ├── fig3_scatter_kemiskinan.png
│   ├── fig4_robustness_boxplot.png
│   └── fig5_quantile_coef.png
├── analisis_sppg_ikp.R        # Script R lengkap (Steps 1–8)
└── README.md
```

---

## Data

### Sumber

| Dataset | Sumber | Tahun | Keterangan |
|---|---|---|---|
| Jumlah SPPG per kab/kota | BGN (bgn.go.id) | 2026 | Per 1 Mei 2026 · 27.427 SPPG · **terverifikasi** |
| Indeks Ketahanan & Kerentanan Pangan (IKP) | Bapanas FSVA | 2024 | 6 kategori: Sangat Rentan–Sangat Tahan |
| Populasi & kemiskinan | BPS | 2024 | Proyeksi 2026 |
| Prevalensi stunting balita | SSGI Kemenkes | 2022 | Terakhir tersedia level kab/kota |
| Jumlah sekolah | Kemdikdasmen | 2024 | SD+SMP+SMA+SMK |

### Deskripsi Variabel Utama (`data/sppg_ikp.xlsx`)

| Variabel | Keterangan |
|---|---|
| `Provinsi` | Nama provinsi |
| `Kabupaten/Kota` | Nama kabupaten/kota |
| `Populasi 2026` | Proyeksi populasi 2026 |
| `Jumlah SPPG` | Jumlah dapur SPPG aktif per 1 Mei 2026 |
| `Jumlah Penduduk Miskin` | Jumlah absolut penduduk miskin |
| `Kemiskinan (%)` | Persentase penduduk miskin |
| `Stunting Balita (%)` | Prevalensi stunting balita |
| `Total Sekolah` | Total sekolah SD–SMK |
| `Indeks Ketahanan & Kerentanan Pangan (IKP)` | Skor IKP/FSVA Bapanas (0–100) |
| `Kategori IKP` | Kategori 1 (Sangat Rentan) – 6 (Sangat Tahan) |

### Statistik Deskriptif

**Distribusi SPPG per 100.000 Penduduk menurut Kategori IKP**

| Kategori IKP | n | Mean SPPG/100k | Median | Rata Kemiskinan | Rata Stunting |
|---|---|---|---|---|---|
| 1 · Sangat Rentan | 20 | **1,13** | 0,00 | 30,1% | 37,3% |
| 2 · Rentan | 19 | 4,36 | 3,92 | 23,0% | 30,1% |
| 3 · Agak Rentan | 42 | 6,60 | 6,50 | 16,9% | 30,6% |
| 4 · Agak Tahan | 111 | 8,77 | 8,62 | 10,7% | 24,2% |
| 5 · Tahan | 216 | 9,36 | 9,68 | 8,3% | 20,1% |
| 6 · Sangat Tahan | 106 | **9,00** | 8,57 | 6,7% | 19,3% |

Gradien hampir monoton: semakin rawan, semakin sedikit SPPG yang diterima (rasio 1:8 antara kategori paling rentan dan paling tahan).

---

## Metodologi

Script R `analisis_sppg_ikp.R` menjalankan delapan langkah berurutan:

### Step 1 — Persiapan Data
- Load `data/sppg_ikp.xlsx`
- Hitung variabel turunan: `sppg_per100k`, `sppg_per_miskin`, `sppg_per_sekolah`
- Flag kabupaten Papua dan 0 SPPG
- Buat dataset tanpa Papua untuk robustness check

### Step 2 — Statistik Deskriptif
- Ringkasan mean, median, SD per kategori IKP
- Daftar 16 kabupaten dengan 0 SPPG

### Step 3 — Uji Perbedaan Antar Kelompok
- **Kruskal-Wallis** (non-parametrik): H = 87,82, p < 0,0001 (full); H = 29,40, p < 0,0001 (tanpa Papua)
- **Post-hoc Dunn** dengan koreksi Bonferroni
- **Mann-Whitney** Rawan (IKP 1–3) vs Tahan (IKP 4–6)

### Step 4 — Concentration Index (CI)
Mengikuti Wagstaff et al. (1991):

| Basis Ranking | CI Full Sample | CI Tanpa Papua | Interpretasi |
|---|---|---|---|
| Kemiskinan (%) | −0,042 | +0,004 | Kesan pro-poor hilang tanpa Papua |
| IKP (ketahanan pangan) | **+0,077** | **+0,034** | Pro-tahan pangan di kedua sampel |

CI > 0 berarti distribusi SPPG berpihak pada wilayah yang *lebih tahan pangan* — berlawanan dengan tujuan program.

### Step 5 — Regresi OLS dan Tobit
Variabel dependen: `sppg_per100k`. Tobit mengatasi *left-censoring* pada 16 kabupaten dengan 0 SPPG.

| Variabel | OLS Full | OLS −Papua | Tobit Full | Tobit −Papua | Arah Harapan |
|---|---|---|---|---|---|
| Kemiskinan (%) | −0,025 | +0,026 | −0,038 | +0,026 | + ✗ |
| Stunting (%) | −0,053** | −0,058** | −0,055** | −0,058** | + ✗ |
| IKP | +0,102*** | +0,057* | +0,118*** | +0,057* | − ✗ |
| log(Populasi) | +0,409** | +0,473** | +0,404** | +0,479** | netral |
| n | 514 | 472 | 514 | 472 | |
| R² | 0,160 | 0,050 | — | — | |

\* p<0,1; \*\* p<0,05; \*\*\* p<0,01. Semua tiga variabel kebutuhan berlawanan arah dari harapan.

R² anjlok dari 0,160 ke 0,050 saat Papua dikeluarkan — menunjukkan bahwa di luar Papua, faktor kebutuhan hampir tidak menjelaskan penempatan SPPG.

### Step 6 — Quantile Regression
Dijalankan pada τ = 0,10; 0,25; 0,50; 0,75; 0,90 dengan SE bootstrap (R = 1.000). Mismatch terjadi **konsisten di seluruh distribusi**, bukan hanya di rata-rata:

**Koefisien IKP per Kuantil (Full Sample)**

| Kuantil | Koefisien | p-value |
|---|---|---|
| Q10 | +0,058 | 0,047* |
| Q25 | +0,111 | <0,001*** |
| Q50 | +0,116 | <0,001*** |
| Q75 | +0,139 | <0,001*** |
| Q90 | +0,120 | 0,003*** |

**Koefisien Stunting per Kuantil (Full Sample)**

| Kuantil | Koefisien | p-value |
|---|---|---|
| Q10 | −0,027 | 0,349 |
| Q25 | −0,055 | 0,076* |
| Q50 | −0,066 | 0,028** |
| Q75 | −0,051 | 0,102 |
| Q90 | −0,060 | 0,130 |

### Step 7 — Visualisasi
Lima figur tersimpan di `output/`:

| File | Isi |
|---|---|
| `fig1_boxplot_ikp.png` | Boxplot distribusi SPPG/100k per kategori IKP |
| `fig2_scatter_ikp.png` | Scatter IKP vs SPPG/100k, diwarnai per kategori |
| `fig3_scatter_kemiskinan.png` | Scatter kemiskinan vs SPPG/100k |
| `fig4_robustness_boxplot.png` | Robustness check: full sample vs tanpa Papua (side-by-side) |
| `fig5_quantile_coef.png` | Koefisien QR lintas kuantil: IKP dan Stunting |

### Step 8 — Ekspor Data Dashboard
Lima file JSON diekspor ke `docs/data/` untuk konsumsi dashboard interaktif.

---

## Temuan Utama

**1. Gradien terbalik (1:8)**
Kruskal-Wallis χ² = 87,82 (p < 0,0001). Wilayah Sangat Rentan mendapat rata-rata 1,13 SPPG/100k vs 9,00 di Sangat Tahan. Temuan bertahan saat Papua dikeluarkan (H = 29,40, p < 0,0001).

**2. Paradoks stunting**
Koefisien stunting negatif dan signifikan secara konsisten di semua model — OLS, Tobit, maupun Quantile Regression. Wilayah dengan beban stunting lebih tinggi justru menerima lebih sedikit SPPG. Ini adalah mismatch yang paling mengkhawatirkan mengingat tujuan program secara eksplisit menyasar penurunan stunting.

**3. Distribusi pro-tahan pangan**
Concentration Index berbasis IKP = +0,077 (full) dan +0,034 (tanpa Papua). Kedua nilai positif, menunjukkan distribusi secara konsisten berpihak ke wilayah yang lebih tahan pangan.

**4. Bukan hanya masalah Papua**
Semua temuan bertahan setelah 42 kabupaten dari 6 provinsi Papua dibuang dari analisis. Mismatch adalah pola sistemik nasional, bukan anomali yang didorong oleh outlier Papua.

**5. 61 kabupaten "krisis ganda"**
Kabupaten dengan IKP kategori 1–2 sekaligus stunting di atas median nasional hanya menerima 1,3% dari total SPPG nasional.

---

## Cara Menjalankan

### Prasyarat

```r
# R ≥ 4.3.0
install.packages(c(
  "readxl", "tidyverse", "dunn.test", "AER",
  "quantreg", "stargazer", "broom", "scales",
  "ggplot2", "patchwork", "jsonlite"
))
```

### Jalankan Analisis

```r
# Pastikan working directory di root repo
setwd("path/to/sppg_rawanpangan")

# Jalankan seluruh pipeline
source("analisis_sppg_ikp.R")
```

Output akan tersimpan di `output/` (gambar) dan `docs/data/` (JSON untuk dashboard).

### Struktur folder yang dibutuhkan sebelum menjalankan

```
sppg_rawanpangan/
├── data/sppg_ikp.xlsx   ← wajib ada
├── output/              ← dibuat otomatis
└── docs/data/           ← dibuat otomatis
```

---

## Dashboard Interaktif

Dashboard tersedia di: **https://yanuprasetyo.github.io/sppg_rawanpangan**

Dibangun dengan Chart.js. Menampilkan:
- Rata-rata SPPG/100k per kategori IKP (bar chart)
- Scatter IKP vs SPPG/100k (514 titik penuh, diwarnai per kategori)
- Tabel Concentration Index
- Tabel regresi OLS dan Tobit
- Koefisien Quantile Regression lintas kuantil
- Tabel data lengkap 514 kabupaten/kota dengan filter IKP dan Papua
- Unduh CSV

**Catatan teknis:** Semua nilai pada dashboard (jumlah SPPG per kab/kota, summary statistik, CI, koefisien regresi) telah diverifikasi ulang terhadap data mentah BGN. Tidak ada data placeholder atau estimasi — setiap angka dapat ditelusuri ke baris data di `sppg_ikp.xlsx`.

---

## Implikasi Kebijakan

**Reformulasi alokasi berbasis IKP/FSVA.** Integrasi skor IKP Bapanas sebagai variabel wajib dalam formula penentuan lokasi SPPG — dengan target Concentration Index IKP negatif sebagai indikator keberhasilan distribusi.

**Afirmasi 61 kabupaten krisis ganda.** Penetapan kabupaten dengan IKP rendah sekaligus stunting tinggi sebagai prioritas nasional ekspansi dapur, termasuk model operasional khusus untuk wilayah 3T di Papua.

**Simulasi redistribusi.** Formula 20% populasi + 40% kemiskinan + 40% stunting berpotensi menurunkan Gini koefisien distribusi SPPG sebesar 8,5% tanpa tambahan anggaran, melalui redistribusi sekitar 5.787 dapur (21,1% dari total).

---

## Keterbatasan

- Data stunting menggunakan SSGI 2022 karena belum ada estimasi level kabupaten/kota yang lebih baru.
- Analisis bersifat cross-sectional; kausalitas tidak dapat diklaim.
- IKP/FSVA mengukur ketahanan pangan secara komposit — tidak memisahkan dimensi akses, ketersediaan, dan pemanfaatan pangan.
- Data SPPG per 1 Mei 2026 bersifat *snapshot*; distribusi terus berkembang seiring penambahan dapur baru.

---

## Kutipan

```bibtex
@techreport{prasetyo2026dapur,
  author      = {Prasetyo, Yanu Endar and Aini, Yusnita Nur and
                 Bahagijo, Sugeng and Rossinda, Siti},
  title       = {Dapur untuk Siapa? Distribusi Satuan Pelayanan
                 Pemenuhan Gizi (SPPG) Program Makan Bergizi Gratis
                 dan Kerawanan Pangan di Indonesia},
  institution = {Pusat Riset Kependudukan, Badan Riset dan
                 Inovasi Nasional (BRIN)},
  year        = {2026},
  url         = {https://github.com/yanuprasetyo/sppg_rawanpangan}
}
```

---

## Lisensi

Kode: [MIT License](LICENSE)
Data & konten: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — bebas digunakan untuk keperluan non-komersial dengan atribusi.

---

## Kontak

**Yanu Endar Prasetyo, Ph.D.**
Peneliti Ahli Madya, Pusat Riset Kependudukan, BRIN
INFID Research Fellow · Founder, Indonesian Basic Income Guarantee Network (indobig.net)

Pertanyaan tentang data atau metodologi: buka [GitHub Issue](https://github.com/yanuprasetyo/sppg_rawanpangan/issues) atau hubungi melalui profil GitHub.
