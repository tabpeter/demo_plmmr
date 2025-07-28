library(plmmr)

# process the data
plink_data <- plmmr::process_plink(
  data_dir = file.path("data"),
  data_prefix = "qc_penncath",
  rds_dir = file.path("results", "n1401_p700K"),
  rds_prefix = "processed_n1401_p700K",
  impute_method = "mode",
  overwrite = TRUE,
  # turning off parallelization
  parallel = FALSE
)

# create a design
pheno <- read.csv(file.path("data", "penncath.csv"))
pheno <- pheno |> dplyr::mutate(FamID = as.character(FamID))
predictors <- pheno |> dplyr::transmute(FID = as.character(FamID), sex = sex, age = age)
design <- plmmr::create_design(
  data_file = plink_data,
  feature_id = "FID",
  rds_dir = file.path("results", "n1401_p700K"),
  new_file = "std_penncath",
  add_outcome = pheno,
  outcome_id = "FamID",
  outcome_col = "CAD",
  add_predictor = predictors,
  predictor_id = "FID",
  logfile = "design",
  overwrite = TRUE
)

# Calculate relatedness
std_X <- bigmemory::attach.big.matrix(design$std_X)
XX <- bigalgebra::dgemm(
  TRANSA = "N",
  TRANSB = "T",
  A = std_X,
  B = std_X
)
K <- XX[,] / ncol(std_X)
write.csv(K, file.path("results", "penncath-k.csv"))
