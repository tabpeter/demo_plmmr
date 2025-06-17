rule penncath:
    output:
        "data/qc_penncath.bed"
    shell:
        """
        wget https://d1ypx1ckp5bo16.cloudfront.net/penncath/penncath.tar.gz
        tar -xvf penncath.tar.gz
        rm penncath.tar.gz
        cp scripts/qc.sh data
        cd data && ./qc.sh
        """

rule subsets:
    input:
        "data/qc_penncath.bed"
    output:
        "data/n700_p700K.bed"
    shell:
        """
        cp scripts/create_subsets.sh data
        cd data && ./create_subsets.sh
        """
