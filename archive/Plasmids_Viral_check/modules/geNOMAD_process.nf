#!/usr/bin/env nextflow

/*
 * geNOMAD process for detection of viral and plasmids sequences
 */

process GeNOMAD_process {

    input:
    tuple val(seq_name), path(seq)
    val project

    output:
    tuple val(seq_name), path("${seq_name}_genomad_out_${project}")

    script:
    """
    module load apptainer
    apptainer exec /lustre06/project/6066427/software/singularity_images/genomad:1.12.0--pyhdfd78af_0 genomad end-to-end \
    --cleanup \
    ${seq} \
    ./"${seq_name}_genomad_out_${project}" \
    --min-virus-marker-enrichment 1 \
    /home/elouanln/projects/def-jcomte/elouanln/DB_geNomad/genomad_db
    """
}