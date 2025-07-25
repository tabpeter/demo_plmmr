# TKP - July 2025
# Objective - create candidate models using plmmr and glmnet, then use
#   CV for model selection.
# Will use the PennCath data again here.
# This script assumes that the model fitting from objective 1 has already been done.

# set up ------------------------
design_wo_std <- readRDS("results/n1401_p700K/penncath_wo_std.rds")

X <- bigmemory::attach.big.matrix(design_wo_std$subset_X)

# create train and test sets
# build the model on 1000 observations; hold out the other 401 for evaluating prediction
set.seed(37075)
test_idx <- sample(1:nrow(X), 401) |> sort()
test_X <- X[test_idx,]
train_X <- X[-test_idx,]

test_y <- design_wo_std$y[test_idx]
train_y <- design_wo_std$y[-test_idx]

# PLMM ------------
train_design <- plmmr::create_design(X = train_X,
                                     y = train_y)

cvres_plmm <- plmmr::cv_plmm(design = train_design,
                             trace = TRUE,
                             save_rds = "results/obj4/cv_fit")

# for reading in results from RDS files, use the lines below:
# cvres_plmm <- readRDS("results/obj4/cv_fit.rds")
# cvres_plmm <- structure(cvres_plmm, class="cv_plmm")

summary(cvres_plmm)
plmm_beta <- coef(cvres_plmm)
plmm_nz <- which(abs(plmm_beta[,1]) > 0.00000001)
plmm_beta[plmm_nz,]

# lasso only ------------
library(glmnet)
glmnet_fit <- glmnet::cv.glmnet(x = train_X,
                                y = train_y,
                                # use same settings as in PLMM approach
                                nfolds = 5,
                                lambda = cvres_plmm$lambda,
                                penalty.factor = design_wo_std$penalty_factor,
                                # show trace
                                trace.it = T)

saveRDS(glmnet_fit, "results/obj4/glmnet_fit.rds")

glmnet_beta <- coef(glmnet_fit, s = "lambda.min")
rownames(glmnet_beta) <- c('(Intercept)', design_wo_std$std_X_colnames)
glmnet_nz <- which(abs(glmnet_beta[,1]) > 0.00000001)
glmnet_beta[glmnet_nz,]


# compare predictions -----------
# null model (predict mean for all outcomes)
(null_mspe <- crossprod(design$y - rep(mean(design$y, length(design$y))))/length(design$y))

# PLMM
plmm_yhat <- readRDS("results/obj4/cv_fit_yhat.rds")
pred_plmm <- plmm_yhat[,cvres_plmm$min]
(plmm_mspe <- crossprod(design$y - cvpred_plmm[cvres_plmm$min])/length(design$y))

# glmnet
pred_glmnet <- predict(glmnet_fit, newx = ram_X, s = "lambda.min")
saveRDS(pred_glmnet, "results/obj4/pred_glmnet.rds")
(glmnet_mspe <- crossprod(design$y - pred_glmnet)/length(design$y))
