#!/usr/bin/env nextflow

/*
 * Import modules required for the pipeline
 */
 
include {Busco_process} from ./modules/Busco_process.nf


/*
 * Functions 
 */



/*
 * Pipeline 
 */

workflow Quality_control {
    
    take:
    protein_fasta
    seq_name

    main:
    Busco_process(protein_fasta, seq_name)

    emit:
    ${seq_name}_quality_control_report = Busco_process.out
}
