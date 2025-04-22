# -------------------------------------------------------------------------
# Project:       Exploratory meta-analysis for cefiderocol combination therapy
# Script:        Data analysis for publication
# Authors:       Matteo Morra, Alessandra Nazeri
# Date created:  2025-04-22
# -------------------------------------------------------------------------

if (!require("pacman")) install.packages("pacman")
pacman::p_load(remotes)
if (!"dmetar" %in% installed.packages()[, "Package"]) {
  remotes::install_github("MathiasHarrer/dmetar")
}
pacman::p_load(tidyverse, meta, readxl, dmetar)


# -------------------------------------------------------------------------
# INITIALIZE & CLEAN DATA -------------------------------------------------
# -------------------------------------------------------------------------

# Outcome Note
# The Excel column labeled as "positive outcome" actually refers to 30-day survival.
# Since our analysis focuses on mortality, we would need to swap the event
# columns if we wanted to show mortality instead.
# We merge RoB/NOS domains into a single column.
# A final quality score is computed by summing the domain scores.
# We then represent this score as a star rating using Unicode stars (★), generated via sapply()

meta_df <- readxl::read_excel("Meta-analysis Cefiderocol_github.xlsx") %>%
  mutate(
    Temporary_column_one = `Fav outcome combo`,
    Temporary_column_two = `Fav outcome mono`,
    `Fav outcome combo` = if_else(outcome == "mortality", `Neg outcome combo`, `Fav outcome combo`),
    `Neg outcome combo` = if_else(outcome == "mortality", Temporary_column_one, `Neg outcome combo`),
    `Fav outcome mono` = if_else(outcome == "mortality", `Neg outcome mono`, `Fav outcome mono`),
    `Neg outcome mono` = if_else(outcome == "mortality", Temporary_column_two, `Neg outcome mono`)
  ) %>%
  dplyr::select(-starts_with("Temporary_column")) %>%
  rowwise() %>%
  mutate(RoB = sum(D1, D2, D3, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    RoB2 = 9 - RoB, # to generate the right amount of empty stars
    RoB = sapply(RoB, function(x) {
      paste(rep("\U0002605", x), collapse = " ")
    }),
    RoB3 = sapply(RoB2, function(x) {
      paste(rep("\U0002606", x), collapse = " ")
    }),
    RoB = if_else(RoB == "", RoB3, paste(RoB, RoB3)),
    RoB = if_else(!is.na(`ROBINS-2`), `ROBINS-2`, RoB) # for clinical trilas we use the RoB2 tool
  ) %>%
  dplyr::select(-c(RoB2, RoB3))

# -------------------------------------------------------------------------
# Unadjusted analysis -----------------------------------------------------
# -------------------------------------------------------------------------

# We first calculate the effect sizes and the standard errors based on observed
# number of events.
# The dataframe is modified inline within the metabin() call to add the total
# number of events for both the experimental and control groups.

meta_bin <- meta::metabin(
  event.e = `Fav outcome combo`,
  n.e = Total_e,
  event.c = `Fav outcome mono`,
  n.c = Total_u,
  data = meta_df %>%
    rowwise() %>%
    mutate(
      Total_e = sum(`Fav outcome combo`, `Neg outcome combo`, na.rm = TRUE),
      Total_u = sum(`Fav outcome mono`, `Neg outcome mono`, na.rm = TRUE)
    ),
  sm = "OR",
  method = "MH",
  MH.exact = TRUE,
  method.tau = "REML",
  method.random.ci = "HK"
)

# -------------------------------------------------------------------------
# Adjusted analysis -------------------------------------------------------
# -------------------------------------------------------------------------

# We use the metagen function to calculate the SE of the logOR to use for
# studies that perform adjusted analysis

meta_gen <- meta::metagen(
  TE = log(`adjusted OR`),
  lower = log(`aOR lower`),
  upper = log(`aOR upper`),
  data = meta_df,
  sm = "OR",
  method.tau = "REML",
  method.random.ci = "HK"
)

# -------------------------------------------------------------------------
# Final dataset -----------------------------------------------------------
# -------------------------------------------------------------------------

# We create a final databsed with treatment effetcs and their stadrd errors 
# based on the type of analysis conducted

meta_df_final <- meta_df %>%
  mutate(
    OR = meta_bin$TE,
    OR2 = meta_gen$TE,
    SE = meta_bin$seTE,
    SE2 = meta_gen$seTE,
    OR = if_else(!is.na(OR2), OR2, OR),
    SE = if_else(!is.na(SE2), SE2, SE)
  )

# -------------------------------------------------------------------------
# Plot generation ---------------------------------------------------------
# -------------------------------------------------------------------------

# We create an empty list to store meta-analysis results for each outcome
meta_result_list <- list()

unique_endpoints <- meta_df_final %>%
  distinct(outcome) %>%
  pull()
# Loop through each unique outcome to perform meta-analysis and generate plots
for (i in unique_endpoints) {
  meta_result_list[[i]] <- meta::metagen(
    TE = OR,
    seTE = SE,
    data = meta_df_final %>% filter(outcome == i), # filter data by outcome
    sm = "OR",
    common = FALSE, # do not compute fixed-effect model
    random = TRUE, # compute random-effects model
    method.tau = "REML", # restricted maximum likelihood for tau²
    method.random.ci = "HK", # Hartung-Knapp adjustment for CI
    studlab = `First author, year`
  )
  png(file = paste0("Plots/forestplot_", i, ".png"), width = 3500, height = 1500, res = 300)
  # Customize plot direction labels based on outcome type
  label_left <- if (i != "mortality") {
    "←\nFavours monotherapy"
  } else {
    "←\nFavours combination"
  }

  label_right <- if (i != "mortality") {
    "→\nFavours combination"
  } else {
    "→\nFavours monotherapy"
  }

  meta::forest(
    meta_result_list[[i]],
    sortvar = OR,
    prediction = TRUE,
    print.tau2 = FALSE,
    common = FALSE,
    leftcols = c("studlab", "No. of patients (total)", "RoB"),
    leftlabs = c("Author, year", "N° patients", "RoB"),
    label.left = label_left,
    label.right = label_right
  )
  dev.off()
  # Perform influence analysis
  influence_analysis <- dmetar::InfluenceAnalysis(meta_result_list[[i]], random = TRUE)
  # Baujat plot (influence vs. heterogeneity contribution)
  png(
    file = paste0("Plots/baujat_", i, ".png"),
    width = 1200,
    height = 1200,
    res = 300
  )
  plot(influence_analysis, "baujat")
  dev.off()
  # Leave-one-out analysis sorted by I² contribution
  png(
    file = paste0("Plots/Leave_one_out_", i, ".png"),
    width = 2400,
    height = 2400,
    res = 300
  )
  plot(influence_analysis, "i2")
  dev.off()
  # Contour-enhanced funnel plot for publication bias assessment
  # Since in none of the meta analysis there are at least 10 studies
  # we do not perform Egger test 
  png(
    file = paste0("Plots/Publication_bias_", i, ".png"),
    width = 2400,
    height = 2400,
    res = 300
  )
  # Define fill colors for contour
  col_contour <- c("gray75", "gray85", "gray95")
  meta::funnel(meta_result_list[[i]],
    contour = c(0.9, 0.95, 0.99),
    col.contour = col.contour,
    studlab = FALSE
  )
  # Add legend explaining contour regions
  legend(
    x = 2.5, y = 0.01, # legend position
    legend = c("p < 0.1", "p < 0.05", "p < 0.01"),
    fill = col_contour
  )
  # Add a title
  title(paste("Contour-Enhanced Funnel Plot for", i))
  dev.off()
}
