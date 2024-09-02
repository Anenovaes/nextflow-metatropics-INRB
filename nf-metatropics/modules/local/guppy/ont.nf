process GUPPY_ONT {
    label 'process_long'

    // Select container based on container engine
    container "${ workflow.containerEngine == 'singularity' ?
        '$projectDir/images/guppy.sif' :
        'daanjansen94/guppy:v6.5.7' }"

    // Set container options for Docker and Singularity
    containerOptions {
        if (workflow.containerEngine == 'singularity') {
            return '--nv'
        } else if (workflow.containerEngine == 'docker') {
            return '--gpus all --rm'
        } else {
            return null
        }
    }

    input:
    path inputF

    output:
    path "pass", emit: basecalling_ch
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    guppy_basecaller \
        -i $inputF \
        -s ${params.outdir} \
        -c ${params.model} \
        --chunks_per_runner 160 \
        --gpu_runners_per_device 4 \
        -x "auto"

    mv $params.outdir/pass pass

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        guppy_basecaller: \$(echo \$(guppy_basecaller --version) | head -n 1| perl -p -e 's/.+Version //g' | cut -d ',' -f1)
    END_VERSIONS
    """
    }
