#' A function to create charts that summarize computational time by n, p, and time
#'
#' @param dat A long-form data frame with variables n, p, and time
#' @param ... Optional arguments passed to `ggplot2::labs()`
#'
#' @return A ggplot
#' @export
#'
comp_time_chart <- function(dat, ...){
  ggplot2::ggplot(data = dat,
                  ggplot2::aes(x = n, y = time, color = p, group = p)) +
    ggplot2::geom_line(ggplot2::aes(color = p, group = p)) +
    ggplot2::labs(x = "n (number of observations)",
                  color = "p \n(number of features,\n in thousands)",
                  ...)

}
