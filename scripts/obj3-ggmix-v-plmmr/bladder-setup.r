#' Clean bladder data and export files as necessary for PenalizedGLMM

# Note: Assumes you have run the bladder processing script from objective 2

library(R.utils)

# Load data
dat <- readRDS(file.path('data', 'bladder-cancer.rds'))
ind <- which(dat$y != 'Biopsy')
x <- dat$x[ind,]
stdx <- ncvreg::std(x)
y <- (dat$y[ind] != 'Normal') * 1

write.csv(data.frame(y = y),
          'data/bladder_outcome.csv',
          row.names = FALSE)

write.csv(stdx,
          'data/bladder_stdx.csv',
          row.names = FALSE)

# Calculate kinship matrix
K <- relatedness_mat(stdx, std = FALSE)

# For PenalizedGLMM, do not scale and gzip
unscaleK <- K * ncol(stdx)
write.csv(unscaleK,
          'data/bladder_K_unscaled.csv',
          row.names = FALSE)
gzip('data/bladder_K_unscaled.csv',
     overwrite = TRUE)

saveRDS(list(stdx = stdx,
             y = y,
             K = K),
        'data/bladder-prepped.rds')
