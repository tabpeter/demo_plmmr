#' Analyze penncath data with plmmr
library(plmmr)
fit <- plmmr::plmm(
  design = 'results/n1401_p700K/std_penncath.rds',
  save_rds = "results/n1401_p700K/fit",
  trace = T
)
