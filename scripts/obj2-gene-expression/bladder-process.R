suppressPackageStartupMessages({
  library(affy)
  library(data.table)
  library(genefilter)
  library(hgu133a.db)
})

# Gene expression
tab <- read.csv(file.path("data", "bladdercels", "bladdertab.csv"), as.is = TRUE)
eset <- justRMA(filenames = tab$filename, celfile.path = file.path("data", "bladdercels"))
outcome <- tab[, 8]
bt <- tab[, 5]
Index <- which(outcome == "sTCC")
Cplus <- grep("CIS", bt[Index])
outcome[Index] <- "sTCC-CIS"
outcome[Index[Cplus]] <- "sTCC+CIS"
outcome[49:57] <- "Biopsy"
mat <- exprs(eset)
dt <- select(
  hgu133a.db,
  keys = rownames(mat),
  column = c("SYMBOL", "ENSEMBL"),
  keytype = "PROBEID",
  multiVals = "first"
) |>
  as.data.table() |>
  _[, first(.SD), PROBEID] |>
  setkey('PROBEID') |>
  _[rownames(mat)]
stopifnot(identical(dt$PROBEID, rownames(mat)))
x <- t(mat)
g <- dt$SYMBOL
names(g) <- dt$PROBEID

# Batch information
dates <- vector("character", ncol(mat))
for (i in seq(along = dates)) {
  tmp <- affyio::read.celfile.header(
    file.path("data", "bladdercels", tab$filenam[i]),
    info = "full"
  )$DatHeader
  dates[i] <- strsplit(tmp, "\ +")[[1]][8]
}
dates <- as.Date(dates, "%m/%d/%Y")
batch <- (dates - min(dates)) |>
  as.numeric() |>
  cut(c(-1, 10, 75, 200, 300, 500))

# Export
saveRDS(list(
  x = t(mat),
  y = outcome,
  g = g,
  batch = batch,
  dates = dates),
  file = file.path("data", "bladder-cancer.rds")
)
