# Objective: visualize the timestamp data
library(ggplot2)
library(dplyr)

## read in data and create long-form -------------------------------------------
track_time <- readRDS(file.path("results", "track_time.rds"))
track_time <- track_time |>
  dplyr::mutate(total_time = (process + create_design + fit)/60)

track_time_long <- tidyr::pivot_longer(data = track_time,
                                       cols = process:eigendecomp,
                                       names_to = "routine",
                                       values_to = "time")

## look at each step of the pipeline separately --------------------------------
process_time <- track_time_long |> dplyr::filter(routine == "process")
design_time <- track_time_long |>
  dplyr::filter(routine == "create_design") |>
  dplyr::mutate(time = time/60)

# NB: 'fit' includes eigendecomposition and model fitting steps (prep + fit + format in plmmr);
#     plmm_fit() is only model fitting (no eigendecomposition)
fit_time <- track_time_long |>
  dplyr::filter(routine == "fit") |>
  dplyr::mutate(time = time/60)

eigendecomp_time <- track_time_long |>
  dplyr::filter(routine == "eigendecomp") |>
  dplyr::mutate(time = time/60)

f1 <- comp_time_chart(dat = process_time,
                      title = "Computational time for processing PLINK files",
                      y = "Time (seconds)")
ggplot2::ggsave(file.path("figures", "process_time.png"), width = 8, height = 6)

f2 <- comp_time_chart(dat = design_time,
                      title = "Computational time for creating a design object",
                      y = "Time (minutes)")
ggplot2::ggsave(file.path("figures", "design_time.png"), width = 8, height = 6)

f3 <- comp_time_chart(dat = fit_time,
                      title = "Computational Time for fitting a model",
                      y = "Time (minutes)")
ggplot2::ggsave(file.path("figures", "fit_time.png"), width = 8, height = 6)

# ggpubr::ggarrange(f1, f2, f3, nrow = 1, widths = 10)
# ggplot2::ggsave(file.path("figures", "comp_time.png"))

## look at total time for varying n & p ----------------------------------------
ggplot2::ggplot(data = track_time,
                ggplot2::aes(x = n,
                             y = total_time,
                             color = p,
                             group = p)) +
  ggplot2::geom_line(ggplot2::aes(color = p, group = p)) +
  ggplot2::expand_limits(y = 0) +
  ggplot2::labs(x = "n (number of observations)",
                y = "Time (min)",
                color = "p \n(number of features,\n in thousands)") +
  theme_minimal()
ggplot2::ggsave(file.path("figures", "total_time.png"), height = 3, width = 5)
ggplot2::ggsave(file.path("figures", "total_time.pdf"), height = 3, width = 5)


## show proportion of time spent on eigendecomposition at each size-------------
track_time_long |>
  mutate(routine = if_else(routine == "process", "Processing", routine)) |>
  mutate(routine = if_else(routine == "create_design", "Processing", routine)) |>
  mutate(routine = if_else(routine == "eigendecomp", "Decomposition", routine)) |>
  mutate(routine = if_else(routine == "fit", "Model fitting", routine)) |>
  mutate(routine = factor(routine, levels = c("Processing", "Decomposition", "Model fitting"))) |>
  mutate(time = if_else(is.na(time), 1, time)) |>
  ggplot(aes(x = factor(n), y = time/60, fill = routine)) +
  geom_bar(stat = "identity") +
  labs(x = "n", y = "Total time (min)", fill = "") +
  theme_minimal() +
  facet_wrap(~p)
ggplot2::ggsave(file.path("figures", "proportion_breakdown.png"), height = 5, width = 7)
ggplot2::ggsave(file.path("figures", "proportion_breakdown.pdf"), height = 3, width = 6)


### to put the two figures above in one panel -----
panel_a <- ggplot2::ggplot(data = track_time,
                           ggplot2::aes(x = n,
                                        y = total_time,
                                        color = p,
                                        group = p)) +
  ggplot2::geom_line(ggplot2::aes(color = p, group = p)) +
  ggplot2::expand_limits(y = 0) +
  # ggplot2::scale_x_continuous(expand = c(0, 0)) +
  # ggplot2::scale_y_continuous(expand = c(0, 0)) +
  ggplot2::labs(x = "n (number of observations)",
                y = "Time (min)",
                color = "p \n(number of features,\n in thousands)",
                title = "Total time for plmmr pipeline",
                subtitle = "Includes pre-processing, eigendecomposition, and model fitting")


panel_b <- ggplot2::ggplot(track_time_long |> dplyr::filter(routine %in% plmmr_steps),
                           ggplot2::aes(x = factor(n),
                                        y = time/60,
                                        fill = factor(routine, levels = plmmr_steps))) +
  ggplot2::geom_bar(stat = "identity") +
  # ggplot2::scale_fill_viridis_d() +
  ggplot2::labs(title = "Time spent in each routine within plmmr pipeline",
                x = "n",
                y = "Total time (min)",
                fill = "Routine") +
  ggplot2::theme_minimal() +
  ggplot2::facet_wrap(~p)

ggpubr::ggarrange(panel_a, panel_b)
