process SNP_COMPARE {
    tag "${meta.id}.${meta.virus}"
    label 'process_single'


    input:
    tuple val(meta), path(bam), path(bamerror), path(vcf), path(csv), path(aln)

    output:
    tuple val(meta), path("*.snps.tab"), path("*.annotated.filtered.vcf"), path("*.edited.fasta"), emit: compare

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.virus}"
    """
    snp_checker.pl $prefix $csv $bam 30 70 $vcf $aln > ${prefix}.snps.tab
    """
}
