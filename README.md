# ANALISIS DISTRIBUSI SPPG PROGRAM MBG terhadap Indeks Ketahanan & Kerentanan Pangan (IKP/FSVA)
# 0. PACKAGES 
pkgs <- c("readxl", "tidyverse", "dunn.test", "AER",
          "quantreg", "stargazer", "broom", "scales",
          "ggplot2", "patchwork")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
invisible(lapply(pkgs, install_if_missing))
invisible(lapply(pkgs, library, character.only = TRUE))

cat("Semua package berhasil dimuat.\n")

# STEP 1: LOAD DATA DAN PERSIAPAN

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

    # Identifikasi Papua
    is_papua = provinsi %in% c("Papua", "Papua Barat", "Papua Barat Daya",
                                "Papua Pegunungan", "Papua Selatan",
                                "Papua Tengah")
  )

# Dataset tanpa Papua
df_nopapua <- df |> filter(!is_papua)

cat(sprintf("Full sample  : %d kabupaten/kota\n", nrow(df)))
cat(sprintf("Tanpa Papua  : %d kabupaten/kota\n", nrow(df_nopapua)))
cat(sprintf("Kabupaten 0 SPPG: %d\n", sum(df$n_sppg == 0)))

glimpse(df)
summary(df[, c("sppg_per100k", "ikp", "pct_miskin", "pct_stunting")])


# STEP 2: STATISTIK DESKRIPTIF

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

# STEP 3: UJI PERBEDAAN ANTAR KELOMPOK

cat("\n===== STEP 3: UJI KRUSKAL-WALLIS & DUNN =====\n")

# 3a. Kruskal-Wallis
kw_full <- kruskal.test(sppg_per100k ~ kat_ikp_f, data = df)
kw_nop  <- kruskal.test(sppg_per100k ~ kat_ikp_f, data = df_nopapua)

cat("Kruskal-Wallis (Full Sample):\n"); print(kw_full)
cat("\nKruskal-Wallis (Tanpa Papua):\n"); print(kw_nop)

# 3b. Post-hoc Dunn (Full)
cat("\nDunn Test (Full Sample, Bonferroni):\n")
dunn.test(df$sppg_per100k, df$kat_ikp_f,
          method = "bonferroni", kw = TRUE, label = TRUE)

cat("\nDunn Test (Tanpa Papua, Bonferroni):\n")
dunn.test(df_nopapua$sppg_per100k, df_nopapua$kat_ikp_f,
          method = "bonferroni", kw = TRUE, label = TRUE)

# 3c. Mann-Whitney: Rawan vs Tahan
mw_full <- wilcox.test(sppg_per100k ~ grup_ikp, data = df)
mw_nop  <- wilcox.test(sppg_per100k ~ grup_ikp, data = df_nopapua)

cat("\nMann-Whitney Rawan vs Tahan (Full):\n"); print(mw_full)
cat("\nMann-Whitney Rawan vs Tahan (Tanpa Papua):\n"); print(mw_nop)


# STEP 4: CONCENTRATION INDEX

cat("\n===== STEP 4: CONCENTRATION INDEX =====\n")

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
cat("\nInterpretasi: CI < 0 = pro-rawan/pro-poor | CI > 0 = pro-tahan/pro-rich\n")


# STEP 5: REGRESI OLS DAN TOBIT

cat("\n===== STEP 5: REGRESI OLS & TOBIT =====\n")

formula_reg <- sppg_per100k ~ pct_miskin + pct_stunting + ikp + log(populasi)

# OLS
ols_full <- lm(formula_reg, data = df)
ols_nop  <- lm(formula_reg, data = df_nopapua)

# Tobit (left-censored pada 0)
tobit_full <- tobit(formula_reg, left = 0, right = Inf, data = df)
tobit_nop  <- tobit(formula_reg, left = 0, right = Inf, data = df_nopapua)

cat("\nRingkasan OLS Full:\n"); summary(ols_full)
cat("\nRingkasan OLS Tanpa Papua:\n"); summary(ols_nop)
cat("\nRingkasan Tobit Full:\n"); summary(tobit_full)
cat("\nRingkasan Tobit Tanpa Papua:\n"); summary(tobit_nop)

# Tabel perbandingan
stargazer(ols_full, ols_nop, tobit_full, tobit_nop,
          type           = "text",
          title          = "Robustness Check: Full Sample vs Tanpa Papua",
          column.labels  = c("OLS Full", "OLS -Papua",
                             "Tobit Full", "Tobit -Papua"),
          dep.var.labels = "SPPG per 100.000 Penduduk",
          covariate.labels = c("Kemiskinan (%)", "Stunting (%)",
                               "IKP", "log(Populasi)"),
          digits         = 3,
          star.cutoffs   = c(0.1, 0.05, 0.01))


# STEP 6: QUANTILE REGRESSION

cat("\n===== STEP 6: QUANTILE REGRESSION =====\n")

tau_seq <- c(0.10, 0.25, 0.50, 0.75, 0.90)

# Full sample
qr_full_list <- lapply(tau_seq, function(t)
  rq(formula_reg, tau = t, data = df))

# Tanpa Papua
qr_nop_list <- lapply(tau_seq, function(t)
  rq(formula_reg, tau = t, data = df_nopapua))

