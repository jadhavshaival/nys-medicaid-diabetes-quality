suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

data_dir <- "path/to/your/data"

needed <- file.path(data_dir, c("rates.csv", "payer_gap.csv", "region_gap.csv"))
if (!all(file.exists(needed))) {
  stop("Cannot find these files:\n  ",
       paste(needed[!file.exists(needed)], collapse = "\n  "),
       "\nCheck data_dir at the top of the script.")
}

fig_dir <- file.path(data_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE)

rates      <- read_csv(file.path(data_dir, "rates.csv"),      show_col_types = FALSE)
payer_gap  <- read_csv(file.path(data_dir, "payer_gap.csv"),  show_col_types = FALSE)
region_gap <- read_csv(file.path(data_dir, "region_gap.csv"), show_col_types = FALSE)

check <- function(label, ok) {
  cat(sprintf("[%s] %s\n", if (isTRUE(ok)) "PASS" else "FAIL", label))
}

# ---------------------------------------------------------------
# Check 1: row accounting (numbers recorded in the working log)

cat("\n== Check 1: row accounting ==\n")
print(rates %>% count(use_note, ci_ok))
check("1,091 rows in total", nrow(rates) == 1091)
check("999 rows have a confidence interval", sum(rates$ci_ok == 1, na.rm = TRUE) == 999)
check("excluded rows: 24 implausible rate, 18 one-year category, 12 unknown region",
      sum(rates$use_note == "Excluded: implausible rate") == 24 &&
        sum(rates$use_note == "Excluded: one-year category") == 18 &&
        sum(rates$use_note == "Excluded: unknown region") == 12)
print(rates %>% count(file_year))

# ---------------------------------------------------------------
# Check 2: Wilson intervals recomputed from scratch

cat("\n== Check 2: Wilson 95% intervals ==\n")
wilson <- function(p, n, z = 1.96) {
  dn     <- 1 + z^2 / n
  center <- (p + z^2 / (2 * n)) / dn
  half   <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / dn
  list(lcl = 100 * (center - half), ucl = 100 * (center + half))
}
ci <- rates %>% filter(ci_ok == 1)
w  <- wilson(ci$Rate / 100, ci$Denominator)
check("lower bounds match SAS (tolerance 0.001)", max(abs(w$lcl - ci$lcl)) < 1e-3)
check("upper bounds match SAS (tolerance 0.001)", max(abs(w$ucl - ci$ucl)) < 1e-3)

# ---------------------------------------------------------------
# Check 3: one number checked by hand (Medicaid BP control, statewide, 2023)

cat("\n== Check 3: one hand-checked number ==\n")
x <- rates %>%
  filter(Payer == "Medicaid Managed Care", Category == "Statewide",
         measure_std == "BP Control <140/90", file_year == 2023)
cat(sprintf("Published %.0f%%; counts %d / %d = %.1f%%\n",
            x$Rate, x$Numerator, x$Denominator, 100 * x$Numerator / x$Denominator))
check("numerator 7,276 and denominator 10,577, published rate 69",
      x$Numerator == 7276 && x$Denominator == 10577 && x$Rate == 69)

# ---------------------------------------------------------------
# Check 4: Medicaid minus commercial gaps recomputed

cat("\n== Check 4: payer gaps ==\n")
sw <- rates %>%
  filter(Category == "Statewide", use_in_analysis == 1) %>%
  select(measure_std, Payer, file_year, Rate, Denominator, ci_ok)

mc <- sw %>% filter(Payer == "Medicaid Managed Care") %>%
  transmute(measure_std, file_year, m_rate = Rate, m_den = Denominator, m_ok = ci_ok)
cm <- sw %>% filter(grepl("^Commercial", Payer)) %>%
  transmute(measure_std, file_year, comparison = Payer,
            c_rate = Rate, c_den = Denominator, c_ok = ci_ok)

gap_r <- inner_join(mc, cm, by = c("measure_std", "file_year")) %>%
  mutate(gap_r = m_rate - c_rate,
         se    = 100 * sqrt(m_rate / 100 * (1 - m_rate / 100) / m_den +
                              c_rate / 100 * (1 - c_rate / 100) / c_den),
         lcl_r = if_else(m_ok == 1 & c_ok == 1, gap_r - 1.96 * se, NA_real_),
         ucl_r = if_else(m_ok == 1 & c_ok == 1, gap_r + 1.96 * se, NA_real_))

cmp <- inner_join(gap_r, payer_gap, by = c("measure_std", "comparison", "file_year"))
check("same number of Medicaid-vs-commercial pairs as SAS", nrow(gap_r) == nrow(payer_gap))
check("gaps match SAS", max(abs(cmp$gap_r - cmp$gap)) < 1e-6)
check("interval availability matches SAS", all(is.na(cmp$lcl_r) == is.na(cmp$gap_lcl)))
check("interval bounds match SAS (tolerance 0.001)",
      max(abs(cmp$lcl_r - cmp$gap_lcl), abs(cmp$ucl_r - cmp$gap_ucl), na.rm = TRUE) < 1e-3)

# ---------------------------------------------------------------
# Check 5: regional tests recomputed (region vs rest of state)

