# visualizing the timestamp data

track_time <- readRDS("results/track_time.rds")
track_time <- track_time |>
  dplyr::mutate(total_time = process + create_design + fit)

track_time_long <- tidyr::pivot_longer(data = track_time,
                                       cols = process:plmm_fit,
                                       names_to = "routine",
                                       values_to = "time")

process_time <- track_time_long |> dplyr::filter(routine == "process")
design_time <- track_time_long |>
  dplyr::filter(routine == "create_design") |>
  dplyr::mutate(time = time/60)

# NB: 'fit' includes eigendecomposition and model fitting steps (prep + fit + format in plmmr);
#   plmm_fit() is only model fitting (no eigendecomposition)
fit_time <- track_time_long |>
  dplyr::filter(routine == "fit") |>
  dplyr::mutate(time = time/60)

eigendecomp_time <- track_time_long |>
  dplyr::filter(routine == "eigendecomp") |>
  dplyr::mutate(time = time/60)

f1 <- comp_time_chart(dat = process_time,
                title = "Computational time for processing PLINK files",
                y = "Time (seconds)")
ggplot2::ggsave("figures/process_time.png", width = 8, height = 6)

f2 <- comp_time_chart(dat = design_time,
                title = "Computational time for creating a design object",
                y = "Time (minutes)")
ggplot2::ggsave("figures/design_time.png", width = 8, height = 6)

f3 <- comp_time_chart(dat = fit_time,
                title = "Computational Time for fitting a model",
                y = "Time (minutes)")
ggplot2::ggsave("figures/fit_time.png", width = 8, height = 6)

# ggpubr::ggarrange(f1, f2, f3, nrow = 1, widths = 10)
# ggplot2::ggsave("figures/comp_time.png")

# show proportion of time spent on eigendecomposition at each size
ggplot2::ggplot(track_time_long |> dplyr::filter(routine %in% c("process", "create_design", "eigendecomp", "plmm_fit")),
                ggplot2::aes(x = factor(n),
                             y = time/60,
                             fill = factor(routine, levels = c("process", "create_design", "eigendecomp", "plmm_fit")))) +
  ggplot2::geom_bar(stat = "identity") +
  ggplot2::labs(title = "Time spent in each routine within plmmr pipeline",
       x = "n",
       y = "Total time (min)",
       fill = "Routine") +
  ggplot2::theme_minimal() +
  ggplot2::facet_wrap(~p)