# Ringkasan dengan SE bootstrap
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
          type           = "text",
          title          = "Quantile Regression (Full Sample)",
          column.labels  = c("Q10","Q25","Q50","Q75","Q90","OLS"),
          dep.var.labels = "SPPG per 100.000 Penduduk",
          covariate.labels = c("Kemiskinan (%)","Stunting (%)","IKP","log(Populasi)"),
          digits         = 3,
          star.cutoffs   = c(0.1, 0.05, 0.01))

# Ekstrak koefisien untuk visualisasi
extract_coef <- function(model, tau, sampel) {
  s       <- summary(model, se = "boot", R = 500)
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


# STEP 7: VISUALISASI

cat("\n===== STEP 7: VISUALISASI =====\n")

# Buat folder output jika belum ada
dir.create("output", showWarnings = FALSE)

# 7a. Boxplot SPPG per kategori IKP
p1 <- ggplot(df, aes(x = kat_ikp_f, y = sppg_per100k, fill = kat_ikp_f)) +
  geom_boxplot(outlier.shape = 21, alpha = 0.75) +
  scale_fill_brewer(palette = "RdYlGn") +
  labs(
    title    = "Distribusi SPPG per 100.000 Penduduk\nmenurut Kategori IKP (FSVA)",
    subtitle = "Jika tepat sasaran: kotak kiri (Rentan) seharusnya lebih tinggi",
    x        = "Kategori Indeks Ketahanan & Kerentanan Pangan",
    y        = "SPPG per 100.000 Penduduk",
    caption  = "Sumber: BGN (2026), Bapanas FSVA (2024)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 20, hjust = 1))

ggsave("output/fig1_boxplot_ikp.png", p1, width = 10, height = 6, dpi = 150)

# 7b. Scatter: IKP vs SPPG per 100k
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
    caption  = "Sumber: BGN (2026), Bapanas FSVA (2024)"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/fig2_scatter_ikp.png", p2, width = 10, height = 6, dpi = 150)

# 7c. Scatter: Kemiskinan vs SPPG per 100k
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
    caption  = "Sumber: BGN (2026), BPS (2024)"
  ) +
  theme_minimal(base_size = 12)

ggsave("output/fig3_scatter_kemiskinan.png", p3, width = 10, height = 6, dpi = 150)

# 7d. Robustness check boxplot (full vs tanpa Papua)
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
    caption = "Sumber: BGN (2026), Bapanas FSVA (2024)"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("output/fig4_robustness_boxplot.png", p4, width = 12, height = 6, dpi = 150)

# 7e. Quantile regression plot (IKP & Stunting)
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
    subtitle = "Area = 95% CI bootstrap | Garis putus = tidak ada efek (0)",
    x        = "Kuantil",
    y        = "Koefisien",
    color    = NULL, fill = NULL,
    caption  = "Sumber: BGN (2026), Bapanas FSVA (2024), BPS (2024)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave("output/fig5_quantile_coef.png", p5, width = 12, height = 6, dpi = 150)

cat("\nSemua visualisasi tersimpan di folder output/\n")


# STEP 8: EKSPOR DATA UNTUK DASHBOARD

cat("\n===== STEP 8: EKSPOR DATA DASHBOARD =====\n")

# Data ringkasan per kategori IKP
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

# Data kabupaten lengkap
data_kabkota <- df |>
  select(provinsi, kabkota, populasi, n_sppg, n_miskin,
         pct_miskin, pct_stunting, ikp, kat_ikp, kat_ikp_f,
         sppg_per100k, sppg_per_miskin, grup_ikp, zero_sppg, is_papua) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# CI results
ci_export <- ci_results

# Koefisien regresi
coef_ols_full <- tidy(ols_full, conf.int = TRUE) |>
  mutate(model = "OLS Full", across(where(is.numeric), ~ round(.x, 4)))

coef_tobit_full <- tidy(tobit_full, conf.int = TRUE) |>
  mutate(model = "Tobit Full", across(where(is.numeric), ~ round(.x, 4)))

coef_ols_nop <- tidy(ols_nop, conf.int = TRUE) |>
  mutate(model = "OLS Tanpa Papua", across(where(is.numeric), ~ round(.x, 4)))

coef_tobit_nop <- tidy(tobit_nop, conf.int = TRUE) |>
  mutate(model = "Tobit Tanpa Papua", across(where(is.numeric), ~ round(.x, 4)))

coef_all <- bind_rows(coef_ols_full, coef_tobit_full,
                      coef_ols_nop, coef_tobit_nop)

# Ekspor ke JSON untuk dashboard
library(jsonlite)

write_json(summary_ikp,   "docs/data/summary_ikp.json",   pretty = TRUE)
write_json(data_kabkota,  "docs/data/kabkota.json",        pretty = TRUE)
write_json(ci_export,     "docs/data/ci_results.json",     pretty = TRUE)
write_json(coef_all,      "docs/data/regression_coef.json",pretty = TRUE)
write_json(df_coef_all,   "docs/data/quantile_coef.json",  pretty = TRUE)

cat("Data dashboard berhasil diekspor ke docs/data/\n")


# SELESAI

cat("\n============================================================\n")
cat("Analisis selesai. Output:\n")
cat("  - Tabel: dicetak di console\n")
cat("  - Gambar: output/fig1_boxplot_ikp.png\n")
cat("            output/fig2_scatter_ikp.png\n")
cat("            output/fig3_scatter_kemiskinan.png\n")
cat("            output/fig4_robustness_boxplot.png\n")
cat("            output/fig5_quantile_coef.png\n")
cat("  - Data dashboard: docs/data/*.json\n")
cat("============================================================\n")
