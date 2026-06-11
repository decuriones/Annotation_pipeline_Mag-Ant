#!/bin/Python3

import requests
import pandas as pa
import os
from ete3 import NCBITaxa
import json
import argparse

def get_taxonomy_from_api(genus,species_name):
    tax_data = requests.get(f"https://gtdb-api.ecogenomic.org/taxon/{genus}")
    tax_data = tax_data.text
    list_dic_tax = json.loads(tax_data)
    if type(list_dic_tax) == dict and "does not exist" in list_dic_tax['detail']:
        print(f"Genus {genus} not found in GTDB API. \nGenus is then set to default value: Escherichia (E. coli) \nPlease check the corrected genus after pgap run with --taxcheck --auto-correct-tax")
        return("g__Escherichia", 561)
    else:
        for taxa in list_dic_tax:
            if species_name == taxa['taxon']:
                return(genus, taxa['ncbiTaxId'])

def get_taxonomy_from_NCBI (taxonomy_id):
    ncbi = NCBITaxa()
    lineage = ncbi.get_lineage(taxonomy_id)
    for Taxid in lineage:
        if NCBITaxa().get_rank([Taxid])[Taxid] == "genus":
            return(ncbi.get_taxid_translator([Taxid])[Taxid])
    return("No genus found")

def compare_taxonomies(genus, species_name):
    print(f"Comparing taxonomies for genus: {genus} and species: {species_name}")
    tax_gtdb = get_taxonomy_from_api(genus, species_name)
    print(f"GTDB taxonomy: {tax_gtdb}")
    tax_ncbi = get_taxonomy_from_NCBI(tax_gtdb[1])
    return tax_gtdb, tax_ncbi, tax_gtdb[0].replace("g__", "").upper() == tax_ncbi.upper()

def csv_creation(seq, tax_gtdb,output_path):
    seq_name, genus, species_name = metadata_parsing(seq, tax_gtdb)
    print(f"Creating CSV file for sequence: {seq_name} with genus: {genus} and species: {species_name}")
    if genus == "g__":
        print("Unknown_genus, \n !!! default genus set to Escherichia (E. coli) !!!, \n Please check the corrected genus after pgap run with --taxcheck --auto-correct-tax")
        genus = "g__Escherichia"
        
    if species_name == "s__":
        print("Unknown_species, \n only genus will be compared, \n Please check the corrected genus after pgap run with --taxcheck --auto-correct-tax")
        species_name = genus.replace("g__", "s__")
    tax_gtdb, tax_ncbi, comparison_result = compare_taxonomies(genus, species_name)
    df = pa.DataFrame({
        'Sequence': [seq_name],
        'GTDB Taxonomy': [tax_gtdb[0]],
        'NCBI Taxonomy': [tax_ncbi],
        'Match': [comparison_result]
    })
    df.to_csv(output_path, index=False)
    print(f"CSV file created at: {output_path}")

def metadata_parsing(seq, tax_gtdb):
    print(f"Parsing metadata for sequence: {seq}")
    df_metadata = pa.read_csv(tax_gtdb, sep="\t")
    seq_name = os.path.basename(seq).replace(".fasta", "")
    if df_metadata[df_metadata['user_genome'] == seq_name].empty:
        print(f"No genus or species found for {seq_name} in GTDB taxonomy file. \nGenus and species are then set to default value: Escherichia (E. coli) \nPlease check the corrected genus after pgap run with --taxcheck --auto-correct-tax")
        return(seq_name, "g__Escherichia", "s__Escherichia coli")
    taxonomy = df_metadata[df_metadata['user_genome'] == seq_name]['classification'].tolist()[0].split(";")
    genus_species = [tax for tax in taxonomy if tax.startswith("g__") or tax.startswith("s__")]
    return(seq_name, genus_species[0], genus_species[1])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract taxonomy from GTDB and NCBI and compare them.")
    parser.add_argument("-S", "--seq", required=True, help="tsv output from CoverM Genome.")
    parser.add_argument("-b", "--tax_gtdb", required=True, help="Taxonomy file from GTDB.")
    parser.add_argument("-o", "--out_dir", required=True, help="Output directory for the CSV file.")
    args = parser.parse_args()
    csv_creation(args.seq, args.tax_gtdb, args.out_dir)

