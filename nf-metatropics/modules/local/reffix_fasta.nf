process REFFIX_FASTA {
    tag "${meta.id}.${meta.virus}"

    input:
    tuple val(meta), path(fastaref)

    output:
    tuple val(meta), path("*.fasta"), emit : fixedseqref

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.virus}"
    """
    perl -p -e 's/\\||:/_/g' $fastaref > ${meta.virus}.fasta
    """
}
