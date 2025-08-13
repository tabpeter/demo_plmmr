#' Clean bladder data and export files as necessary for PenalizedGLMM

# Note: Assumes you have run the bladder processing script from objective 2

library(R.utils)

# Need dev version of plmmr to generate lambda sequence
devtools::load_all('../plmmr')

# Load data
dat <- readRDS(file.path('data', 'bladder-cancer.rds'))
ind <- which(dat$y != 'Biopsy')
x <- dat$x[ind,]
stdx <- ncvreg::std(x)
y <- (dat$y[ind] != 'Normal') * 1

write.table(data.frame(y = y),
            'results/bladder_outcome.csv',
            row.names = FALSE,
            sep = ",")

write.table(stdx,
            'results/bladder_stdx.csv',
            row.names = FALSE,
            sep = ",")

# Establish sequence of lambda values
lambdaseq <- setup_lambda(stdx, y, alpha = 1, lambda_min = 0.01, nlambda = 100,
                          penalty_factor = rep(1, ncol(stdx)))

write.table(lambdaseq,
            'results/bladder_lambda.csv',
            row.names = FALSE,
            col.names = FALSE,
            sep = ",")

# Calculate kinship matrix
K <- relatedness_mat(stdx, std = FALSE)

write.table(K,
            'results/bladder_K.csv',
            row.names = FALSE,
            sep = ",")

# for PenalizedGLMM, do not scale and gzip
unscaleK <- K * ncol(stdx)
write.table(unscaleK,
            'results/bladder_K_unscaled.csv',
            row.names = FALSE,
            sep = ",")
gzip('results/bladder_K_unscaled.csv',
     overwrite = TRUE)


saveRDS(list(stdX = stdx,
             y = y,
             K = K,
             lambda = lambdaseq),
        'results/bladder-prepped.rds')
