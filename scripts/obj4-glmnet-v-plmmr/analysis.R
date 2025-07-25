# TKP - July 2025
# Objective - create candidate models using plmmr and glmnet, then use
#   CV for model selection.
# Will use the PennCath data again here.
# This script assumes that the model fitting from objective 1 has already been done.


# PLMM ------------

design <- readRDS("results/n1401_p700K/std_penncath.rds")
fit <- readRDS("results/n1401_p700K/fit.rds")
cvres_plmm <- plmmr::cv_plmm(design = "results/n1401_p700K/std_penncath.rds",
                             K = fit$K,
                             trace = TRUE,
                             save_rds = "results/n1401_p700K/cv_fit")
# cvres_plmm <- structure(cvres_plmm, class="cv_plmm")
cvpred_plmm <- readRDS("results/n1401_p700K/cv_fit_yhat.rds")

summary(cvres_plmm)
plmm_beta <- cvres_plmm$fit$beta_vals[,cvres_plmm$min]
# lasso only ------------

# prepare input for glmnet
# since cv.biglasso standardizes internally, we need to create a data matrix
#   that combines unpenalized features (sex, age) with PLINK data *without* doing standardization

plink_data <- "results/n1401_p700K/processed_n1401_p700K.rds"

pheno <- read.csv("data/penncath.csv")
pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)

design_wo_std_path <- create_design_wo_std(data_file = plink_data,
                               feature_id = "FID",
                               rds_dir = "results/n1401_p700K/",
                               new_file = "penncath_wo_std",
                               add_outcome = pheno,
                               outcome_id = "FamID",
                               outcome_col = "CAD",
                               add_predictor = predictors,
                               predictor_id = "FID",
                               overwrite = TRUE)

design_wo_std <- readRDS(design_wo_std_path)

X <- design_wo_std$subset_X |> bigmemory::attach.big.matrix()
ram_X <- X[,]
glmnet_fit <- glmnet::cv.glmnet(x = ram_X,
                                y = design_wo_std$y,
                                nfolds = 5,
                                parallel = T,
                                penalty.factor = design_wo_std$penalty_factor)

glmnet_beta <- coef(glmnet_fit, s = "lambda.min")
rownames(glmnet_beta) <- c('(Intercept)',design_wo_std$std_X_colnames)
nz <- which(abs(glmnet_beta[,1]) > 0.00000001)
glmnet_beta[nz,]

# compare predictions -----------


