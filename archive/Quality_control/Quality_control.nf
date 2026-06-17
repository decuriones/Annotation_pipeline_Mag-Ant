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
    Busco_process(params.busco_lineage,params.protein_fasta, params.seq_name)

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