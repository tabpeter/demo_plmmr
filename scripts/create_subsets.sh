#!/bin/bash
# note: this script makes three assumptions: 
# (1) you have PLINK installed 
# (2) are in the directory where your data is located 
# (3) you have have made this file executable

# The objective of this script is to create 11 subsets of varying size 
# Note: n = number of samples, p = number of SNPs
# Note: K represents thousands in the notation for 'p'

# n = 350, p = 400K
plink --bfile qc_penncath --thin-indiv-count 350 --thin-count 400000 --make-bed --out n350_p400K

# n = 700, p = 400K
plink --bfile qc_penncath --thin-indiv-count 700 --thin-count 400000 --make-bed --out n700_p400K

# n = 1050, p = 400K
plink --bfile qc_penncath --thin-indiv-count 1050 --thin-count 400000 --make-bed --out n1050_p400K

# n = 1401, p = 400K 
plink --bfile qc_penncath --thin-count 400000 --make-bed --out n1401_p400K


# n = 350, p = 600K
plink --bfile qc_penncath --thin-indiv-count 350 --thin-count 600000 --make-bed --out n350_p600K

# n = 700, p = 600K
plink --bfile qc_penncath --thin-indiv-count 700 --thin-count 600000 --make-bed --out n700_p600K

# n = 1050, p = 600K
plink --bfile qc_penncath --thin-indiv-count 1050 --thin-count 600000 --make-bed --out n1050_p600K

# n = 1401, p = 600K 
plink --bfile qc_penncath --thin-count 600000 --make-bed --out n1401_p600K


# n = 350, p = 800K
plink --bfile qc_penncath --thin-indiv-count 350 --make-bed --out n350_p800K

# n = 700, p = 800K
plink --bfile qc_penncath --thin-indiv-count 700 --make-bed --out n700_p800K

# n = 1050, p = 800K
plink --bfile qc_penncath --thin-indiv-count 1050 --make-bed --out n1050_p800K

# n = 1401, p = 800K 
# this is the case where we will use the entire data set 