cat("\n== Check 5: regional gaps ==\n")
rg <- region_gap %>%
  mutate(rest_num = st_num - reg_num,
         rest_den = st_den - reg_den,
         p1 = reg_num / reg_den,
         p2 = rest_num / rest_den,
         pp = (reg_num + rest_num) / (reg_den + rest_den),
         z  = (p1 - p2) / sqrt(pp * (1 - pp) * (1 / reg_den + 1 / rest_den)),
         pval_r    = if_else(test_ok == 1, pchisq(z^2, 1, lower.tail = FALSE), NA_real_),
         gap_cnt_r = if_else(test_ok == 1, 100 * (p1 - p2), NA_real_),
         meaningful_r = test_ok == 1 & !is.na(pval_r) & pval_r < 0.05 &
           sign(gap_cnt_r) == sign(gap_pub) & abs(gap_pub) >= 3)

check("p-values match SAS (tolerance 1e-6)", max(abs(rg$pval_r - rg$pval), na.rm = TRUE) < 1e-6)
check("counts-based gaps match SAS (tolerance 0.001)",
      max(abs(rg$gap_cnt_r - rg$gap_cnt), na.rm = TRUE) < 1e-3)
check("same set of meaningful gaps as SAS", all(rg$meaningful_r == (rg$meaningful == 1)))
cat(sprintf("Meaningful regional gaps: %d (SAS output you reviewed listed 35)\n",
            sum(rg$meaningful_r)))
check("35 meaningful regional gaps", sum(rg$meaningful_r) == 35)

r1 <- rg %>% filter(test_ok == 1) %>% slice(1)
pt <- prop.test(c(r1$reg_num, r1$rest_num), c(r1$reg_den, r1$rest_den), correct = FALSE)$p.value
check("R's prop.test agrees with the hand-written test on one row", abs(pt - r1$pval_r) < 1e-8)

# ---------------------------------------------------------------
# Charts

pal <- c("Medicaid Managed Care" = "#1b6ca8",
         "Commercial HMO"        = "#d17b0f",
         "Commercial PPO"        = "#6b6b6b")

# Chart 1: statewide trend by payer (gaps are real missing data, not interpolated)
trend <- rates %>%
  filter(Category == "Statewide", use_in_analysis == 1) %>%
  select(measure_std, Payer, file_year, Rate, lcl, ucl) %>%
  complete(measure_std, Payer, file_year = 2018:2024)

p1 <- ggplot(trend, aes(file_year, Rate, colour = Payer, fill = Payer, group = Payer)) +
  geom_ribbon(aes(ymin = lcl, ymax = ucl), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  facet_wrap(~ measure_std, ncol = 2) +
  scale_x_continuous(breaks = 2018:2024) +
  scale_colour_manual(values = pal) +
  scale_fill_manual(values = pal) +
  labs(title = "Diabetes care measures, New York statewide, 2018 to 2024",
       subtitle = "Published rates (%) by plan type; higher is better for all four panels",
       x = NULL, y = "Rate (%)", colour = NULL, fill = NULL,
       caption = paste("Shaded band: approximate 95% interval (not shown where denominators are oversized).",
                       "Breaks in a line: no usable data (Medicaid BP and HbA1c 2019 missing;",
                       "Commercial HMO 2019 BP and HbA1c excluded). Glycemic Status is a new 2024 measure.",
                       sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.caption = element_text(hjust = 0, size = 8))
ggsave(file.path(fig_dir, "fig1_statewide_trends.png"), p1, width = 9, height = 7, dpi = 200)

# Chart 2: Medicaid minus commercial gap with intervals
g <- payer_gap %>% mutate(comparison = paste("Medicaid minus", comparison))
p2 <- ggplot(g, aes(file_year, gap)) +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey40") +
  geom_errorbar(aes(ymin = gap_lcl, ymax = gap_ucl), width = 0.2, na.rm = TRUE,
                colour = "#1b6ca8") +
  geom_point(aes(shape = is.na(gap_lcl)), size = 2.5, colour = "#1b6ca8") +
  facet_grid(measure_std ~ comparison, labeller = labeller(measure_std = label_wrap_gen(18)))
  labs(title = "Medicaid compared with commercial plans, statewide",
       subtitle = "Percentage-point gap with approximate 95% interval; above 0 means Medicaid is higher",
       x = NULL, y = "Gap (percentage points)",
       caption = "Intervals use published rates and reported denominators and are approximate.") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", plot.caption = element_text(hjust = 0, size = 8),
        strip.text.y = element_text(size = 8))
ggsave(file.path(fig_dir, "fig2_medicaid_vs_commercial_gap.png"), p2, width = 9, height = 8, dpi = 200)

# Chart 3: Medicaid regional gaps vs statewide
hm <- region_gap %>%
  group_by(measure_std, region) %>%
  summarise(mean_gap = mean(gap_pub), k = sum(meaningful), n = sum(test_ok), .groups = "drop") %>%
  mutate(label = sprintf("%+.1f\n(%d of %d yrs)", mean_gap, k, n))

p3 <- ggplot(hm, aes(measure_std, region, fill = mean_gap)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = label), size = 3) +
  scale_fill_gradient2(low = "#b2182b", mid = "white", high = "#2166ac",
                       midpoint = 0, name = "Mean gap\n(points)") +
  labs(title = "Medicaid: region compared with statewide",
       subtitle = "Mean published gap; (k of n yrs) = years with a meaningful gap out of years tested",
       x = NULL, y = NULL,
       caption = paste("Meaningful = p < 0.05 on counts (region vs rest of state), same direction as the",
                       "published gap, published gap of at least 3 points. Plan-type rates, not risk-adjusted.",
                       sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(plot.caption = element_text(hjust = 0, size = 8), panel.grid = element_blank())
ggsave(file.path(fig_dir, "fig3_regional_gaps.png"), p3, width = 8, height = 5, dpi = 200)

cat("\nCharts saved to:", fig_dir, "\n")