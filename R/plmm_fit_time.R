#' A function to measure the time spent in plmm_fit() based on logfile timestamps
#'
#' @param file_path Path to .log file
#'
#' @return time elapsed from eigendecomposition finished to model fit complete
#' @export
#'
plmm_fit_time <- function(file_path) {
  # Read the log file
  log_lines <- readLines(file_path)

  # Extract the relevant lines
  decomp_line <- grep("Eigendecomposition finished at", log_lines, value = TRUE)
  model_ready_line <- grep("Model ready at", log_lines, value = TRUE)

  # Extract the timestamps
  decomp_time <- sub(".*at\\s+", "", decomp_line)
  model_ready_time <- sub(".*at\\s+", "", model_ready_line)

  # Convert to POSIXct
  decomp_time <- as.POSIXct(decomp_time, format = "%Y-%m-%d %H:%M:%S")
  model_ready_time <- as.POSIXct(model_ready_time, format = "%Y-%m-%d %H:%M:%S")

  # Calculate the time difference
  time_difference <- difftime(model_ready_time, decomp_time, units = "secs")

  return(time_difference)
}


