#!/usr/bin/env nextflow

/*
 * Import modules required for the pipeline
 */
 
include {Busco_process} from "./modules/Busco_process.nf"


/*
 * Functions 
 */



/*
 * Pipeline 
 */

workflow Quality_control {
    
    take:
    lineage_db
    protein_fasta
    seq_name

    main:
    Busco_process(lineage_db, protein_fasta, seq_name)

    emit:
    quality_report = Busco_process.out
}
