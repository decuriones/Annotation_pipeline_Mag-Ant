#!/usr/bin/env nextflow

/*
 * AntiSmash annotation pipeline
 */

process Antismash_annotation {

    input:
    val(seq_name)
    path(nucleotide_file)
    path(gff3_file)
    val project

    output:
    tuple val(seq_name), path("${seq_name}_antismash_out_${project}")

    script:
    """
    # Prevent error propagation
    set -euo pipefail

    # Importing apptainer and creating an overlay for the current project and sequence
    module load apptainer
    mkdir -p "$SCRATCH/apptainer_overlays"
    apptainer overlay create --size 8192 "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img"
 
    # Antismash execution
    apptainer exec --env PYTHONNOUSERSITE=1 --overlay "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img" /home/elouanln/projects/def-jcomte/software/singularity_images/antismash_galaxy/antismash_v8-0-4.sif antismash \
    --output-dir ./"${seq_name}_antismash_out_${project}" \
    --genefinding-gff3 ${gff3_file} \
    --databases /home/elouanln/scratch/antismash_db/db/ \
    --cc-mibig --cb-knownclusters --smcog-trees  \
    ${nucleotide_file}
    
    # Cleaning up the overlay after execution
    rm -f "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img"
    """

}