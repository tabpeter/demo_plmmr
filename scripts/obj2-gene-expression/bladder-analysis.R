library(data.table)
library(plmmr)
library(glmnet)
library(msigdbr)
library(stringr)

# Load data
dat <- readRDS(file.path('data', 'bladder-cancer.rds'))
ind <- which(dat$y != 'Biopsy')
x <- dat$x[ind,]
y <- dat$y[ind] != 'Normal'
g <- dat$g
b <- dat$batch[ind]
d <- dat$dates[ind]

# Fit models
cv_lasso <- cv.glmnet(
  x,
  y,
  lambda.min.ratio = 0.01,
  grouped = FALSE,
  nfolds = length(y),
  keep = TRUE
)
plot(cv_lasso)
cv_plmmr <- cv_plmm(x, y, lambda_min = 0.01, nfolds = length(y))
plot(cv_plmmr)

# Compare prediction
rmse <- function(x) {sqrt(crossprod(x) / length(x))}
rmse(cv_lasso$fit.preval[, cv_lasso$index["min",1]] - y)
rmse(cv_plmmr$Y[, cv_plmmr$min] - y)

# Compare selections
beta <- list(
  lasso = coef(cv_lasso, s = 'lambda.min')[-1],
  plmmr = coef(cv_plmmr)[-1]
)
sel <- lapply(beta, \(x) which(x != 0))
vapply(sel, length, 1)

# Define set of "plausible cancer genes"
hallmark <- msigdbr(species = "Homo sapiens", collection = "H") |>
  as.data.table()
cancer_hallmarks <- c(
  "HALLMARK_E2F_TARGETS",
  "HALLMARK_G2M_CHECKPOINT",
  "HALLMARK_MYC_TARGETS_V1",
  "HALLMARK_MYC_TARGETS_V2",
  "HALLMARK_P53_PATHWAY",
  "HALLMARK_DNA_REPAIR",
  "HALLMARK_APOPTOSIS",
  "HALLMARK_PI3K_AKT_MTOR_SIGNALING",
  "HALLMARK_TNFA_SIGNALING_VIA_NFKB",
  "HALLMARK_TGF_BETA_SIGNALING",
  "HALLMARK_MTORC1_SIGNALING"
)
hallmark_genes <- hallmark[gs_name %in% cancer_hallmarks]$gene_symbol
c2 <- msigdbr(species = "Homo sapiens", collection = "C2") |>
  as.data.table()
c2_genes <- c2 |>
  _[str_detect(gs_name, regex("cancer|tumor", ignore_case = TRUE))] |>
  getElement('gene_symbol')
cancer_genes <- c(hallmark_genes, c2_genes) |> unique()
length(cancer_genes)

# Summarize
gsel <- lapply(sel, \(x) g[x])
vapply(gsel, \(x) mean(x %in% cancer_genes), numeric(1))
vapply(gsel, \(x) mean(x %in% hallmark_genes), numeric(1))
vapply(gsel, \(x) mean(x %in% c2_genes), numeric(1))
