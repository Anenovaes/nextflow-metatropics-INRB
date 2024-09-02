process MAFFT_ALIGN {
    tag "$meta.virus"
    label 'process_single'

    conda "bioconda::mafft=7.520"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mafft%3A7.520--hec16e2b_1':
        'quay.io/biocontainers/mafft' }"

    input:
    tuple val(meta), path(fastas)
    //tuple val(meta), path(fastas, stageAs: "?/*")
    path(references)

    output:
    tuple val(meta), path("*.aln"), emit: aln
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.virus}"
    //def input_str = fastas instanceof List ? fastas.join(" ") : fastas
    //cat *.fasta > temp.fasta
    """
    cat $references/${meta.virus}.fasta *.fasta > ${prefix}.fasta
    mafft --retree 1 ${prefix}.fasta > ${prefix}.aln

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mafft: \$(echo \$(mafft --version >&1))
    END_VERSIONS
    """
}


