# fit a PLMM model with n = 350 and p = 400,000
# library(plmmr)
# library(dplyr)

# process the data
process_time <- system.time(
  plink_data <- process_plink(data_dir = "data/p400K/",
                              data_prefix = "n350_p400K",
                              rds_dir = "results/n350_p400K/",
                              rds_prefix = "processed_n350_p400K",
                              impute_method = "mode",
                              overwrite = TRUE,
                              # turning off parallelization
                              parallel = FALSE)
)


# create a design
pheno <- read.csv("data/penncath.csv")
pheno <- pheno |> mutate(FamID = as.character(FamID))
predictors <- pheno |> transmute(FID = as.character(FamID), sex = sex, age = age)

design_time <- system.time(
  design <- create_design(data_file = plink_data,
                          feature_id = "FID",
                          rds_dir = "results/n350_p400K/",
                          new_file = "std_penncath_lite",
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
  plmm(design = design,
       save_rds = "results/n350_p400K/fit",
       trace = T)
)

# save timestamps
track_time <- readRDS("results/track_time.rds")
track_time[track_time$n == 350 & track_time$p == "400K", "process"] <- process_time['elapsed']
track_time[track_time$n == 350 & track_time$p == "400K", "create_design"] <- design_time['elapsed']
track_time[track_time$n == 350 & track_time$p == "400K", "fit"] <- fit_time['elapsed']
saveRDS(track_time, 'results/track_time.rds')
