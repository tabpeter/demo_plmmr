rule all:
    input:
        "data/.subsets.complete",
        "data/bladder-cancer.rds"

rule penncath:
    output:
        "data/qc_penncath.bed"
    shell:
        """
        wget https://d1ypx1ckp5bo16.cloudfront.net/penncath/penncath.tar.gz
        tar -xvf penncath.tar.gz
        rm penncath.tar.gz
        cp scripts/obj1-scaling/qc.sh data
        cd data && ./qc.sh
        """

rule subsets:
    input:
        "data/qc_penncath.bed"
    output:
        "data/.subsets.complete"
    shell:
        """
        cp scripts/obj1-scaling/create_subsets.sh data
        cd data && ./create_subsets.sh
        cd .. && touch {output}
        """

rule bladder:
    output:
        "data/bladder-cancer.rds"
    shell:
        """
        Rscript -e 'if (!all(sapply(c("affy", "genefilter"), requireNamespace, quietly=TRUE))) stop("Missing required R packages: affy and/or genefilter", call.=FALSE)'
        mkdir -p data
        cd data
        curl -L -OJ https://ndownloader.figshare.com/files/4862323
        tar -xvf bladdercels.tgz
        rm bladdercels.tgz
        cd ..
        Rscript scripts/obj2-gene-expression/bladder-process.R
        """
