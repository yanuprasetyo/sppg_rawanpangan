# =============================================================================
# ANALISIS KETEPATSASARAN DISTRIBUSI SPPG PROGRAM MBG
# Berdasarkan Indeks Ketahanan & Kerentanan Pangan (IKP/FSVA)
# -----------------------------------------------------------------------------
# Penulis   : Yanu Endar Prasetyo et al.
# Institusi : Pusat Riset Kependudukan, BRIN
# Tahun     : 2026
# Versi     : 2.0 (diperbarui setelah rekonsiliasi data BGN, Juni 2026)
# Repo      : https://github.com/yanuprasetyo/sppg_rawanpangan
# -----------------------------------------------------------------------------
# CATATAN VERIFIKASI DATA (v2.0):
#   Data n_sppg per kabupaten/kota dalam sppg_ikp.xlsx telah direkonsiliasi
#   dan diverifikasi terhadap data mentah BGN (27.427 titik SPPG per
#   1 Mei 2026). Total nasional, per provinsi, dan per kabupaten/kota
#   dikonfirmasi cocok persis. Script ini menyertakan blok stopifnot() pada
#   Step 1 dan Step 8 untuk memastikan integritas data sebelum analisis
#   dan sebelum ekspor.
#
# PERUBAHAN v2.0 vs v1.0:
#   - [Step 0]  jsonlite dipindah ke deklarasi packages di awal
#   - [Step 0]  set.seed(42) ditambahkan untuk reproducibility bootstrap QR
#   - [Step 1]  Blok verifikasi data (stopifnot) ditambahkan
#   - [Step 6]  extract_coef: R=500 → R=1000 (konsisten dengan ringkasan)
#   - [Step 7]  fig6 baru: scatter stunting vs SPPG/100k (paradoks stunting)
#   - [Step 7]  Caption semua figur diperbarui: "Data per 1 Mei 2026"
#   - [Step 8]  Ekspor JS embed (RAW array & allData) untuk dashboard statis
#   - [Step 8]  Ekspor CSV kabkota untuk fitur unduh di dashboard
#   - [Step 8]  stopifnot verifikasi total sebelum ekspor
#   - [Step 9]  Blok baru: audit trail angka kunci
# =============================================================================


