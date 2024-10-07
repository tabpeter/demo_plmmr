#' A function to measure the time spent in eigendecomposition based on logfile timestamps
#'
#' @param file_path Path to .log file
#'
#' @return time elapsed from input passing checks until eigendecomposition finished
#' @export
#'
eigen_time <- function(file_path) {
  # Read the log file
  log_lines <- readLines(file_path)

  # Extract the relevant lines
  input_data_line <- grep("Input data passed all checks at", log_lines, value = TRUE)
  eigendecomposition_line <- grep("Eigendecomposition finished at", log_lines, value = TRUE)

  # Extract the timestamps
  input_data_time <- sub(".*at\\s+", "", input_data_line)
  eigendecomposition_time <- sub(".*at\\s+", "", eigendecomposition_line)

  # Convert to POSIXct
  input_data_time <- as.POSIXct(input_data_time, format = "%Y-%m-%d %H:%M:%S")
  eigendecomposition_time <- as.POSIXct(eigendecomposition_time, format = "%Y-%m-%d %H:%M:%S")

  # Calculate the time difference
  time_difference <- difftime(eigendecomposition_time, input_data_time, units = "secs")

  return(time_difference)
}


