#!/usr/bin/env nextflow

/*
 * Python file to get both NCBI and GTDB and compare them to follow (focus mainly on the genus as the reference genomes for the species are often irrelevant)
 */

process Python_taxonomy_comparison {

    input:
    path seq
    path tax_gtdb

    output:
    path "${seq.simpleName}_output.csv"
    path "${seq.simpleName}.log"


    script:
    """
    module load python
    source /home/elouanln/scratch/Sandbox/ETE3/bin/activate
    python /home/elouanln/projects/def-jcomte/elouanln/Sandbox/Code/Annotation/PGAP/bin/compare_taxonomies.py  \
    --seq ${seq} \
    --tax_gtdb ${tax_gtdb} \
    --out_dir ${seq.simpleName}_output.csv > ${seq.simpleName}.log
    """
}