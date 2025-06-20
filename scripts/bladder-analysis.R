library(data.table)
library(plmmr)
library(glmnet)
library(msigdbr)
library(stringr)

# Load data
dat <- readRDS('data/bladder-cancer.rds')
ind <- which(dat$y != 'Biopsy')
x <- dat$x[ind,]
y <- dat$y[ind] != 'Normal'
g <- dat$g
b <- dat$batch[ind]
d <- dat$dates[ind]

# Fit models
cv_lasso <- cv.glmnet(x, y, lambda.min.ratio = 0.01, nfolds = length(y))
plot(cv_lasso)
cv_plmmr <- cv_plmm(x, y, lambda_min = 0.01, nfolds = length(y))
plot(cv_plmmr)

# Compare
beta <- list(
  lasso = coef(cv_lasso, s = 'lambda.min')[-1],
  plmmr = coef(cv_plmmr)[-1]
)
sel <- lapply(beta, \(x) which(x != 0))

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

gsel <- lapply(sel, \(x) g[x])
vapply(gsel, \(x) mean(x %in% cancer_genes), numeric(1))
vapply(gsel, \(x) mean(x %in% hallmark_genes), numeric(1))

# Association with batch: Ambiguous because outcome is confounded with batch
assoc_with_batch <- function(genes) {
  xx <- x[, genes]
  aov(xx ~ b) |>
    summary() |>
    vapply(\(x) x[1,5], numeric(1))
}
p <- lapply(beta, \(x) which(x != 0)) |>
  lapply(assoc_with_batch)
lapply(p, \(x) sum(x < 0.05))

# Determine association with batch
library(ggplot2)
j <- sel$lasso[4]
data.frame(b, y, x = x[,j]) |>
  ggplot(aes(b, x)) +
  geom_boxplot() +
  facet_grid(~y)
j <- sel$plmmr[4]
data.frame(b, y, x = x[,j]) |>
  ggplot(aes(b, x)) +
  geom_boxplot() +
  facet_grid(~y)

# Cluster heat
xlc <- x[y, sel$lasso]
xln <- x[!y, sel$lasso]
xpc <- x[y, sel$plmmr]
xpn <- x[!y, sel$plmmr]
xlc
arc <- data.frame(batch = as.integer(b[y]), row.names = rownames(xlc))
arn <- data.frame(batch = as.integer(b[!y]), row.names = rownames(xln))

pheatmap::pheatmap(
  xlc, scale = 'column', annotation_row = arc,
  show_rownames = FALSE,
  color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
)

pheatmap::pheatmap(
  xln, scale = 'column', annotation_row = arn,
  show_rownames = FALSE,
  color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
)

pheatmap::pheatmap(
  xpc, scale = 'column', annotation_row = arc,
  show_rownames = FALSE,
  color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
)

pheatmap::pheatmap(
  xpn, scale = 'column', annotation_row = arn,
  show_rownames = FALSE,
  color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
)

# Correlation
lapply(sel, \(j) abs(cor(as.integer(b), x[,j]))) |>
  vapply(mean, numeric(1))
lapply(sel, \(j) abs(cor(as.integer(b[y]), x[y,j]))) |>
  vapply(mean, numeric(1))
lapply(sel, \(j) abs(cor(as.integer(b[!y]), x[!y,j]))) |>
  vapply(mean, numeric(1))
lapply(sel, \(j) abs(cor(as.numeric(d[!y]), x[!y,j]))) |>
  vapply(mean, numeric(1))
lapply(sel, \(j) abs(cor(as.numeric(d[!y]), x[!y,j]))) |>
  vapply(median, numeric(1))

# Regression
f <- function(idx) {
  p <- numeric(length(idx))
  for (j in seq_along(idx)) {
    p[j] <- lm(as.numeric(d) ~ x[,j] + y) |>
      summary() |>
      getElement('coefficients') |>
      _[2, 4]
  }
  p
}

lapply(sel, f) |>
  boxplot(log = 'y')

# Setdiffs
las_only <- setdiff(sel[[1]], sel[[2]])
plm_only <- setdiff(sel[[2]], sel[[1]])

x[y, las_only] |>
  pheatmap::pheatmap(
    scale = 'column', annotation_row = arc,
    show_rownames = FALSE,
    color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
  )
x[y, plm_only] |>
  pheatmap::pheatmap(
    scale = 'column', annotation_row = arc,
    show_rownames = FALSE,
    color = colorRampPalette(c("#FF4E37FF", "white", "#008DFFFF"))(50)
  )

# GSEA ----
library(msigdbr)
library(fgsea)

# Convert sel to gene symbol
gsel <- lapply(sel, \(x) g[x])

# Get hallmark gene sets for Homo sapiens
msig <- msigdbr(species = "Homo sapiens", collection = "H")
gene_sets <- split(msig$gene_symbol, msig$gs_name)

# Anything?
l <- abs(beta[[1]])
names(l) <- g
gsea_res <- fgsea(pathways = gene_sets, stats = l[!is.na(g) & !duplicated(g)])
gsea_res[order(pval)]

l <- abs(beta[[2]])
names(l) <- g
gsea_res <- fgsea(pathways = gene_sets, stats = l[!is.na(g) & !duplicated(g)])
gsea_res[order(pval)]
