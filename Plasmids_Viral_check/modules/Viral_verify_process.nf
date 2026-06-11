#!/usr/bin/env nextflow

/*
 * Viral verify process for detection of viral and plasmids sequences
 */

process Viral_verify_process {

    input:
    tuple val(seq_name), path(seq)
    val project

    output:
    tuple val(seq_name), path("${seq_name}_viral_verified_${project}") 
    
    script:
    """
    module load StdEnv/2023 prodigal/2.6.3 hmmer/3.4
    source /home/elouanln/scratch/Sandbox/Test_ground/Test_viral_verify/VENV_viral_verify/bin/activate
    viral_verify -i ${seq} \
    -o ./"${seq_name}_viral_verified_${project}" \
    -H /home/elouanln/scratch/Pfam_db_v38.1_hmm/Pfam-A.hmm     
    """
}