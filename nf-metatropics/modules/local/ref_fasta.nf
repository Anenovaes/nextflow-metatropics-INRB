process REF_FASTA {
    tag "$meta.id"

    container "$projectDir/images/samtools_minimap2.sif"
    conda "bioconda::metamaps=0.1.98102e9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metamaps:0.1.98102e9--h176a8bc_0':
        'daanjansen94/minimap:v2.28' }"

    input:
    tuple val(meta), path(report), path(emreads), path(rawfastq)

    output:
    tuple val(meta), path("*.fasta"), emit : seqref
    tuple val(meta), path("*.reads"), emit : headereads
    tuple val(meta), path("*.fastq"), emit : allreads
    //tuple val(meta), stdout, emit : virusout

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    produce_fasta.pl $report $emreads $rawfastq $args
    """
}
