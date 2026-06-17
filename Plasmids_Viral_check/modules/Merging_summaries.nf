#!/usr/bin/env nextflow

/*
 * Summarizing results from geNOMAD and viral verify then merging them
 */

process Merging_summaries {

    input:
    tuple val(seq_name), path(geNomad_summary_plasmids), path(geNomad_summary_viruses), path(viral_verify_summary)
    val project

    output:
    path("*.csv")

    script:
    """
    module load python
    source /home/elouanln/scratch/Sandbox/VenV/bin/activate
    python "/home/elouanln/projects/def-jcomte/elouanln/Sandbox/Code/Annotation/Complete_pipeline/Plasmids_Viral_check/bin/Summarize_&_merge.py" \
    --geNomad_v ${geNomad_summary_viruses} \
    --geNomad_p ${geNomad_summary_plasmids} \
    --viral_verify ${viral_verify_summary} \
    --out_v ./"viruses_summary_${project}.csv" \
    --out_p ./"plasmid_summary_${project}.csv" \
    """
}