# ── 0. PACKAGES ───────────────────────────────────────────────────────────────
pkgs <- c(
  "readxl", "tidyverse", "dunn.test", "AER",
  "quantreg", "stargazer", "broom", "scales",
  "ggplot2", "patchwork", "jsonlite"   # jsonlite dipindah ke sini dari Step 8
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
invisible(lapply(pkgs, install_if_missing))
invisible(lapply(pkgs, library, character.only = TRUE))

# Seed global untuk reproducibility semua prosedur bootstrap (QR Step 6)
set.seed(42)

cat("Semua package berhasil dimuat.\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Dijalankan: %s\n\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))


# =============================================================================
# STEP 1: LOAD DATA DAN PERSIAPAN
# =============================================================================

df_raw <- read_excel("data/sppg_ikp.xlsx")

df <- df_raw |>
  rename(
    provinsi       = `Provinsi`,
    kabkota        = `Kabupaten/Kota`,
    populasi       = `Populasi 2026`,
    n_sppg         = `Jumlah SPPG`,
    n_miskin       = `Jumlah Penduduk Miskin`,
    pct_miskin     = `Kemiskinan (%)`,
    pct_stunting   = `Stunting Balita (%)`,
    total_sekolah  = `Total Sekolah`,
    ikp            = `Indeks Ketahanan & Kerentanan Pangan (IKP)`,
    rank_ikp       = `Rank IKP`,
    kat_ikp        = `Kategori IKP`
  ) |>
  filter(!is.na(n_sppg), !is.na(ikp)) |>
  mutate(
    # Variabel turunan
    sppg_per100k     = (n_sppg / populasi) * 100000,
    sppg_per_miskin  = (n_sppg / n_miskin) * 1000,
    sppg_per_sekolah = n_sppg / total_sekolah,

    # Kategori IKP sebagai factor
    kat_ikp_f = factor(kat_ikp,
                       levels = 1:6,
                       labels = c("Sangat Rentan", "Rentan",
                                  "Agak Rentan",   "Agak Tahan",
                                  "Tahan",         "Sangat Tahan")),

    # Grup biner: rawan vs tahan
    grup_ikp = if_else(kat_ikp <= 3, "Rawan (1-3)", "Tahan (4-6)"),

    # Flag kabupaten tanpa SPPG
    zero_sppg = if_else(n_sppg == 0, "Nol SPPG", "Ada SPPG"),

    # Identifikasi Papua (6 provinsi pemekaran)
    is_papua = provinsi %in% c("Papua", "Papua Barat", "Papua Barat Daya",
                                "Papua Pegunungan", "Papua Selatan",
                                "Papua Tengah")
  )

# Dataset tanpa Papua
df_nopapua <- df |> filter(!is_papua)

# ── Verifikasi integritas data ─────────────────────────────────────────────
# Angka-angka ini adalah nilai terverifikasi dari rekonsiliasi data BGN v2.0
# Jika ada perbedaan, cek sumber data sebelum melanjutkan analisis.
cat("\n--- VERIFIKASI INTEGRITAS DATA ---\n")
cat(sprintf("Full sample        : %d kab/kota  (expected: 514)\n", nrow(df)))
cat(sprintf("Tanpa Papua        : %d kab/kota  (expected: 472)\n", nrow(df_nopapua)))
cat(sprintf("Kabupaten 0 SPPG   : %d           (expected: 16)\n",  sum(df$n_sppg == 0)))
cat(sprintf("Total SPPG nasional: %s            (expected: 27,427)\n",
            format(sum(df$n_sppg), big.mark = ",")))

stopifnot(
  "n ≠ 514: cek filter data"          = nrow(df) == 514,
  "n_nopapua ≠ 472: cek Papua flag"   = nrow(df_nopapua) == 472,
  "Total SPPG ≠ 27427: cek sumber"    = sum(df$n_sppg) == 27427,
  "Kab 0 SPPG ≠ 16: cek data"        = sum(df$n_sppg == 0) == 16
)
cat("✓ Semua cek integritas lulus.\n\n")

glimpse(df)
summary(df[, c("sppg_per100k", "ikp", "pct_miskin", "pct_stunting")])


# =============================================================================
# STEP 2: STATISTIK DESKRIPTIF
# =============================================================================

cat("\n===== STEP 2: STATISTIK DESKRIPTIF =====\n")

tabel_deskriptif <- df |>
  group_by(kat_ikp_f) |>
  summarise(
    n             = n(),
    mean_sppg     = round(mean(sppg_per100k, na.rm = TRUE), 2),
    median_sppg   = round(median(sppg_per100k, na.rm = TRUE), 2),
    sd_sppg       = round(sd(sppg_per100k, na.rm = TRUE), 2),
    mean_miskin   = round(mean(pct_miskin, na.rm = TRUE), 2),
    mean_stunting = round(mean(pct_stunting, na.rm = TRUE), 2),
    .groups = "drop"
  )

print(tabel_deskriptif)

cat("\nKabupaten dengan 0 SPPG:\n")
df |>
  filter(n_sppg == 0) |>
  select(provinsi, kabkota, pct_miskin, pct_stunting, ikp, kat_ikp_f) |>
  arrange(ikp) |>
  print(n = Inf)


# =============================================================================
# STEP 3: UJI PERBEDAAN ANTAR KELOMPOK
# =============================================================================

cat("\n===== STEP 3: UJI KRUSKAL-WALLIS & DUNN =====\n")

# 3a. Kruskal-Wallis
kw_full <- kruskal.test(sppg_per100k ~ kat_ikp_f, data = df)
kw_nop  <- kruskal.test(sppg_per100k ~ kat_ikp_f, data = df_nopapua)

cat("Kruskal-Wallis (Full Sample):\n"); print(kw_full)
cat("\nKruskal-Wallis (Tanpa Papua):\n"); print(kw_nop)

# 3b. Post-hoc Dunn dengan koreksi Bonferroni
cat("\nDunn Test (Full Sample, Bonferroni):\n")
dunn.test(df$sppg_per100k, df$kat_ikp_f,
          method = "bonferroni", kw = TRUE, label = TRUE)

cat("\nDunn Test (Tanpa Papua, Bonferroni):\n")
dunn.test(df_nopapua$sppg_per100k, df_nopapua$kat_ikp_f,
          method = "bonferroni", kw = TRUE, label = TRUE)

# 3c. Mann-Whitney: Rawan (IKP 1-3) vs Tahan (IKP 4-6)
mw_full <- wilcox.test(sppg_per100k ~ grup_ikp, data = df)
mw_nop  <- wilcox.test(sppg_per100k ~ grup_ikp, data = df_nopapua)

cat("\nMann-Whitney Rawan vs Tahan (Full):\n"); print(mw_full)
cat("\nMann-Whitney Rawan vs Tahan (Tanpa Papua):\n"); print(mw_nop)


# =============================================================================
# STEP 4: CONCENTRATION INDEX
# =============================================================================

cat("\n===== STEP 4: CONCENTRATION INDEX =====\n")
cat("Metode: Wagstaff et al. (1991)\n")
cat("CI < 0 = pro-rawan/pro-poor (diinginkan)\n")
cat("CI > 0 = pro-tahan/pro-rich (tidak diinginkan)\n\n")

calc_ci <- function(benefit_var, rank_var, data) {
  d <- data |>
    filter(!is.na(.data[[benefit_var]]),
           !is.na(.data[[rank_var]])) |>
    arrange(.data[[rank_var]]) |>
    mutate(n  = n(),
           ri = (2 * row_number() - 1) / (2 * n))
  y_mean <- mean(d[[benefit_var]], na.rm = TRUE)
  ci     <- (2 / y_mean) * cov(d$ri, d[[benefit_var]])
  return(round(ci, 4))
}

# Full sample
df_ci_full <- df |>
  mutate(rank_miskin = rank(pct_miskin, ties.method = "average"),
         rank_ikp2   = rank(ikp,        ties.method = "average"))

# Tanpa Papua
df_ci_nop <- df_nopapua |>
  mutate(rank_miskin = rank(pct_miskin, ties.method = "average"),
         rank_ikp2   = rank(ikp,        ties.method = "average"))

ci_results <- tibble(
  Basis          = c("Kemiskinan (%)", "IKP (ketahanan pangan)"),
  CI_Full_Sample = c(
    calc_ci("sppg_per100k", "rank_miskin", df_ci_full),
    calc_ci("sppg_per100k", "rank_ikp2",   df_ci_full)
  ),
  CI_Tanpa_Papua = c(
    calc_ci("sppg_per100k", "rank_miskin", df_ci_nop),
    calc_ci("sppg_per100k", "rank_ikp2",   df_ci_nop)
  )
)

print(ci_results)

# Interpretasi eksplisit
cat("\nInterpretasi:\n")
for (i in seq_len(nrow(ci_results))) {
  cf  <- ci_results$CI_Full_Sample[i]
  cn  <- ci_results$CI_Tanpa_Papua[i]
  cat(sprintf(
    "  %-25s Full=%+.4f (%s) | Tanpa Papua=%+.4f (%s)\n",
    ci_results$Basis[i],
    cf, if (cf < 0) "pro-rawan ✓" else "pro-tahan ✗",
    cn, if (cn < 0) "pro-rawan ✓" else "pro-tahan ✗"
  ))
}


# =============================================================================
# STEP 5: REGRESI OLS DAN TOBIT
# =============================================================================

cat("\n===== STEP 5: REGRESI OLS & TOBIT =====\n")

formula_reg <- sppg_per100k ~ pct_miskin + pct_stunting + ikp + log(populasi)

# OLS
ols_full <- lm(formula_reg, data = df)
ols_nop  <- lm(formula_reg, data = df_nopapua)

# Tobit — left-censored pada 0 (untuk 16 kabupaten dengan 0 SPPG)
tobit_full <- tobit(formula_reg, left = 0, right = Inf, data = df)
tobit_nop  <- tobit(formula_reg, left = 0, right = Inf, data = df_nopapua)

cat("\nRingkasan OLS Full:\n");        print(summary(ols_full))
cat("\nRingkasan OLS Tanpa Papua:\n"); print(summary(ols_nop))
cat("\nRingkasan Tobit Full:\n");        print(summary(tobit_full))
cat("\nRingkasan Tobit Tanpa Papua:\n"); print(summary(tobit_nop))

# Tabel perbandingan empat model
stargazer(ols_full, ols_nop, tobit_full, tobit_nop,
          type             = "text",
          title            = "Robustness Check: Full Sample vs Tanpa Papua",
          column.labels    = c("OLS Full", "OLS -Papua",
                               "Tobit Full", "Tobit -Papua"),
          dep.var.labels   = "SPPG per 100.000 Penduduk",
          covariate.labels = c("Kemiskinan (%)", "Stunting (%)",
                               "IKP", "log(Populasi)"),
          digits           = 3,
          star.cutoffs     = c(0.1, 0.05, 0.01))


# =============================================================================
# STEP 6: QUANTILE REGRESSION
# =============================================================================

cat("\n===== STEP 6: QUANTILE REGRESSION =====\n")

tau_seq <- c(0.10, 0.25, 0.50, 0.75, 0.90)

# set.seed sudah dipanggil di awal (Step 0) untuk reproducibility

# Full sample
qr_full_list <- lapply(tau_seq, function(t)
  rq(formula_reg, tau = t, data = df))

# Tanpa Papua
qr_nop_list <- lapply(tau_seq, function(t)
  rq(formula_reg, tau = t, data = df_nopapua))

# Ringkasan dengan SE bootstrap R=1000
cat("\nQuantile Regression (Full Sample):\n")
lapply(seq_along(tau_seq), function(i) {
  cat(sprintf("\n--- tau = %.2f ---\n", tau_seq[i]))
  print(summary(qr_full_list[[i]], se = "boot", R = 1000))
})

cat("\nQuantile Regression (Tanpa Papua):\n")
lapply(seq_along(tau_seq), function(i) {
  cat(sprintf("\n--- tau = %.2f ---\n", tau_seq[i]))
  print(summary(qr_nop_list[[i]], se = "boot", R = 1000))
})

# Tabel stargazer
stargazer(qr_full_list[[1]], qr_full_list[[2]], qr_full_list[[3]],
          qr_full_list[[4]], qr_full_list[[5]], ols_full,
          type             = "text",
          title            = "Quantile Regression (Full Sample)",
          column.labels    = c("Q10","Q25","Q50","Q75","Q90","OLS"),
          dep.var.labels   = "SPPG per 100.000 Penduduk",
          covariate.labels = c("Kemiskinan (%)","Stunting (%)","IKP","log(Populasi)"),
          digits           = 3,
          star.cutoffs     = c(0.1, 0.05, 0.01))

# Ekstrak koefisien untuk visualisasi (R=1000, konsisten dengan ringkasan)
extract_coef <- function(model, tau, sampel) {
  s       <- summary(model, se = "boot", R = 1000)   # diperbaiki: R=500 → R=1000
  coef_df <- as.data.frame(s$coefficients)
  coef_df$term   <- rownames(coef_df)
  coef_df$tau    <- tau
  coef_df$sampel <- sampel
  coef_df
}

df_coef_full <- purrr::map2_dfr(qr_full_list, tau_seq,
                                 ~ extract_coef(.x, .y, "Full Sample"))
df_coef_nop  <- purrr::map2_dfr(qr_nop_list,  tau_seq,
                                 ~ extract_coef(.x, .y, "Tanpa Papua"))

df_coef_all <- bind_rows(df_coef_full, df_coef_nop) |>
  rename(estimate = Value, se = `Std. Error`,
         t_val = `t value`, p_val = `Pr(>|t|)`) |>
  mutate(ci_low  = estimate - 1.96 * se,
         ci_high = estimate + 1.96 * se) |>
  filter(term != "(Intercept)")


# =============================================================================
# STEP 7: VISUALISASI
# =============================================================================

cat("\n===== STEP 7: VISUALISASI =====\n")

dir.create("output", showWarnings = FALSE)

# Caption standar
cap_bgn_bapanas <- "Sumber: BGN (2026), Bapanas FSVA (2024) · Data per 1 Mei 2026"
cap_bgn_bps     <- "Sumber: BGN (2026), BPS (2024) · Data per 1 Mei 2026"
cap_bgn_all     <- "Sumber: BGN (2026), Bapanas FSVA (2024), BPS (2024) · Data per 1 Mei 2026"

# 7a. Boxplot SPPG per kategori IKP ─────────────────────────────────────────
p1 <- ggplot(df, aes(x = kat_ikp_f, y = sppg_per100k, fill = kat_ikp_f)) +
  geom_boxplot(outlier.shape = 21, alpha = 0.75) +
  scale_fill_brewer(palette = "RdYlGn") +
  labs(
    title    = "Distribusi SPPG per 100.000 Penduduk\nmenurut Kategori IKP (FSVA)",
    subtitle = "Jika tepat sasaran: kotak kiri (Rentan) seharusnya lebih tinggi",
    x        = "Kategori Indeks Ketahanan & Kerentanan Pangan",
    y        = "SPPG per 100.000 Penduduk",
    caption  = cap_bgn_bapanas
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 20, hjust = 1))

ggsave("output/fig1_boxplot_ikp.png", p1, width = 10, height = 6, dpi = 150)

# 7b. Scatter: IKP vs SPPG per 100k ─────────────────────────────────────────
p2 <- ggplot(df, aes(x = ikp, y = sppg_per100k)) +
  geom_point(aes(color = kat_ikp_f, size = populasi / 1e6), alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE,
              color = "black", linetype = "dashed", linewidth = 0.8) +
  scale_color_brewer(palette = "RdYlGn", name = "Kategori IKP") +
  scale_size_continuous(name = "Populasi (juta)", range = c(1, 8)) +
  labs(
    title    = "Indeks Ketahanan & Kerentanan Pangan vs. Cakupan SPPG",
    subtitle = "Tren positif = wilayah lebih tahan pangan mendapat lebih banyak SPPG",
    x        = "IKP (semakin tinggi = semakin tahan pangan)",
    y        = "SPPG per 100.000 Penduduk",
    caption  = cap_bgn_bapanas
  ) +
  theme_minimal(base_size = 12)

ggsave("output/fig2_scatter_ikp.png", p2, width = 10, height = 6, dpi = 150)

# 7c. Scatter: Kemiskinan vs SPPG per 100k ───────────────────────────────────
p3 <- ggplot(df, aes(x = pct_miskin, y = sppg_per100k)) +
  geom_point(aes(color = kat_ikp_f, size = populasi / 1e6), alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE,
              color = "black", linetype = "dashed", linewidth = 0.8) +
  scale_color_brewer(palette = "RdYlGn", name = "Kategori IKP") +
  scale_size_continuous(name = "Populasi (juta)", range = c(1, 8)) +
  labs(
    title    = "Kemiskinan vs. Cakupan SPPG per Kapita",
    subtitle = "Tren negatif = wilayah lebih miskin justru mendapat lebih sedikit SPPG",
    x        = "Tingkat Kemiskinan (%)",
    y        = "SPPG per 100.000 Penduduk",
    caption  = cap_bgn_bps
  ) +
  theme_minimal(base_size = 12)

ggsave("output/fig3_scatter_kemiskinan.png", p3, width = 10, height = 6, dpi = 150)

# 7d. Robustness check: full sample vs tanpa Papua ───────────────────────────
n_full <- nrow(df)
n_nop  <- nrow(df_nopapua)

df_plot <- bind_rows(
  df         |> mutate(sampel = paste0("Full Sample (n=", n_full, ")")),
  df_nopapua |> mutate(sampel = paste0("Tanpa Papua (n=", n_nop, ")"))
)

p4 <- ggplot(df_plot, aes(x = kat_ikp_f, y = sppg_per100k, fill = kat_ikp_f)) +
  geom_boxplot(outlier.shape = 21, alpha = 0.75) +
  facet_wrap(~ sampel, ncol = 2) +
  scale_fill_brewer(palette = "RdYlGn") +
  labs(
    title   = "Robustness Check: Full Sample vs Tanpa Papua",
    x       = "Kategori IKP",
    y       = "SPPG per 100.000 Penduduk",
    caption = cap_bgn_bapanas
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("output/fig4_robustness_boxplot.png", p4, width = 12, height = 6, dpi = 150)

# 7e. Quantile regression: koefisien IKP & Stunting lintas kuantil ───────────
p5 <- df_coef_all |>
  filter(term %in% c("ikp", "pct_stunting")) |>
  mutate(term = case_when(
    term == "ikp"          ~ "IKP",
    term == "pct_stunting" ~ "Stunting (%)",
    TRUE                   ~ term
  )) |>
  ggplot(aes(x = tau, y = estimate, color = sampel, fill = sampel)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high),
              alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  facet_wrap(~ term, scales = "free_y", ncol = 2) +
  scale_x_continuous(breaks = tau_seq,
                     labels = c("Q10","Q25","Q50","Q75","Q90")) +
  scale_color_manual(values = c("Full Sample" = "#E74C3C",
                                "Tanpa Papua" = "#2980B9")) +
  scale_fill_manual(values  = c("Full Sample" = "#E74C3C",
                                "Tanpa Papua" = "#2980B9")) +
  labs(
    title    = "Koefisien Quantile Regression: IKP dan Stunting",
    subtitle = "Area = 95% CI bootstrap (R=1000) | Garis putus = tidak ada efek (0)",
    x        = "Kuantil",
    y        = "Koefisien",
    color    = NULL, fill = NULL,
    caption  = cap_bgn_all
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave("output/fig5_quantile_coef.png", p5, width = 12, height = 6, dpi = 150)

# 7f. [BARU] Scatter: Stunting vs SPPG per 100k ──────────────────────────────
# Paradoks stunting adalah temuan kunci; figur tersendiri memperkuat narasi.
p6 <- ggplot(df, aes(x = pct_stunting, y = sppg_per100k)) +
  geom_point(aes(color = kat_ikp_f, size = populasi / 1e6), alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE,
              color = "black", linetype = "dashed", linewidth = 0.8) +
  scale_color_brewer(palette = "RdYlGn", name = "Kategori IKP") +
  scale_size_continuous(name = "Populasi (juta)", range = c(1, 8)) +
  annotate("text", x = max(df$pct_stunting, na.rm = TRUE) * 0.75,
           y = max(df$sppg_per100k, na.rm = TRUE) * 0.9,
           label = "Paradoks Stunting:\ntren negatif berlawanan\ndengan tujuan program",
           size = 3.5, color = "#c0392b", hjust = 0) +
  labs(
    title    = "Paradoks Stunting: Prevalensi Stunting vs. Cakupan SPPG",
    subtitle = "Wilayah dengan beban stunting lebih tinggi justru menerima lebih sedikit SPPG",
    x        = "Prevalensi Stunting Balita (%)",
    y        = "SPPG per 100.000 Penduduk",
    caption  = "Sumber: BGN (2026), Kemenkes SSGI (2022), Bapanas FSVA (2024) · Data per 1 Mei 2026"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/fig6_scatter_stunting.png", p6, width = 10, height = 6, dpi = 150)

cat("\nSemua visualisasi tersimpan di folder output/\n")
cat("  fig1_boxplot_ikp.png\n")
cat("  fig2_scatter_ikp.png\n")
cat("  fig3_scatter_kemiskinan.png\n")
cat("  fig4_robustness_boxplot.png\n")
cat("  fig5_quantile_coef.png\n")
cat("  fig6_scatter_stunting.png  [BARU]\n")


# =============================================================================
# STEP 8: EKSPOR DATA UNTUK DASHBOARD
# =============================================================================

cat("\n===== STEP 8: EKSPOR DATA DASHBOARD =====\n")

dir.create("docs/data", recursive = TRUE, showWarnings = FALSE)

# ── 8a. Data ringkasan per kategori IKP ─────────────────────────────────────
summary_ikp <- df |>
  group_by(kat_ikp, kat_ikp_f) |>
  summarise(
    n             = n(),
    mean_sppg     = round(mean(sppg_per100k, na.rm = TRUE), 3),
    median_sppg   = round(median(sppg_per100k, na.rm = TRUE), 3),
    sd_sppg       = round(sd(sppg_per100k, na.rm = TRUE), 3),
    mean_miskin   = round(mean(pct_miskin, na.rm = TRUE), 2),
    mean_stunting = round(mean(pct_stunting, na.rm = TRUE), 2),
    mean_ikp      = round(mean(ikp, na.rm = TRUE), 2),
    .groups = "drop"
  )

# ── 8b. Data kabupaten lengkap ───────────────────────────────────────────────
data_kabkota <- df |>
  select(provinsi, kabkota, populasi, n_sppg, n_miskin,
         pct_miskin, pct_stunting, ikp, kat_ikp, kat_ikp_f,
         sppg_per100k, sppg_per_miskin, grup_ikp, zero_sppg, is_papua) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# Verifikasi total sebelum ekspor — wajib cocok dengan BGN
stopifnot(
  "Total SPPG berubah sebelum ekspor" = sum(data_kabkota$n_sppg) == 27427
)
cat(sprintf("✓ Total SPPG terverifikasi: %s\n",
            format(sum(data_kabkota$n_sppg), big.mark = ",")))

# ── 8c. Koefisien regresi ────────────────────────────────────────────────────
coef_ols_full   <- tidy(ols_full,   conf.int = TRUE) |>
  mutate(model = "OLS Full",        across(where(is.numeric), ~ round(.x, 4)))
coef_tobit_full <- tidy(tobit_full, conf.int = TRUE) |>
  mutate(model = "Tobit Full",      across(where(is.numeric), ~ round(.x, 4)))
coef_ols_nop    <- tidy(ols_nop,    conf.int = TRUE) |>
  mutate(model = "OLS Tanpa Papua", across(where(is.numeric), ~ round(.x, 4)))
coef_tobit_nop  <- tidy(tobit_nop,  conf.int = TRUE) |>
  mutate(model = "Tobit Tanpa Papua", across(where(is.numeric), ~ round(.x, 4)))

coef_all <- bind_rows(coef_ols_full, coef_tobit_full,
                      coef_ols_nop, coef_tobit_nop)

# ── 8d. Ekspor JSON ──────────────────────────────────────────────────────────
write_json(summary_ikp,   "docs/data/summary_ikp.json",      pretty = TRUE)
write_json(data_kabkota,  "docs/data/kabkota.json",           pretty = TRUE)
write_json(ci_results,    "docs/data/ci_results.json",        pretty = TRUE)
write_json(coef_all,      "docs/data/regression_coef.json",   pretty = TRUE)
write_json(df_coef_all,   "docs/data/quantile_coef.json",     pretty = TRUE)

# ── 8e. [BARU] Ekspor CSV untuk fitur unduh di dashboard ────────────────────
# Dashboard menyediakan tombol "Unduh CSV" — file ini sumbernya.
readr::write_csv(data_kabkota, "docs/data/kabkota.csv")

# ── 8f. [BARU] Ekspor JS embed untuk dashboard statis (GitHub Pages) ────────
# Masalah sebelumnya: dashboard fetch JSON via XHR yang tidak berjalan di
# GitHub Pages tanpa konfigurasi CORS. Solusi: embed data langsung sebagai
# JS const sehingga tidak ada fetch saat runtime.

# RAW array untuk dashboard SPPG (format: [prov, kab, pop, sppg, miskin_n, miskin_pct, stunting, sekolah])
raw_rows <- data_kabkota |>
  arrange(provinsi, kabkota) |>
  mutate(
    sekolah_int = as.integer(round(
      df$total_sekolah[match(paste(provinsi, kabkota),
                             paste(df$provinsi, df$kabkota))]
    )),
    js_row = sprintf(
      '["%s","%s",%d,%d,%d,%.2f,%.2f,%d]',
      provinsi, kabkota,
      as.integer(populasi), as.integer(n_sppg),
      as.integer(n_miskin), pct_miskin, pct_stunting,
      sekolah_int
    )
  )

raw_js_content <- paste0(
  "// Data terverifikasi BGN · ", format(Sys.Date(), "%d %B %Y"),
  " · Total SPPG: ", format(sum(data_kabkota$n_sppg), big.mark = ","),
  " · 514 kab/kota\n",
  "const RAW = [\n",
  paste(raw_rows$js_row, collapse = ",\n"),
  "\n];\n",
  "const TOTAL_BGN = ", sum(data_kabkota$n_sppg), ";\n"
)

writeLines(raw_js_content, "docs/data/sppg_raw_array.js")

# allData array untuk dashboard rawan pangan
# (format: {provinsi, kabkota, ikp, kat_ikp, sppg_per100k, pct_miskin, pct_stunting, n_sppg, is_papua})
alldata_rows <- data_kabkota |>
  arrange(ikp) |>
  mutate(
    sppg_100k_r = round(sppg_per100k, 2),
    js_row = sprintf(
      '{provinsi:"%s",kabkota:"%s",ikp:%.1f,kat_ikp:%d,sppg_per100k:%.2f,pct_miskin:%.2f,pct_stunting:%.2f,n_sppg:%d,is_papua:%s}',
      provinsi, kabkota, ikp, as.integer(kat_ikp),
      sppg_100k_r, pct_miskin, pct_stunting,
      as.integer(n_sppg),
      tolower(as.character(is_papua))
    )
  )

alldata_js_content <- paste0(
  "// Data terverifikasi BGN · ", format(Sys.Date(), "%d %B %Y"),
  " · Total SPPG: ", format(sum(data_kabkota$n_sppg), big.mark = ","),
  " · 514 kab/kota\n",
  "allData = [\n  ",
  paste(alldata_rows$js_row, collapse = ",\n  "),
  "\n];\n"
)

writeLines(alldata_js_content, "docs/data/alldata_kabkota.js")

cat("Data dashboard berhasil diekspor ke docs/data/\n")
cat("  summary_ikp.json\n")
cat("  kabkota.json\n")
cat("  ci_results.json\n")
cat("  regression_coef.json\n")
cat("  quantile_coef.json\n")
cat("  kabkota.csv           [BARU] unduh dashboard\n")
cat("  sppg_raw_array.js     [BARU] embed dashboard SPPG\n")
cat("  alldata_kabkota.js    [BARU] embed dashboard rawan pangan\n")


# =============================================================================
# STEP 9: AUDIT TRAIL — RINGKASAN ANGKA KUNCI
# =============================================================================

cat("\n===== STEP 9: AUDIT TRAIL =====\n")
cat("Angka-angka ini harus cocok dengan yang tertera di dashboard dan README.\n\n")

cat("── Data ────────────────────────────────────────────\n")
cat(sprintf("  Total SPPG nasional : %s\n", format(sum(df$n_sppg), big.mark = ",")))
cat(sprintf("  n kabupaten/kota    : %d\n", nrow(df)))
cat(sprintf("  Kab tanpa SPPG      : %d\n", sum(df$n_sppg == 0)))
cat(sprintf("  Sampel tanpa Papua  : %d\n", nrow(df_nopapua)))

cat("\n── Deskriptif per IKP ──────────────────────────────\n")
print(tabel_deskriptif[, c("kat_ikp_f", "n", "mean_sppg", "median_sppg")])

cat("\n── Concentration Index ─────────────────────────────\n")
print(ci_results)

cat("\n── OLS Full Sample ─────────────────────────────────\n")
coef_tbl <- tidy(ols_full) |>
  filter(term != "(Intercept)") |>
  mutate(
    sig = case_when(p.value < 0.01 ~ "***",
                    p.value < 0.05 ~ "**",
                    p.value < 0.10 ~ "*",
                    TRUE           ~ ""),
    arah = if_else(estimate > 0, "+", "-")
  ) |>
  select(term, estimate, p.value, sig, arah)
print(coef_tbl)
cat(sprintf("  R² = %.3f\n", summary(ols_full)$r.squared))

cat("\n── QR Koefisien IKP (Full Sample) ──────────────────\n")
df_coef_all |>
  filter(term == "ikp", sampel == "Full Sample") |>
  select(tau, estimate, ci_low, ci_high) |>
  mutate(across(where(is.numeric), ~ round(.x, 4))) |>
  print()

cat("\n── QR Koefisien Stunting (Full Sample) ─────────────\n")
df_coef_all |>
  filter(term == "pct_stunting", sampel == "Full Sample") |>
  select(tau, estimate, ci_low, ci_high) |>
  mutate(across(where(is.numeric), ~ round(.x, 4))) |>
  print()

# Verifikasi file output
cat("\n── File output ─────────────────────────────────────\n")
files_expected <- c(
  "output/fig1_boxplot_ikp.png",
  "output/fig2_scatter_ikp.png",
  "output/fig3_scatter_kemiskinan.png",
  "output/fig4_robustness_boxplot.png",
  "output/fig5_quantile_coef.png",
  "output/fig6_scatter_stunting.png",
  "docs/data/summary_ikp.json",
  "docs/data/kabkota.json",
  "docs/data/ci_results.json",
  "docs/data/regression_coef.json",
  "docs/data/quantile_coef.json",
  "docs/data/kabkota.csv",
  "docs/data/sppg_raw_array.js",
  "docs/data/alldata_kabkota.js"
)
for (f in files_expected) {
  status <- if (file.exists(f)) "✓" else "✗ TIDAK ADA"
  cat(sprintf("  %s %s\n", status, f))
}


# =============================================================================
# SELESAI
# =============================================================================

cat("\n============================================================\n")
cat("Analisis v2.0 selesai.\n")
cat(sprintf("Selesai: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("============================================================\n")
