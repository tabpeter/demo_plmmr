#!/bin/bash
# note: this script makes three assumptions: 
# (1) you have PLINK installed 
# (2) are in the directory where your data is located 
# (3) you have have made this file executable

# First step: run make-bed by itself to address this error: 
# Error: .bim file has a split chromosome.  Use --make-bed by itself to
# remedy this.
plink --bfile penncath --make-bed --out penncath_clean

# Next step: implement the QC steps and add phenotype info from meta-data file
plink  --autosome \
--bfile penncath_clean \
--geno 0.1 \
--hwe 1e-10 \
--maf 0.01 \
--make-bed \
--mind 0.1 \
--out qc_penncath