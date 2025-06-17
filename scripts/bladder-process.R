# https://jtleek.com/batch/
suppressPackageStartupMessages({
  library(affy)
  library(genefilter)
})

tab <- read.csv("data/bladdercels/bladdertab.csv", as.is = TRUE)
eset <- justRMA(filenames = tab$filename, celfile.path = "data/bladdercels/")
outcome <- tab[, 8]
bt <- tab[, 5]
Index <- which(outcome == "sTCC")
Cplus <- grep("CIS", bt[Index])
outcome[Index] <- "sTCC-CIS"
outcome[Index[Cplus]] <- "sTCC+CIS"
outcome[49:57] <- "Biopsy"
mat <- exprs(eset)

dates <- vector("character", ncol(mat))
for (i in seq(along = dates)) {
  tmp <- affyio::read.celfile.header(
    file.path("data/bladdercels", tab$filenam[i]),
    info = "full"
  )$DatHeader
  dates[i] <- strsplit(tmp, "\ +")[[1]][8]
}
dates <- as.Date(dates, "%m/%d/%Y")
batch <- (dates - min(dates)) |>
  as.numeric() |>
  cut(c(-1, 10, 75, 200, 300, 500))
saveRDS(list(
  x = mat,
  y = outcome,
  batch = batch,
  dates = dates),
  file = "data/bladder-cancer.rds"
)
