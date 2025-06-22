libary(ggmix)
design <- readRDS('results/n1401_p700K/std_penncath.rds')
x <- bigmemory::attach.big.matrix(design$std_X)[,]
k <- read.csv('results/penncath-k.csv')
fit <- ggmix(
  x = x,
  y = design$y,
  kinship = k
)
