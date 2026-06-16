#!/usr/bin/env nextflow

/*
 * AntiSmash annotation pipeline
 */

process Antismash_annotation {

    //errorStrategy 'ignore'

    input:
    val(seq_name)
    path(nucleotide_file)
    path(gff3_file)
    val project

    output:
    tuple val(seq_name), path("${seq_name}_antismash_out_${project}")

    script:
    """
    # Cleaning up any existing overlay for the current project and sequence
    rm -f "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img"
    # Importing apptainer and creating an overlay for the current project and sequence
    module load apptainer
    mkdir -p "$SCRATCH/apptainer_overlays"
    apptainer overlay create --size 8192 "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img"
    
    # Resolving symbolic issues
    nucl_seq=\$(readlink -f "${nucleotide_file}")
    gff3_seq=\$(readlink -f "${gff3_file}")
    echo "Nucleotide file for Antismash input: \$nucl_seq"
    echo "GFF3 file for Antismash input: \$gff3_seq"

    # Antismash execution
    apptainer exec --env PYTHONNOUSERSITE=1 --overlay "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img" /home/elouanln/projects/def-jcomte/software/singularity_images/antismash_galaxy/antismash_v8-0-4.sif antismash \
    --output-dir ./"${seq_name}_antismash_out_${project}" \
    --genefinding-tool prodigal \
    --databases /home/elouanln/scratch/antismash_db/db/ \
    --cc-mibig --cb-knownclusters --smcog-trees \
    \$nucl_seq
    
    # Cleaning up the overlay after execution
    rm -f "$SCRATCH/apptainer_overlays/antismash_${project}_${seq_name}_rw.img"
    """

}
