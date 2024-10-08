# fit a PLMM model with the *entire* penncath dataset (n = 1401, p = ~800K)
# Note: this requires its own script

# process the data
process_time <- system.time(
  plink_data <- plmmr::process_plink(data_dir = "data/",
                              data_prefix = "qc_penncath",
                              rds_dir = "results/n1401_p800K/",
                              rds_prefix = "processed_n1401_p800K",
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
                          rds_dir = "results/n1401_p800K/",
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
       save_rds = "results/n1401_p800K/fit",
       trace = T)
)

# save timestamps
track_time <- readRDS("results/track_time.rds")
track_time[track_time$n == 1401 & track_time$p == "800K", "process"] <- process_time['elapsed']
track_time[track_time$n == 1401 & track_time$p == "800K", "create_design"] <- design_time['elapsed']
track_time[track_time$n == 1401 & track_time$p == "800K", "fit"] <- fit_time['elapsed']
saveRDS(track_time, 'results/track_time.rds')
