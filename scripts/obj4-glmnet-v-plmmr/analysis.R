# Preamble: Load necessary libraries ------------------------
library(glmnet)

# Set up file paths and directories ------------------------
# Define base directories for inputs and outputs
# This makes it easy to change the root folder structure in one place.
results_dir <- "results"
obj4_dir <- file.path(results_dir, "obj4")

# Create the output directory if it doesn't already exist
# The 'recursive = TRUE' argument creates any necessary parent directories.
if (!dir.exists(obj4_dir)) {
  dir.create(obj4_dir, recursive = TRUE)
}

# Construct the full path to the input file
penncath_file <- file.path(results_dir, "n1401_p700K", "penncath_wo_std.rds")
design_wo_std <- readRDS(penncath_file) # this has the processed data matrix - see setup.R

# Attach the big.matrix data
X <- bigmemory::attach.big.matrix(design_wo_std$subset_X)


# Create train and test sets ------------------------
# Build the model on 1000 observations; hold out the other 401 for prediction
set.seed(37075) # Set seed for reproducible random sampling
test_idx <- sample(1:nrow(X), 401) |> sort()
test_X <- X[test_idx,]
train_X <- X[-test_idx,]

test_y <- design_wo_std$y[test_idx]
train_y <- design_wo_std$y[-test_idx]

# PLMM ------------------------
train_design <- plmmr::create_design(X = train_X,
                                     y = train_y)

# Use file.path to construct the save path
# Note: The plmmr function adds the '.rds' extension automatically.
cv_fit_path <- file.path(obj4_dir, "cv_fit")

cvres_plmm <- plmmr::cv_plmm(design = train_design,
                             trace = TRUE,
                             save_rds = cv_fit_path)

# For reading in results from RDS files, you can use the lines below:
# cv_fit_rds_path <- file.path(obj4_dir, "cv_fit.rds")
# cvres_plmm <- readRDS(cv_fit_rds_path)
# cvres_plmm <- structure(cvres_plmm, class="cv_plmm")

summary(cvres_plmm)
plmm_beta <- coef(cvres_plmm)
names(plmm_beta) <- c("(Intercept)",design_wo_std$std_X_colnames)
plmm_nz <- which(abs(plmm_beta) > 1e-8) # Using 1e-8 for numeric precision
plmm_beta[plmm_nz] |> round(3)


# Lasso only ------------------------
glmnet_fit <- glmnet::cv.glmnet(x = train_X,
                                y = train_y,
                                # use same settings as in PLMM approach
                                nfolds = 5,
                                lambda = cvres_plmm$lambda,
                                penalty.factor = train_design$penalty_factor,
                                # show trace
                                trace.it = TRUE)

# Construct the save path for the glmnet model object
glmnet_fit_path <- file.path(obj4_dir, "glmnet_fit.rds")
saveRDS(glmnet_fit, glmnet_fit_path)

glmnet_beta <- coef(glmnet_fit, s = "lambda.min")
rownames(glmnet_beta) <- c('(Intercept)', design_wo_std$std_X_colnames)
glmnet_nz <- which(abs(glmnet_beta[,1]) > 1e-8)
glmnet_beta[glmnet_nz,] |> round(3)


# Compare predictions on the test set ------------------------
# Null model (predicting the mean of the training data)
null_pred <- rep(mean(train_y), length(test_y))
(null_mspe <- mean((test_y - null_pred)^2))

# PLMM predictions
plmm_fit <- plmmr::plmm(design = train_design,
                        lambda = cvres_plmm$lambda_min,
                        trace = TRUE)
pred_plmm <- predict(plmm_fit, newX = test_X, X = train_X)
(plmm_mspe <- mean((test_y - pred_plmm)^2))


# GLMNET predictions
pred_glmnet <- predict(glmnet_fit, newx = test_X, s = "lambda.min")

# Construct the save path for the predictions
pred_glmnet_path <- file.path(obj4_dir, "pred_glmnet.rds")
saveRDS(pred_glmnet, pred_glmnet_path)

# Calculate Mean Squared Prediction Error on the test set
(glmnet_mspe <- mean((test_y - pred_glmnet)^2))


# Create table of results ------------------------------
results_df <- data.frame(
  model = c("Null", "GLMNET", "PLMM"),
  MSPE = c(null_mspe, glmnet_mspe, plmm_mspe) |> round(digits = 3),
  NVAR = c(NA_integer_,
           length(glmnet_beta[glmnet_nz,]) - 1,
           length(plmm_beta[plmm_nz]) - 1)
)

print(results_df)
