#' Analyze bladder data with plmmr

# Load data
bladder <- readRDS('results/bladder-prepped.rds')

stdX <- bladder$stdX
y <- bladder$y
K <- bladder$K
lambda <- bladder$lambda

# Fit model
plmmrmod <- plmm(stdx,
                 y,
                 K = K,
                 lambda = lambda,
                 nfolds = length(y))
plot(plmmrmod)

# Save coefficient paths
saveRDS(coef(plmmrmod), 'results/bladder-plmmr.rds')
