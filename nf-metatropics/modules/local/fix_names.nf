process FIX_NAMES {

    tag{sample}

    input:
    tuple val(meta), val(sample), path(reads)

    output:
    tuple val(sample), path("*.fastq.gz"), emit : fqreads

    script:
    """
    if [[ $params.basecall == "true" ]]; then
        cat $reads/* > ${sample}.fastq && gzip ${sample}.fastq

    elif [[ $params.basecall == "false" ]]; then
        cat $reads > ${sample}.fastq && gzip ${sample}.fastq
    fi
    """
}
