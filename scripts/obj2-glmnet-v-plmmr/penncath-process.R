# TKP - July 2025
# Objective - create testing and training data sets from PennCath data
# This script assumes that the model fitting from objective 1 has already been done.

# create data matrix of all observations, *in-memory* (glmnet requires in-memory)
# In particular, I will create a data matrix that combines unpenalized features (sex, age)
#   with PLINK data *without* doing standardization
plink_data <- file.path("results", "n1401_p700K", "processed_n1401_p700K.rds")
pheno <- read.csv(file.path("data", "penncath.csv"))
pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)

design_wo_std_path <- create_design_wo_std(data_file = plink_data,
                                           feature_id = "FID",
                                           rds_dir = file.path("results", "n1401_p700K"),
                                           new_file = "penncath_wo_std",
                                           add_outcome = pheno,
                                           outcome_id = "FamID",
                                           outcome_col = "CAD",
                                           add_predictor = predictors,
                                           predictor_id = "FID",
                                           overwrite = TRUE)

# create folder to hold results
dir.create(file.path("results", "obj4"))
