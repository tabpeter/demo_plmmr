#!/bin/bash
# note: this script makes three assumptions: 
# (1) you have PLINK installed 
# (2) are in the directory where your data is located 
# (3) you have have made this file executable

# The objective of this script is to create subsets of varying size 
# Note: n = number of samples, p = number of SNPs
# Note: K represents thousands in the notation for 'p'

# n = 350, p = 400K
plink --bfile qc_penncath --thin-indiv-count 350 --thin-count 400

# n = 700, p = 400K

# n = 1050, p = 400K

# n = 1401, p = 400K 



# n = 350, p = 600K

# n = 700, p = 600K

# n = 1050, p = 600K

# n = 1401, p = 600K 


# n = 350, p = 800K

# n = 700, p = 800K

# n = 1050, p = 800K

# n = 1401, p = 800K 


