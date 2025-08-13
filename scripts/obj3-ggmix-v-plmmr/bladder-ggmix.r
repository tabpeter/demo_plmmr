#' Analyze bladder data with ggmix

library(ggmix)

# Load in data
bladder <- readRDS('results/bladder-prepped.RDS')

stdX <- bladder$stdX
y <- bladder$y
K <- bladder$K
lambda <- bladder$lambda

# Fit model
ggmixmod <- ggmix(x = stdX,
                  y = y,
                  kinship = K,
                  lambda = lambda)

# Save coefficient paths
saveRDS(as.matrix(coef(ggmixmod)), 'results/bladder-ggmix.rds')
