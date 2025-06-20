# Purpose

The purpose of this repository is to create an extended demonstration of the [`plmmr`](https://github.com/pbreheny/plmmr) package. The focus here is assessing the performance of `plmmr` for real data sets of varying size.

This demonstration uses data from the [PennCATH study](https://pubmed.ncbi.nlm.nih.gov/21239051/) of genetic risk factors for coronary artery disease. You may download the publicly-available data from one of the following sources (the contents are the same):

-   [Data (zip)](https://d1ypx1ckp5bo16.cloudfront.net/penncath/penncath.zip): for Windows users

-   [Data (tar)](https://d1ypx1ckp5bo16.cloudfront.net/penncath/penncath.tar.gz): for Mac/Linux users

Once downloaded, you will need to unzip/untar the data into the folder of your choice. Throughout the tutorial, I will assume that the unzipped data files are in a folder called 'data'; if you store them somewhere else, you will need to change the directory references.

# TL;DR

Here are the results for the computational time needed to fit a penalized linear mixed model with `plmmr`; $n$ is the number of observations (e.g., samples) and $p$ is the number of features (e.g., variants). All computations were run on a laptop using a single core.

![](figures/total_time.png)

# Structure

This demonstration is structured in the following way:

-   the 'scripts' folder contains the code used to analyze the data/fit the models.

-   the 'R' folder has the R functions I wrote to run the analysis and synthesize results.

I also have two private folders on my computer, called 'data' and 'results'. My 'data' folder has all the PLINK data files (.bed/.bim/.fam) as well as the .csv file of meta-data. My 'results' folder has the .rds/.bk files with the objects returned by our model fitting process. These two folders are too large to include in the GitHub site. By making this repository public, my goal is to ensures the reproducibility and transparency of my work. The publicly available data & scripts allow users/readers to follow along with this demonstration and compare their results with the ones shown in my graphs. I welcome user feedback (via pull requests and/or issues).

## Scripts

The order and purpose of each script is as follows:

-   `qc.sh` documents what I did to clean the data, using [PLINK 1.9](https://www.cog-genomics.org/plink/1.9/) and R 4.4.1.

-   `create_subsets.sh` documents how I created the subsets of data of varying numbers of features (i.e., SNPs) and observations (i.e., samples)

-   `save_timestamps.R` creates an RDS object that stores the run times for each model fit

-   `run_all_analyses.R` fits models for all combinations of $n$ and $p$. Results are saved to the RDS object in the 'results' subfolder.

-   `get_eigen_times.R` and `get_plmm_fit_time.R` both extract time stamps from the log files of each model fit. The goal here was to break down how much time is spent in the eigendecomposition step as compared to how much time is spend in the actual model fitting.

-   `fig.R` has the code I used for creating figures

# References

-   For tutorial-style explanations of how to use plmmr, check out the [documentation website](https://pbreheny.github.io/plmmr/articles/getting-started.html#data-input-types). There are several data sets that 'ship' with the package, and the documentation website has a vignette that covers each of these data sets.

-   For more hands-on experience with GWAS data, check out [this other tutorial](https://pbreheny.github.io/adv-gwas-tutorial/index.html).

-   For details on the notation I use (e.g., in the comments within scripts), see this [note on notation](https://pbreheny.github.io/plmmr/articles/notation.html).
