include { Viral_and_plamsid_check } from './Plasmids_Viral_check/Viral_and_plamsid_check.nf'
include { Annotation_pipeline } from './Annotation/Annotation_pipeline.nf'
include { Quality_control } from './Quality_control/Quality_control.nf'
// include validation module here when it will be ready

Workflow {

    log.info """
    ╔════════════════════════════════════════════════════╗
    ║   # Input summary                                  ║
    ║   Pipeline: ${params.project_name}                 ║
    ║   Input: ${params.seq_list}                        ║
    ║                                                    ║
    ║   # Tools exectued                                 ║
    ║   Annotation_tool: ${params.annotation_tool}       ║
    ║   Viral_Verify: ${params.viral_verify}             ║
    ║   Antismash: ${params.antismash}                   ║
    ║   *********: ${params.antismash}                   ║
    ║   *********: ${params.antismash}                   ║
    ╚════════════════════════════════════════════════════╝
        """
    // Modify the seq list to readable format for the pipeline
    seq_input = params.seq_list instanceof String ? params.seq_list.replaceAll(/^\[|\]$/, '').split(/\s*,\s*/).findAll { it } : params.seq_list
    
    seq_ch = Channel.fromPath(seq_input)
                      .flatten()
                      .map { seq -> tuple(seq.simpleName, seq) }
                      .view { seq_name, seq -> "Input sequences: $seq_name -> $seq" }
    
    seq_ch = Channel.fromPath(seq_input)
                      .flatten()
                      .view { seq -> "Input sequences: $seq" }
    seq_with_name = seq_ch.map { seq -> tuple(seq.simpleName, seq) }

    annotation_step = Annotation_pipeline (
        seq_input: seq_input
    )

    viral_check = Viral_and_plamsid_check (
        seq_input: seq_input
    )



    
    
    publish:
    // Annotation output
    Annotation = annotation_step.Annotation
    Taxonomy = annotation_step.Taxonomy
    Secondary_metabolites = annotation_step.Secondary_metabolites

    // Viral check and geNomad output
    Collection_results = viral_check.Collection_results
    Summary_tables = viral_check.Summary_tables
}

output {
    Collection_results {
        path "Output/${params.project}_collection_results.tsv"
        mode "copy"
    }
    Summary_tables {
        path "Output/${params.project}_summary_tables"
        mode "copy"
    }
    Taxonomy {
        path "Output/Taxonomy"
        mode "copy"
    }
    Annotation {
        path "Output/Annotation_${params.project}/${params.annotation_tool}_annotation_${params.project}"
        mode "copy"
    }
    Secondary_metabolites {
        path "Output/Secondary_metabolites_${params.project}"
        mode "copy"
    }

}
