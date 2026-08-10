include { Viral_and_plamsid_check } from './Plasmids_Viral_check/Viral_and_plamsid_check.nf'
include { Annotation_pipeline } from './Annotation/Annotation_pipeline.nf'
include { Quality_control } from './Quality_control/Quality_control.nf'
// include validation module here when it will be ready

/*
 * Function definition 
 */
def counting_caracter = { str ->
    str.toString().length()
    }

def adding_spaces = { str, nb_spaces ->
    return str + ' ' * nb_spaces
}

def formating_info = { info, other_caract, total_length ->
    if (info.length() >= total_length) {
        return "${info.substring(0, total_length - (5+counting_caracter(other_caract)))}...  ║"
    }
    def spaces_needed = total_length - (counting_caracter(info)+counting_caracter(other_caract))
    def formatted_info = adding_spaces(info, spaces_needed)+'║'
    return formatted_info
}
/*
 * Pipeline definition 
 */

workflow {

    log.info ($/"""
  __  __                                 _   
 |  \/  |                    /\         | |  
 | \  / | __ _  __ _ ______ /  \   _ __ | |_ 
 | |\/| |/ _` |/ _` |______/ /\ \ | '_ \| __|
 | |  | | (_| | (_| |     / ____ \| | | | |_ 
 |_|  |_|\__,_|\__, |    /_/    \_\_| |_|\__|
                __/ |                        
               |___/                         
"""/$)   

log.info ("""
    ╔════════════════════════════════════════════════════╗
    ║   # Input summary                                  ║
    ║   Project: ${formating_info("${params.project}", "   Project: ", 52)}
    ║   Input: ${formating_info("${params.seq_list}", "   Input: ", 52)}
    ║                                                    ║
    ║   # Tools exectued                                 ║
    ║   Annotation_tool: ${formating_info("${params.annotation_tool}", "   Annotation_tool: ", 52)}
    ║   Viral_Verify: ${formating_info("${params.viral_verify}", "   Viral_Verify: ", 52)}
    ║   Antismash: ${formating_info("${params.antismash}", "   Antismash: ", 52)}
    ║   Busco: ${formating_info("${params.busco}", "   Busco: ", 52)}
    ║                                                    ║
    ║   # Taxonomy                                       ║    
    ║   Taxonomy: ${formating_info("${params.tax_gtdb}", "   Taxonomy: ", 52)}
    ║   Lineage_db: ${formating_info("${params.busco}", "   Lineage_db: ", 52)}
    ╚════════════════════════════════════════════════════╝
     """)

    main:
    // Modify the seq list to readable format for the pipeline
    seq_input = file(params.seq_list).readLines().findAll { it.trim() }
    
    seq_with_name = Channel.fromPath(seq_input)
                    .flatten()
                    .map { seq -> tuple(seq.simpleName, seq) }
                    .view { seq -> "channeled sequences: $seq" }                  
    
    // input similar for both pipelines, channel of tuples (seq_name, seq_path)
    annotation_step = Annotation_pipeline (
        seq_with_name
    )

    viral_check = Viral_and_plamsid_check (
        seq_with_name
    )

    // Extracting .faa and seq files from the annotation output then starting quality control
    if (params.busco) {
    busco_input = annotation_step.Annotation
                      .map { seq_name, annotation_dir ->
                          tuple(seq_name, file("${annotation_dir}/${seq_name}.faa"))
                      }
    quality_report = Quality_control(params.busco_lineage, busco_input)
    }
    else {
        log.info "Busco annotation and quality control steps are skipped..."
        quality_report = Channel.empty()
    }   

    publish:
    // Annotation output
    Annotation = annotation_step.Annotation
    Taxonomy = annotation_step.Taxonomy
    Secondary_metabolites = annotation_step.Secondary_metabolites

    // Viral check and geNomad output
    Collection_results = viral_check.Collection_results.view { collection_results -> "collection results for viral check: $collection_results" }
    Summary_tables = viral_check.Summary_tables

    // Quality control output
    Quality_control_report = quality_report
}

output {
    Collection_results {
        path "${params.project}_collection_results"
        mode "copy"
    }
    Summary_tables {
        path "${params.project}_summary_tables"
        mode "copy"
    }
    Taxonomy {
        path "Taxonomy"
        mode "copy"
    }
    Annotation {
        path "Annotation_${params.project}/${params.annotation_tool}_annotation_${params.project}"
        mode "copy"
    }
    Secondary_metabolites {
        path "Secondary_metabolites_${params.project}"
        mode "copy"
    }
    Quality_control_report {
        path "Quality_control_${params.project}"
        mode "copy"
    }

}
