#' Create coefficient comparisons for the bladder model fits

library(ggplot2)

bladderplmmr <- readRDS('results/bladder-plmmr.rds')
bladderggmix <- readRDS('results/bladder-ggmix.rds')
bladderpglmm <- read.table('results/bladder-PenalizedGLMM.csv',
                           sep = ",",
                           header = TRUE)

# Calculate differences, removing intercept
coef_difference(list(plmmr = bladderplmmr[-1,],
                     ggmix = bladderggmix[-1,]),
                colnames(bladderplmmr))
ggsave(file.path("figures", "bladder_plmmr_ggmix.png"), width = 8, height = 6)

coef_difference(list(plmmr = bladderplmmr[-1,],
                     PenalizedGLMM = bladderpglmm),
                colnames(bladderplmmr))
ggsave(file.path("figures", "bladder_plmmr_pglmm.png"), width = 8, height = 6)
