# Objective: for each combination of n and p, carry out data pre-processing and fit a model

# Analyze all subsets ----------------------------------

d <- expand.grid(n = c(350, 700, 1050, 1401), p = c(400, 600, 700))

# analyese of subsets
for (i in 1:nrow(d)){
  run_analysis(n = d[i,1], p = d[i, 2])
}

# Last step: analysis of full data (n = 1401, p = ~700K) --------------------
# Note: this requires its own code, since it is not a subset

# process the data
process_time <- system.time(
  plink_data <- plmmr::process_plink(data_dir = "data/",
                                     data_prefix = "qc_penncath",
                                     rds_dir = "results/n1401_p700K/",
                                     rds_prefix = "processed_n1401_p700K",
                                     impute_method = "mode",
                                     overwrite = TRUE,
                                     # turning off parallelization
                                     parallel = FALSE)
)


# create a design
pheno <- read.csv("data/penncath.csv")
pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)

design_time <- system.time(
  design <- plmmr::create_design(data_file = plink_data,
                                 feature_id = "FID",
                                 rds_dir = "results/n1401_p700K/",
                                 new_file = "std_penncath",
                                 add_outcome = pheno,
                                 outcome_id = "FamID",
                                 outcome_col = "CAD",
                                 add_predictor = predictors,
                                 predictor_id = "FID",
                                 logfile = "design",
                                 overwrite = TRUE)
)



# fit a model
fit_time <- system.time(
  plmmr::plmm(design = design,
              save_rds = "results/n1401_p700K/fit",
              trace = T)
)

# save timestamps
track_time <- readRDS("results/track_time.rds")
track_time[track_time$n == 1401 & track_time$p == "700K", "process"] <- process_time['elapsed']
track_time[track_time$n == 1401 & track_time$p == "700K", "create_design"] <- design_time['elapsed']
track_time[track_time$n == 1401 & track_time$p == "700K", "fit"] <- fit_time['elapsed']
saveRDS(track_time, 'results/track_time.rds')

