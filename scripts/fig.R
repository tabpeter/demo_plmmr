# visualizing the timestamp data

track_time <- readRDS("results/track_time.rds")
track_time_long <- tidyr::pivot_longer(data = track_time,
                                       cols = process:fit,
                                       names_to = "routine",
                                       values_to = "time")

process_time <- track_time_long |> dplyr::filter(routine == "process")
design_time <- track_time_long |>
  dplyr::filter(routine == "create_design") |>
  dplyr::mutate(time = time/60)

fit_time <- track_time_long |>
  dplyr::filter(routine == "fit") |>
  dplyr::mutate(time = time/60)

f1 <- comp_time_chart(dat = process_time,
                title = "Computational time for processing PLINK files",
                y = "Time (seconds)")
ggplot2::ggsave("figures/process_time.png", width = 5)

f2 <- comp_time_chart(dat = design_time,
                title = "Computational time for creating a design object",
                y = "Time (minutes)")
ggplot2::ggsave("figures/design_time.png", width = 5)

f3 <- comp_time_chart(dat = fit_time,
                title = "Computational Time for fitting a model",
                y = "Time (minutes)")
ggplot2::ggsave("figures/fit_time.png", width = 5)

# ggpubr::ggarrange(f1, f2, f3, nrow = 1, widths = 10)
# ggplot2::ggsave("figures/comp_time.png")
