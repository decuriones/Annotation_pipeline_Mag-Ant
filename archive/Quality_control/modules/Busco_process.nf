#!/usr/bin/env nextflow


/*
 * Busco process to assess quality and check for genome completeness
 */

process Busco_process {

    input:
    val busco_lineage
    val protein_fasta
    val seq_name

    output:
    path "Busco_output_${seq_name}" 
    
    script:
    """
    module load  apptainer

    echo "Starting Busco analysis for ${seq_name} with lineage ${busco_lineage}..."
    # if possible always use
    if [ ${busco_lineage} == "Cyanobacteria_odb12" ]; then
        DB_path="/home/elouanln/Busco/Busco_db/busco_db_cyanobacteria_odb12/lineages/cyanobacteriota_odb12"
    elif [ ${busco_lineage} == "Bacteria_odb12" ]; then
        DB_path="/home/elouanln/Busco/Busco_db/busco_db_bacteria_odb12/lineages/bacteria_odb12"
    elif [[ ${busco_lineage} == *odb* ]]; then
        if [[ -n \$(find "/home/elouanln/Busco/Busco_db/" -type d -name "${busco_lineage}" ) ]]; then
            DB_path="/home/elouanln/Busco/Busco_db/busco_db_${busco_lineage}/lineages/${busco_lineage}"
        else
            DB_path="${busco_lineage}"
        fi
    else
        echo "Lineage not recognized. Please check the lineage name and try again."
        exit 1
    fi
    echo "Using Busco lineage dataset: \$DB_path"
    
    apptainer exec /home/elouanln/projects/def-jcomte/software/singularity_images/busco_v6-0-0.sif busco --offline \
    --in ${protein_fasta} \
    --out Busco_output_${seq_name} \
    --lineage_dataset \$DB_path \
    --mode protein \
    --download_path /home/elouanln/Busco/Busco_db
    """
}