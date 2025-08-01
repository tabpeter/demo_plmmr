#' A function to create a *filebacked* data matrix *without* standardization, outcome vector, and penalty factor to be passed to a model fitting function
#'
#' @param data_file               A filepath to rds file of processed data (data from `process_plink()` or `process_delim()`)
#' @param rds_dir                 The path to the directory in which you want to create the new '.rds' and '.bk' files.
#' @param new_file                User-specified filename (*without .bk/.rds extension*) for the to-be-created .rds/.bk files. Must be different from any existing .rds/.bk files in the same folder.
#' @param feature_id              A string specifying the column in the data X (the feature data) with the row IDs (e.g., identifiers for each row/sample/participant/, etc.). No duplicates allowed.
#'                                  - for PLINK data: a string specifying an ID column of the PLINK `.fam` file. Options are "IID" (default) and "FID"
#'                                  - for all other filebacked data: a character vector of unique identifiers (IDs) for each row of the feature data (i.e., the data processed with `process_delim()`)
#'                                  - if left NULL (default), X is assumed to have the same row-order as add_outcome.
#'                                  **Note**: if this assumption is made in error, calculations downstream will be incorrect. Pay close attention here.
#' @param add_outcome             A data frame or matrix with two columns: and ID column and a column with the outcome value (to be used as 'y' in the final design). IDs must be characters, outcome must be numeric.
#' @param outcome_id              A string specifying the name of the ID column in 'add_outcome'
#' @param outcome_col             A string specifying the name of the phenotype column in 'add_outcome'
#' @param na_outcome_vals         A vector of numeric values used to code NA values in the outcome. Defaults to `c(-9, NA_integer)` (the -9 matches PLINK conventions).
#' @param add_predictor           Optional (for PLINK data only): a matrix or data frame to be used for adding additional **unpenalized** covariates/predictors/features from an external file (i.e., not a PLINK file).
#'                                This matrix must have one column that is an ID column; all other columns aside the ID will be used as covariates in the design matrix. Columns must be named.
#' @param predictor_id            Optional (for PLINK data only): A string specifying the name of the column in 'add_predictor' with sample IDs. **Required** if 'add_predictor' is supplied.
#'                                The names will be used to subset and align this external covariate with the supplied PLINK data.
#' @param unpen                   Optional (for delimited file data only): an optional character vector with the names of columns to mark as unpenalized (i.e., these features would always be included in a model).
#'                                **Note**: if you choose to use this option, X must have column names.
#' @param overwrite               Logical: should existing .rds files be overwritten? Defaults to FALSE.
#' @param logfile                 Optional: name of the '.log' file to be written -- **Note:** do not append a `.log` to the filename; this is done automatically.
#' @param quiet                   Logical: should messages to be printed to the console be silenced? Defaults to FALSE
#'
#' @returns A file path to the RDS object which holds the pointer to the newly created data matrix as well as a list of meta-data
#'
#' @export
#'
create_design_wo_std <- function(data_file,
                                 rds_dir,
                                 new_file,
                                 add_outcome,
                                 outcome_id,
                                 outcome_col,
                                 na_outcome_vals = c(-9, NA_integer_),
                                 feature_id = NULL,
                                 add_predictor = NULL,
                                 predictor_id = NULL,
                                 unpen = NULL,
                                 logfile = NULL,
                                 overwrite = FALSE,
                                 quiet = FALSE){

  obj <- readRDS(data_file)

  # check for input errors ----------------------------------------

  if (any(add_outcome[, outcome_col] %in% na_outcome_vals)) {
    stop("It appears that you have some missing values in the outcome data.
         Please remove these samples; missing values are not permitted in the design.")
  }

  if (is.null(colnames(add_outcome))) {
    stop("The columns of 'add_outcome' must be named.")
  }

  if (grepl(pattern = "fold", x = new_file, fixed = TRUE)) {
    warning("The string 'fold' is a keyword that is used to create intermediate files in cv_plmm().
            If you call cv_plmm() on this design, there is a big possiblity that you will lose files unintentionally.
            I recommend you either (1) choose a different 'new_file' name (best option) or (2)
            double check that the folder where you will save your results from
            downstream analysis is not the same folder where you are saving this design.")
  }

  # additional checks for case where add_predictor is specified
  if (!is.null(add_predictor)) {

    if (is.null(predictor_id)) {
      stop("If add_predictor is specified, the user must also specify predictor_id.")
    }

    if (is.null(colnames(add_predictor))) {
      stop("The columns of 'add_predictor' must be named.")
    }

    if (anyNA(add_predictor[,])) {
      stop("It appears that there are missing values in the predictor data.
         Please remove these samples; missing values are not permitted in the design.")
    }

    if (!identical(add_outcome[, outcome_id], add_predictor[, predictor_id])) {
      stop("Something is off in the supplied outcome and/or predictor data.
         Make sure the indicated ID columns are character type, represent the same samples, and have the same order.
           Note: 'create_design()' will align the two external data items (outcome and predictors) with
           the PLINK data. It is your responsibility to align the external data items with each other.\n")
    }

  }

  # initial setup --------------------------------------------------
  existing_files <- list.files(rds_dir)

  if (!is.null(logfile)) {
    logfile <- file.path(rds_dir, logfile)
  }

  logfile <- plmmr:::create_log(outfile = logfile)

  # create list to be returned
  design <- list()

  # check for files to be overwritten---------------------------------
  if (overwrite) {

    # remove files with name pattern
    to_remove <- paste0(file.path(rds_dir, new_file), c(".bk", ".rds", ".desc"))
    if (any(file.exists(to_remove))) {
      file.remove(to_remove)
    }

    # check for left over intermediate files
    if (file.exists(file.path(rds_dir, "unstd_design_matrix.bk"))) {
      file.remove(c(file.path(rds_dir, "unstd_design_matrix.bk"),
                    file.path(rds_dir, "unstd_design_matrix.desc")))
    }


  }

  # attach the processed data -------------------------------
  obj$X <- bigmemory::attach.big.matrix(obj$X)

  # flag for data coming from plink
  is_plink <- inherits(obj, "processed_plink")

  # determine which IDs to use ---------------------------------
  if (is.null(feature_id)) {
    if (!quiet) cat("No feature_id supplied; will assume data X are in same row-order as add_outcome.\n")
    cat("No feature_id supplied; will assume data X are in same row-order as add_outcome.\n",
        file = logfile, append = TRUE)
  } else if (length(feature_id) == 1) {
    if (feature_id == "IID") {
      indiv_id <- "sample.ID"
      og_ids <- as.character(obj$fam[, indiv_id])

    } else if (feature_id == "FID") {
      indiv_id <- "family.ID"
      og_ids <- as.character(obj$fam[, indiv_id])

    }
  } else if (length(feature_id) == nrow(obj$X)) {
    if (!inherits(feature_id, "character")) feature_id <- as.character(feature_id)
    og_ids <- feature_id
  } else {
    stop("The feature_id argument is misspecified (see documentation for options).")
  }

  # check for any duplicated row IDs, if applicable
  # TODO: update this syntax not to use 'exists()'
  if (exists("og_ids") && anyDuplicated(og_ids)) stop("Duplicated feature_id values detected.\n")

  # save these original dim names
  if (is_plink) {
    design$X_colnames <- obj$colnames <- obj$map$marker.ID
  } else {
    design$X_colnames <- colnames(obj$X)
  }

  if (exists("og_ids")) {
    design$X_rownames <- og_ids
  } else {
    design$X_rownames <- paste0("row", seq_len(nrow(obj$X)))
  }


  # save colnames of add_predictor (if supplied)
  if (is.null(colnames(add_outcome))) {
    stop("The matrix supplied to add_outcome must have column names.")
  }


  # save original dimensions
  design$n <- obj$n
  design$p <- obj$p # Note: p = # of features, not including any additional predictors!

  # note whether data are from PLINK
  design$is_plink <- is_plink

  # index samples for subsetting ------------
  # Note: this step uses the outcome (from external file) to determine which
  #   samples/observations should be pruned out; observations with no feature
  #   data will be removed from analysis
  if (exists("og_ids")) {
    sample_idx <- plmmr:::index_samples(obj = obj,
                                rds_dir = rds_dir,
                                indiv_id = og_ids,
                                add_outcome = add_outcome,
                                outcome_id = outcome_id,
                                outcome_col = outcome_col,
                                na_outcome_vals = na_outcome_vals,
                                outfile = logfile,
                                quiet = quiet)

    # save items to return
    design$outcome_idx <- sample_idx$outcome_idx # save indices of which rows in the feature data should be included in the design
    design$y <- sample_idx$complete_samples[, outcome_col, with = FALSE] |> unlist()
    design$std_X_rownames <- sample_idx$complete_samples$ID
  } else {
    # save items to return
    design$outcome_idx <- plmmr:::seq_len(nrow(obj$X))
    design$y <- unlist(add_outcome[, outcome_col])
    design$std_X_rownames <- design$X_rownames
  }

  gc()

  # align IDs between feature data and external data -------------------------
  if (!is.null(add_predictor)) {
    if (is.null(predictor_id)) {
      stop("If add_predictor is supplied, the predictor_id argument must also be supplied")
    }
    aligned_add_predictor <- plmmr:::align_ids(id_var = predictor_id,
                                       quiet = quiet,
                                       add_predictor = add_predictor,
                                       og_ids = og_ids)
    gc()
    # add predictors from external files --------------------------------------
    unstd_X <- plmmr:::add_predictors(obj = obj,
                              add_predictor = aligned_add_predictor,
                              id_var = feature_id,
                              rds_dir = rds_dir,
                              quiet = quiet)
    # save items to return
    design$unpen <- unstd_X$unpen # save indices for unpenalized covariates
    design$unpen_colnames <- setdiff(colnames(add_predictor), predictor_id)
    gc()
  } else {
    # make sure 'unpen' was not specified by mistake
    if (is_plink && !is_plink) stop("The 'unpen' argument is only for matrix data or delimited file data.
                                   To create unpenalized covariates with PLINK file data,
                                   see the documentation for the 'add_predictor' argument.")

    if (is.null(unpen)) {
      design$unpen <- NULL
      design$unpen_colnames <- NULL
    } else {
      design$unpen <- which(design$X_colnames %in% unpen) # this will be used to index the columns which are unpenalized
      design$unpen_colnames <- unpen
    }

    unstd_X <- obj
    unstd_X$design_matrix <- obj$X
    unstd_X$colnames <- design$X_colnames
  }

  if (is_plink) {
    design$fam <- unstd_X$obj$fam
    design$map <- unstd_X$obj$map
  }

  # again, clean up to save space
  rm(obj)

  # index features for subsetting --------------------------------------------
  design$ns <- plmmr:::count_constant_features(fbm = unstd_X$design_matrix,
                                       outfile = logfile,
                                       quiet = quiet)
  gc()
  # subsetting -----------------------------------------------------------------
  subset_res <- plmmr:::subset_filebacked(X = unstd_X$design_matrix,
                                  complete_samples = design$outcome_idx,
                                  ns = design$ns,
                                  rds_dir = rds_dir,
                                  new_file = new_file,
                                  outfile = logfile,
                                  quiet = quiet)
  # clean up
  design$ns <- subset_res$ns
  design$std_X_colnames <- unstd_X$colnames[subset_res$ns]
  gc()

  # add meta data -------------------------------------------------------------
  design$penalty_factor <- c(rep(0, length(design$unpen)),
                             rep(1, ncol(subset_res$subset_X) - length(design$unpen)))

  design$subset_X <- bigmemory::describe(subset_res$subset_X)
  # cleanup -------------------------------------------------------------------
  list.files(rds_dir,
             pattern = paste0("^unstd_design.*"),
             full.names = TRUE) |> file.remove()
  gc()
  # return -------------------------------------------------------------
  saveRDS(structure(design, class = "plmm_design"),
          file.path(rds_dir, paste0(new_file, ".rds")))

  return(file.path(rds_dir, paste0(new_file, ".rds")))

}
