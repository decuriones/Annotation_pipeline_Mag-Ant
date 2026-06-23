#!/usr/bin/env nextflow

/*
 * Import modules required for the pipeline
 */
 
include {Busco_process} from './modules/Busco_process.nf'


/*
 * Functions 
 */



/*
 * Pipeline 
 */

workflow {
    
    main:
    seq_name = params.seq_name
    protein_fasta = params.protein_fasta
    busco_lineage = params.busco_lineage

    println("${seq_name}, ${protein_fasta}, ${busco_lineage}")
    Busco_process(busco_lineage, protein_fasta, seq_name)

    publish:
    quality_report = Busco_process.out
}

/*
 * Output definition 
 */

output{
    quality_report {
        path "Output/Quality_control_${params.project}"
        mode "copy"
    }
}