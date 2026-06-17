#!/usr/bin/env nextflow


/*
 * Busco process to assess quality and check for genome completeness
 */

process Busco_process {
    module 'java/21.0.1'
    input:
    val busco_lineage
    val protein_fasta
    val seq_name

    output:
    path "Busco_output_${seq_name}" 
    
    script:
    '''
    # Load modules dependencies.
    module load StdEnv/2023 gcc python/3.11 augustus/3.5.0 hmmer/3.4 blast+/2.17.0 metaeuk/7 prodigal/2.6.3 r bbmap/39.06 java/17.0.6

    # if possible always use
    if [ ${busco_lineage} == "Cyanobacteria_odb12" ]; then
        DB_path="/home/elouanln/Busco/Busco_db/busco_db_cyanobacteria_odb12/busco_downloads/lineages/cyanobacteriota_odb12"
    elif [ ${busco_lineage} == "Bacteria_odb12" ]; then
        DB_path="/home/elouanln/Busco/Busco_db/busco_db_bacteria_odb12/busco_downloads/lineages/bacteria_odb12"
    elif [ ${busco_lineage} == *odb* ]; then
        if [[ -n $(find "/home/elouanln/Busco/Busco_db/ -type d -name ${busco_lineage}" )]]; then
            DB_path="/home/elouanln/Busco/Busco_db/busco_db_${busco_lineage}/busco_downloads/lineages/${busco_lineage}"
        else
            DB_path="${busco_lineage}"
        fi
    else
        echo "Lineage not recognized. Please check the lineage name and try again."
        exit 1
    fi

    if [ ! -d "/home/elouanln/Busco/Busco_env" ]; then
        virtualenv --no-download /home/elouanln/Busco/Busco_env
        source /home/elouanln/Busco/Busco_env/bin/activate
        pip install --no-index --upgrade pip
        pip install --no-index --requirement /home/elouanln/Busco/busco-requirements.txt
    else
        source /home/elouanln/Busco/Busco_env/bin/activate

    fi
    
    busco --offline \
    --in ${protein_fasta} \
    --out Busco_output_${seq_name} \
    --lineage_dataset ${DB_path} \
    --mode protein \
    --download_path /home/elouanln/Busco/Busco_db


    '''
}