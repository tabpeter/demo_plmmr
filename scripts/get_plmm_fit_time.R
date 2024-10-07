# Objective: get the timestamps for plmm_fit() and add to time tracking RDS object
res_folders <- list.files(path = "results/")

track_time <- readRDS("results/track_time.rds")
track_time$plmm_fit <- NA_real_

# get times for
for (i in 1:length(res_folders)) {
  logfile <- paste0(file.path("results", res_folders[i], "fit"), ".log")
  if (file.exists(logfile)) {
    n <- sub(".*n([0-9]+)_.*", "\\1", res_folders[i]) |> as.numeric()
    p <- sub(".*p([0-9]+).*", "\\1", res_folders[i]) |> as.numeric()
    pfit_time <- plmm_fit_time(logfile)
    print(pfit_time)
    track_time[track_time$n == n & track_time$p == paste0(p, "K"),
               "plmm_fit"] <- pfit_time
  }
}
saveRDS(track_time, "results/track_time.rds")
