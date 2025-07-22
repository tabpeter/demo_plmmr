# The objective here is to create a data.frame that documents the timestamps for
# each model fit. This data.frame will be saved as an RDS and updated each time
# a model is fit.


# first task: set up empty data frame to fill in with results
g <- expand.grid(n = c(350, 700, 1050, 1401), p = c("400K", "600K", "700K"))
track_time <- as.data.frame(g)
track_time$process <- NA_real_
track_time$create_design <- NA_real_
track_time$fit <- NA_real_
# str(track_time)
saveRDS(track_time, file = "results/track_time.rds")

# second task: create folders to organize results
for (i in 1:nrow(g)){
  foldername <- file.path("results", paste0("n", g[i,1], "_p", g[i,2]))
  dir.create(foldername)
}
