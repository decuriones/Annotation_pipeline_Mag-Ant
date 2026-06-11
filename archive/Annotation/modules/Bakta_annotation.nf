#!/usr/bin/env nextflow

/*
 * Bakta annotation pipeline
 */

process Bakta_annotation {
    
    errorStrategy 'ignore'

    input:
    tuple val(seq_name), val(seq) 
    val genus
    val project

    output:
    tuple val (seq_name) ,path ("${seq_name}_bakta_annotation")
    

    script:
    // store only the genus value (or empty string) — build the shell flag later
    def genus_opt = genus ? "${genus}" : ""
    """
    mkdir -p "\$PWD/${seq_name}_bakta_annotation"
    echo "processing ${seq} with genus ${genus} for project ${project}"
    echo "\$PWD"
    module load apptainer
    GENUS="${genus_opt}"
    genus_bsh="\${GENUS#g__}"      # remove GTDB prefix if present
    if [ "\$genus_bsh" == "Escherichia" ] || [ -z "\$genus_bsh" ]; then
        apptainer exec -C \
                    --bind /home/elouanln/scratch/Sandbox/fulldb_bakta/db:/bakta_db \
                    --bind "/\$( dirname "${seq}")":"/data" \
                    --bind "\$PWD/${seq_name}_bakta_annotation":"/outdir" \
                    /lustre06/project/6066427/software/singularity_images/Bakta_dependances/Bakta_v1-12-0.sif bakta \
                    --db /bakta_db/ \
                    -o /outdir \
                    --complete \
                    --force \
                    /data/${seq.name}
    else
        apptainer exec -C \
                    --bind /home/elouanln/scratch/Sandbox/fulldb_bakta/db:/bakta_db \
                    --bind "/\$( dirname "${seq}")":"/data" \
                    --bind "\$PWD/${seq_name}_bakta_annotation":"/outdir" \
                    /lustre06/project/6066427/software/singularity_images/Bakta_dependances/Bakta_v1-12-0.sif bakta \
                    --db /bakta_db/ \
                    --genus "\${genus_bsh}" \
                    -o /outdir \
                    --complete \
                    --force \
                    /data/${seq.name}
    fi
    """
}