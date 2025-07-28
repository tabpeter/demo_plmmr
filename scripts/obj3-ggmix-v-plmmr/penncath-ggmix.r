library(ggmix)
design <- readRDS(file.path('results', 'n1401_p700K', 'std_penncath.rds'))
x <- bigmemory::attach.big.matrix(design$std_X)[,]
k <- read.csv(file.path('results', 'penncath-k.csv'))[, -1] |> as.matrix()
fit <- ggmix(
  x = x,
  y = design$y,
  kinship = k
)
