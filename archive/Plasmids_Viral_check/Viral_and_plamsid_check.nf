#!/usr/bin/env nextflow

/*
 * Import modules required for the pipeline
 */
 
include { Viral_verify_process } from '/lustre06/project/6066427/elouanln/Sandbox/Code/Annotation/Complete_pipeline/Plasmids_Viral_check/modules/Viral_verify_process.nf'
include { GeNOMAD_process } from '/lustre06/project/6066427/elouanln/Sandbox/Code/Annotation/Complete_pipeline/Plasmids_Viral_check/modules/geNOMAD_process.nf'
include { Merging_summaries } from '/lustre06/project/6066427/elouanln/Sandbox/Code/Annotation/Complete_pipeline/Plasmids_Viral_check/modules/Merging_summaries.nf'


/*
 * Pipeline 
 */

workflow Viral_and_plamsid_check {
    take:
    seq_input = params.seq_list instanceof String ? params.seq_list.replaceAll(/^\[|\]$/, '').split(/\s*,\s*/).findAll { it } : params.seq_list

    main:
    
    seq_ch = Channel.fromPath(seq_input)
                      .flatten()
                      .map { seq -> tuple(seq.simpleName, seq) }
                      .view { seq_name, seq -> "Input sequences: $seq_name -> $seq" }
    
    GeNOMAD_process(seq_ch, params.project) 
    if (params.viral_verify) {
        Viral_verify_process(seq_ch, params.project)
    }
    GeNomad_summary_plasmids = GeNOMAD_process.out
                                     .map { seq_name, geNomad_out -> tuple(seq_name, file("${geNomad_out}/${seq_name}_summary/${seq_name}_plasmid_summary.tsv")) }

    GeNomad_summary_viruses = GeNOMAD_process.out
                                     .map { seq_name, geNomad_out -> tuple(seq_name, file("${geNomad_out}/${seq_name}_summary/${seq_name}_virus_summary.tsv")) }
    
    Viral_verify_summary = Viral_verify_process.out
                                               .map { seq_name, viralVerify_out -> tuple(seq_name, file("${viralVerify_out}/${seq_name}-results.csv")) }

    Merged_summaries = GeNomad_summary_plasmids
        .join(GeNomad_summary_viruses, by: 0)
        .join(Viral_verify_summary, by: 0)


    publish:
    Collection_results = GeNOMAD_process.out.combine(Viral_verify_process.out)
    Summary_tables = Merging_summaries(Merged_summaries, params.project)
}

/*
 * Pipeline outputs
 */

output {
    Collection_results {
        path "Output/${params.project}_collection_results.tsv"
        mode "copy"
    }
    Summary_tables {
        path "Output/${params.project}_summary_tables"
        mode "copy"
    }
}
