#!/usr/bin/env nextflow

/*
 * Bakta annotation pipeline
 */

process Bakta_annotation {

    input:
    path seq
    val genus
    val project

    output:
    path "${seq.simpleName}_bakta_annotation"

    script:
    // store only the genus value (or empty string) — build the shell flag later
    def genus_opt = genus ? "${genus}" : ""
    
    """
    echo "processing ${seq} with genus ${genus} for project ${project}"
    module load apptainer
    GENUS="${genus_opt}"
    genus_bsh="\${GENUS#g__}"      # remove GTDB prefix if present
    if [ "\$genus_bsh" == "Escherichia" ] || [ -z "\$genus_bsh" ]; then
        apptainer exec -C \
                    --bind /home/elouanln/scratch/Sandbox/fulldb_bakta/db:/bakta_db \
                    --bind "/\$( dirname \"${seq}\" ):/data" \
                    /lustre06/project/6066427/software/singularity_images/Bakta_dependances/Bakta_v1-12-0.sif bakta \
                    --db /bakta_db/version.json \
                    -o ${seq.simpleName}_bakta_annotation \
                    --complete \
                    --force \
                    /data/\$(basename \"${seq}\")
    else
        apptainer exec -C \
                    --bind /home/elouanln/scratch/Sandbox/fulldb_bakta/db:/bakta_db \
                    --bind "/\$( dirname \"${seq}\" ):/data" \
                    /lustre06/project/6066427/software/singularity_images/Bakta_dependances/Bakta_v1-12-0.sif bakta \
                    --db /bakta_db/version.json \
                    --genus "\${genus_bsh}" \
                    -o ${seq.simpleName}_bakta_annotation \
                    --complete \
                    --force \
                    /data/\$(basename \"${seq}\")
    fi
    """
}