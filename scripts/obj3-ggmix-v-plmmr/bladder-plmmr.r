#' Analyze bladder data with plmmr

# Load data
bladder <- readRDS('data/bladder-prepped.rds')

stdx <- bladder$stdx
y <- bladder$y
K <- bladder$K

# Fit model
plmmrmod <- plmm(stdx,
                 y,
                 K = K)
plot(plmmrmod)

# Get CV best fit
plmmrcv <- cv_plmm(stdx,
                   y,
                   K = K,
                   nfolds = length(y))

# Save coefficient paths
saveRDS(list(coefpath = coef(plmmrmod),
             coefcv = coef(plmmrcv)),
        'results/bladder-plmmr.rds')

# Save lambda values for use in other models
saveRDS(list(lambdaseq = plmmrmod$lambda,
             lambdamin = plmmrcv$lambda_min),
        'data/bladder-lambda.rds')
