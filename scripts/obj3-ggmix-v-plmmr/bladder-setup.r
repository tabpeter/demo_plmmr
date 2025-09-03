#' Clean bladder data and export files as necessary for PenalizedGLMM

# Note: Assumes you have run the bladder processing script from objective 2

library(R.utils)

# Load data
dat <- readRDS(file.path('data', 'bladder-cancer.rds'))
ind <- which(dat$y != 'Biopsy')
x <- dat$x[ind,]
y <- (dat$y[ind] != 'Normal') * 1

# Calculate kinship matrix
K <- relatedness_mat(x, std = TRUE)

saveRDS(list(x = x,
             y = y,
             K = K),
        file.path('data', 'bladder-prepped.rds'))
