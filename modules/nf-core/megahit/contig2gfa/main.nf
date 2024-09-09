process MEGAHIT_CONTIG2GFA {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/megahit_pigz:657d77006ae5f222' :
        'community.wave.seqera.io/library/megahit_pigz:87a590163e594224' }"

    input:
    tuple val(meta), path(megahit_contigs)

    output:
    tuple val(meta), path("${prefix}.graph.fastg.gz")   , emit: fastg
    tuple val(meta), path("${prefix}.gfa.gz")           , emit: gfa
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args            = task.ext.args ?: ''
    def args2           = task.ext.args2 ?: ''
    def is_compressed   = megahit_contigs.getExtension() == "gz" ? true : false
    def contigs_name    = is_compressed ? megahit_contigs.getBaseName() : megahit_contigs
    prefix              = task.ext.prefix ?: "${meta.id}"
    """
    # decompress megahit_contigs if compressed
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${megahit_contigs} > ${contigs_name}
    fi

    # identify kmer size used to create assemblies
    kmer_size=\$(grep "^>" ${contigs_name} | sed 's/>k//; s/_.*//' | head -n 1)

    # convert contigs to FastG format
    megahit_toolkit \\
        contig2fastg \\
        \$kmer_size \\
        ${contigs_name} > ${prefix}.graph.fastg

    # convert FastG to GFA format
    fastg2gfa \\
        ${prefix}.graph.fastg > ${prefix}.gfa

    gzip ${prefix}.gfa ${prefix}.graph.fastg

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit: \$(echo \$(megahit -v 2>&1) | sed 's/MEGAHIT v//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def is_compressed   = megahit_contigs.getExtension() == "gz" ? true : false
    def contigs_name    = is_compressed ? megahit_contigs.getBaseName() : megahit_contigs
    prefix              = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.graph.fastg.gz
    echo "" | gzip > ${prefix}.gfa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        megahit: \$(echo \$(megahit -v 2>&1) | sed 's/MEGAHIT v//')
    END_VERSIONS
    """
}
