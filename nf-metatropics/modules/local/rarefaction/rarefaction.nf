process RAREFACTION {
    tag "$meta.id"
    label 'process_low'
    container "daanjansen94/bbmap:38.86"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bbmap:38.86--h1296035_0':
        'daanjansen94/bbmap:38.86' }"

    input:
    tuple val(meta), path(reads)
    val(perform_rarefaction)
    val(target_bases)

    output:
    tuple val(meta), path("*_rarefied.fastq.gz"), optional: true, emit: rarefied_reads
    path "versions.yml", emit: versions

    when:
    perform_rarefaction

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Count the number of reads
    read_count=\$(zcat ${reads} | echo \$((`wc -l`/4)))

    # Check if the number of reads is at least 100
    if [ \$read_count -ge 100 ]; then
        reformat.sh in=${reads} out=${prefix}_rarefied.fastq.gz samplebasestarget=$target_bases qin=33 ignorebadquality
    else
        echo "Sample ${meta.id} has less than 100 reads. Skipping rarefaction."
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbmap.sh --version 2>&1 | grep -o 'BBMap version [0-9.]*' | sed 's/BBMap version //')
    END_VERSIONS
    """
}
