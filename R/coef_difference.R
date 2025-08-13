#' A function to create a comparison plot between the coefficient paths of two
#' penalized mixed modeling approaches
#'
#' @param modeldat List of two data frames containing the coefficient paths for
#'                 each model, fit using the same values of lambda. The intercept
#'                 should be removed. The list names will be used for display.
#' @param lambda Lambda path used to fit both models.
#'
#' @return Plot of summarized absolute coefficient differences between two
#'         penalized mixed modeling approaches, including the maximum difference
#'         and the median non-zero difference
#'
coef_difference <- function(modeldat, lambda) {
  loglambda <- lambda |>
               as.numeric() |>
               log()

  diffdat <- abs(modeldat[[1]] - modeldat[[2]])
  mod1 <- names(modeldat)[[1]]
  mod2 <- names(modeldat)[[2]]

  sumdat <- data.frame(loglamda = loglambda,
                       maxdiff = apply(diffdat, 2, max),
                       mediandiff = apply(diffdat, 2,
                                          function(x) { median(x[x != 0]) }))

  ggplot(sumdat, aes(x = loglambda)) +
    geom_line(aes(y = maxdiff, col = "Max"), lty = 2) +
    geom_line(aes(y = mediandiff, col = "Median"), lty = 1) +
    xlab(expression(paste("log ", lambda))) +
    ylab(paste(mod1, "-", mod2,
               "\n Absolute Coefficient Difference", sep = " ")) +
    scale_color_manual(values = c("Max" = "red", "Median" = "blue"),
                       labels = c("Maximum",
                                  "Median \n Non-zero")) +
    labs(color = "Difference") +
    theme_bw()
}
