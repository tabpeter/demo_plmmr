#' fit a PLMM model for penncath subset with specified dimensions
#'
#' @param n Integer indicating the number of rows (observations) in the data subset of interest
#' @param p Integer indicating the approximate number of columns (features) in the data subset of interest
#' @param ... Other arguments to plmmr functions (not currently implemented)
run_analysis <- function(n, p, ...){

  # process the data
  process_time <- system.time(
    plink_data <- plmmr::process_plink(data_dir = file.path("data"),
                                data_prefix = paste0("n",n, "_p", p, "K"),
                                rds_dir = file.path('results', paste0("n",n, "_p", p, "K")),
                                rds_prefix = paste0("processed_n",n,"_p",p,"K"),
                                impute_method = "mode",
                                ...)
  )


  # create a design
  pheno <- read.csv("data/penncath.csv")
  pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
  predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)

  design_time <- system.time(
    design <- plmmr::create_design(data_file = plink_data,
                            feature_id = "FID",
                            rds_dir = file.path('results', paste0("n",n, "_p", p, "K")),
                            new_file = "std_penncath_lite",
                            add_outcome = pheno,
                            outcome_id = "FamID",
                            outcome_col = "CAD",
                            add_predictor = predictors,
                            predictor_id = "FID",
                            logfile = "design",
                            ...)
  )

  # fit a model
  fit_time <- system.time(
    plmmr::plmm(design = design,
         save_rds = file.path('results', paste0("n",n, "_p", p, "K"), "fit"),
         trace = T)
  )

  # save timestamps
  track_time <- readRDS("results/track_time.rds")
  track_time[track_time$n == n & track_time$p == paste0(p, "K"), "process"] <- process_time['elapsed']
  track_time[track_time$n == n & track_time$p == paste0(p, "K"), "create_design"] <- design_time['elapsed']
  track_time[track_time$n == n & track_time$p == paste0(p, "K"), "fit"] <- fit_time['elapsed']
  saveRDS(track_time, 'results/track_time.rds')

}
