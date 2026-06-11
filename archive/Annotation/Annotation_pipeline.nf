#!/usr/bin/env nextflow

/*
 * Import modules required for the pipeline
 */
 
include { Python_taxonomy_comparison } from './modules/Python_taxonomy_comparison.nf'
include { PGAP_annotation } from './modules/PGAP_annotation.nf'
include { Bakta_annotation } from './modules/Bakta_annotation.nf'
include { Antismash_annotation } from './modules/Antismash_annotation.nf'
////// !!!! Should incule another module to check that input sequences are correct (e.g. check that they are in fasta format, check that they are not empty, etc.) !!!! //////
// Adding a module for antismah

/*
 * Functions 
 */

// Fuction to find the gff3 file in the annotation output directory
def findGff3File(directory) {
    def gff3Files = file(directory).listFiles()
        .findAll { it.isFile() && (it.name.endsWith('.gff3') || it.name.endsWith('.gff')) }
    
    if (gff3Files.isEmpty()) {
        error("Aucun fichier .gff3 trouvé!")
    }
    
    return gff3Files[0]
}

// Fuction to find the embl or gbk file in the annotation output directory
def findEmlbFile(directory) {
    def emblFiles = file(directory).listFiles()
        .findAll { it.isFile() && (it.name.endsWith('.embl') || it.name.endsWith('.gbk')) }
    
    if (emblFiles.isEmpty()) {
        error("Aucun fichier .embl ou .gbk trouvé!")
    }
    
    return emblFiles[0]
}


/*
 * Pipeline 
 */

workflow {
    main:
    seq_input = params.seq_list instanceof String ? params.seq_list.replaceAll(/^\[|\]$/, '').split(/\s*,\s*/).findAll { it } : params.seq_list
    println "annotation_tool = ${params.annotation_tool}"

    seq_ch = Channel.fromPath(seq_input)
                      .flatten()
                      .view { seq -> "Input sequences: $seq" }
    seq_with_name = seq_ch.map { seq -> tuple(seq.simpleName, seq) }
    
    // Check if the taxonomy file is provided, if yes, run the taxonomy comparison and check
    if (params.tax_gtdb != '') {
        tax_gtdb = Channel.fromPath(params.tax_gtdb)
                        .view { tax -> "Taxonomy GTDB file: $tax" }
        seq_tax_gtdb = seq_ch.combine(tax_gtdb)
                        .view { combined -> "total input: $combined " }
                        .multiMap{ it ->
                            seq : it[0]
                            tax : it[1]
                        }                    
        
        // Python taxonomy comparison & check
        Python_taxonomy_comparison(seq_tax_gtdb
                                    .seq
                                    , seq_tax_gtdb
                                    .tax
                                    )


        // Get the genus from python out 
        genus = Python_taxonomy_comparison.out[0]
                    .splitCsv()
                    .map { row -> 
                    tuple(row[0].replaceFirst(/\.fa(sta)?$/, ''), row[1])  // (nom_séquence, genus)
                    }
                    //.collect() // Collect the results into a list
                    //.map{ genus -> genus[1]} // getting the right column with the genus name
                    .view{ genus -> "Extracted genus: $genus" }

        // Collect taxonomy results
        Taxonomy_collection = Python_taxonomy_comparison.out[0]
                                                    .collectFile(
                                                            name: "${params.project}_taxonomy.csv",
                                                            keepHeader: true,
                                                            skip: 1,
                                                            newLine: false
                                                        )
        seq_genus = seq_with_name.join(genus)
                        .view { combined -> "total input of seq and genus: $combined " }
                        .multiMap{ it ->
                            seq : it[1]
                            genus : it[2]
                        }
   
        // Run annotation based on the chosen annotation tool
        if (params.annotation_tool == 'PGAP') {

            // PGAP annotation
            PGAP_annotation(seq_genus
                            .seq
                            , seq_genus
                            .genus
                            , params.project)

        } else if (params.annotation_tool == 'Bakta') {

            // Bakta annotation
            Bakta_annotation(seq_genus
                            .seq
                            ,seq_genus
                            .genus
                            ,params.project)

        }
    } else {
        println "No taxonomy file provided, skipping taxonomy comparison and check. Running annotation with the chosen tool without genus information."

        // Run annotation based on the chosen annotation tool without genus information
        if (params.annotation_tool == 'PGAP') {
            error "PGAP annotation requires genus information. Please provide a taxonomy file for PGAP annotation."

        } else if (params.annotation_tool == 'Bakta') {
            // Bakta annotation
            Bakta_annotation(seq_with_name // Get the sequence path for Bakta input
                            , "" // No genus information
                            , params.project)
        }
        Taxonomy_collection = Channel.empty() // Create an empty channel for taxonomy collection since no taxonomy information is available
    }
    
    // Set the annotation output path based on the chosen annotation tool
    if (params.annotation_tool == 'PGAP') {
        annotation_out = PGAP_annotation.out
    } else if (params.annotation_tool == 'Bakta') {
        annotation_out = Bakta_annotation.out
    }
    if (params.antismash) {
        gff_file = annotation_out
                            .map { seq_name, annotation_dir -> findGff3File(annotation_dir) } // Get the gff3 file path for Antismash input
                            .view { gff -> "GFF3 file for Antismash input: $gff" }
        nucleotide_file = annotation_out.map { seq_name, annotation_dir -> findEmlbFile(annotation_dir) } // Get the sequence path for Antismash input
                                        .view { nucleotide -> "Nucleotide file for Antismash input: $nucleotide" }
        Antismash_annotation(seq_with_name
                            .map { it[0] } // Get the sequence name for Antismash input
                            , nucleotide_file
                            , gff_file
                            , params.project)
    }

    publish:
    Annotation = annotation_out
    Taxonomy = Taxonomy_collection
    Secondary_metabolites = Antismash_annotation.out
}

/*
 * Pipeline outputs
 */

output {
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
