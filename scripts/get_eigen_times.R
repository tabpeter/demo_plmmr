# Objective: get the timestamps for the eigendecomposition and add to time tracking RDS object
res_folders <- list.files(path = "results/")

track_time <- readRDS("results/track_time.rds")
track_time$eigendecomp <- NA_real_

# get times for
for (i in 1:length(res_folders)) {
  logfile <- paste0(file.path("results", res_folders[i], "fit"), ".log")
  if (file.exists(logfile)) {
    n <- sub(".*n([0-9]+)_.*", "\\1", res_folders[i]) |> as.numeric()
    p <- sub(".*p([0-9]+).*", "\\1", res_folders[i]) |> as.numeric()
    e_time <- eigen_time(logfile)
    print(e_time)
    track_time[track_time$n == n & track_time$p == paste0(p, "K"),
               "eigendecomp"] <- e_time
  }
}
saveRDS(track_time, "results/track_time.rds")

