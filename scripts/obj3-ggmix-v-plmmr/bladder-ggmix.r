#' Analyze bladder data with ggmix

library(ggmix)

# Load in data
bladder <- readRDS('data/bladder-prepped.rds')
lambda <- readRDS('data/bladder-lambda.rds')

stdx <- bladder$stdx
y <- bladder$y
K <- bladder$K
lambdaseq <- lambda$lambdaseq

# Fit model
ggmixmod <- ggmix(x = stdx,
                  y = y,
                  kinship = K,
                  lambda = lambdaseq)

# Get fit from plmmr CV error minimum lambda
ggmixcv <- predict(ggmixmod,
                   s = lambda$lambdamin,
                   type = 'coefficients')

# Save coefficient paths
saveRDS(list(coefpath = as.matrix(coef(ggmixmod)),
             coefcv = as.matrix(ggmixcv)),
        'results/bladder-ggmix.rds')
