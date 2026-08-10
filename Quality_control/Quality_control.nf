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
    busco_input          // tuple(seq_name, protein_fasta)

    main:
    Busco_process(lineage_db, busco_input)

    emit:
    quality_report = Busco_process.out
}
