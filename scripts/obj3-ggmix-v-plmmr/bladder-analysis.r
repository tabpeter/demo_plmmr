library(data.table)
library(ggplot2)
library(msigdbr)
library(stringr)
library(ggmix)

##### Model fitting #####

# Load data
bladder <- readRDS(file.path('data', 'bladder-prepped.rds'))

x <- bladder$x
y <- bladder$y
n <- ncol(bladder$x)

# Fit plmmr model
plmmrmod <- plmm(x,
                 y)
plot(plmmrmod)

# Get CV plmmr model
plmmrcv <- cv_plmm(x,
                   y,
                   nfolds = length(y),
                   lambda_min = 0.01,
                   save_rds = file.path('results', 'bladder-plmmr.rds'))
# plmmrcv <- readRDS(file.path('results', 'bladder-plmmr.rds'))
# plmmrcv <- structure(plmmrcv, class = 'cv_plmm')
plot(plmmrcv)

# Fit ggmix model
initmod <- ggmix(x = x,
                 y = y,
                 K = x,
                 standardize = TRUE)

plot(initmod, xvar = 'lambda')

# LOOCV
ggpred <- list()
for(i in 1:length(y)) {
  xtmp <- bladder$x[-i,]
  ytmp <- bladder$y[-i]

  mod <- ggmix(x = xtmp,
               y = ytmp,
               K = xtmp,
               standardize = TRUE,
               lambda = initmod$lambda)

  # Consider how standardization would affect this next line before finalizing
  predcov <- var(bladder$x[i,], t(bladder$x[-i,])) * ((n - 1) / n)

  ggpred[[i]] <- predict(mod,
                         s = initmod$lambda,
                         newx = bladder$x[i,,drop = FALSE],
                         type = 'individual',
                         covariance = predcov)
}

# Calculate MSPE
loss <- list()
for(i in 1:length(y)) {
  loss[[i]] <- (ggpred[[i]] - y[i])^2
}

loss <- do.call(rbind, loss)
E <- apply(loss, 2, mean)

ggmod <- list(beta_vals = initmod$beta,
              lambda = initmod$lambda,
              min = which.min(E),
              lambda_min = initmod$lambda[which.min(E)])
saveRDS(ggmod,
        file.path('results', 'bladder-ggmix.rds'))
# ggmod <- readRDS(file.path('results', 'bladder-ggmix.rds'))

##### Comparison #####

# Get variable selections
plmmrvars <- which(coef(plmmrcv)[-1] != 0)
ggmixvars <- which(ggmod$beta_vals[-1, ggmod$min] != 0)

length(plmmrvars)
length(ggmixvars)

intersect(plmmrvars, ggmixvars) |> length()

# Define set of "plausible cancer genes"
# TODO: this is completely duplicated from obj2, coalesce?
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

# Get bladder data gene names
dat <- readRDS(file.path('data', 'bladder-cancer.rds'))
g <- dat$g

# Summarize
plmmrgene <- g[plmmrvars]
mean(plmmrgene %in% cancer_genes)

ggene <- g[ggmixvars]
mean(ggene %in% cancer_genes)
