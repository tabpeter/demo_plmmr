#' Analyze penncath data with plmmr
library(plmmr)

# process the data
process_time <- system.time(
  plink_data <- plmmr::process_plink(
    data_dir = "data/",
    data_prefix = "qc_penncath",
    rds_dir = "results/n1401_p700K/",
    rds_prefix = "processed_n1401_p700K",
    impute_method = "mode",
    overwrite = TRUE,
    # turning off parallelization
    parallel = FALSE
  )
)

# create a design
pheno <- read.csv("data/penncath.csv")
pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)
design_time <- system.time(
  design <- plmmr::create_design(
    data_file = plink_data,
    feature_id = "FID",
    rds_dir = "results/n1401_p700K/",
    new_file = "std_penncath",
    add_outcome = pheno,
    outcome_id = "FamID",
    outcome_col = "CAD",
    add_predictor = predictors,
    predictor_id = "FID",
    logfile = "design",
    overwrite = TRUE
  )
)

# fit a model
fit_time <- system.time(
  plmmr::plmm(
    design = design,
    save_rds = "results/n1401_p700K/fit",
    trace = T
  )
)
