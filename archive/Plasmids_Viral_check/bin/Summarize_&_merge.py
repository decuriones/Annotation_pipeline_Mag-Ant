#!/bin/Python3

import pandas as pa
import os
import argparse

def csv_creation(geNomad_v, geNomad_p, viral_verify, out_v, out_p):
    # Load the geNomad summaries for viruses and plasmids
    geNomad_viruses = pa.read_csv(geNomad_v, sep="\t")
    geNomad_plasmids = pa.read_csv(geNomad_p, sep="\t")
    
    # Load the viral_verify summary
    viral_verify_df = pa.read_csv(viral_verify, sep=",")
    
    # giving the strain an ID (contained in the filename)
    strain_ID= os.path.basename(viral_verify).split("-")[0]
    if strain_ID.endswith("results.csv") or strain_ID.lower() != os.path.basename(geNomad_p).replace("_plasmid_summary.tsv","").lower() or strain_ID.lower() != os.path.basename(geNomad_v).replace("_virus_summary.tsv","").lower():
        raise ValueError(f"Strain ID mismatch: {strain_ID} does not match the expected format based on the input filenames.")
    
    # Merge the geNomad virus summary with the viral_verify summary on 'Contig_ID'
    merged_viruses = Merging(geNomad_viruses, viral_verify_df,strain_ID)

    # Summarize and merge the geNomad plasmid summary with the viral_verify summary
    merged_plasmids = Merging(geNomad_plasmids, viral_verify_df,strain_ID)
    
    # Save the merged plasmid & virus summary to a new CSV file
    merged_plasmids.to_csv(out_p, sep=",", index=False)
    merged_viruses.to_csv(out_v, sep=",", index=False)

def Merging(geNomad_df, viral_verify_df, strain_ID):

    # Copying the dataframes to avoid modifying the original ones
    copy_geNomad_df, copy_viral_verify_df = geNomad_df.copy(), viral_verify_df.copy()
    # Masking values according to geNomad input, keeping only viruses if considering virus summary and chromosomal and plasmidic sequences else

    if 'virus_score' in copy_geNomad_df.columns:
        copy_viral_verify_df = copy_viral_verify_df.loc[
            copy_viral_verify_df['classification'].astype(str).str.lower().str.contains('virus|provirus', regex=True, na=False), :
        ]
        type_seq = "viral"
    elif 'plasmid_score' in copy_geNomad_df.columns:
        copy_viral_verify_df = copy_viral_verify_df.loc[
            copy_viral_verify_df['classification'].astype(str).str.lower().str.contains('plasmid|chromosome', regex=True), :
        ]
        type_seq = "plasmid"
    
    # Creating col with stable contig id and new col for genomad complete viruses and plasmids
    copy_geNomad_df['Contig_ID'] = copy_geNomad_df['seq_name'].astype(str).str.split('|').str[0].str.replace("_polypolish", "", regex=False).str.replace("_polish", "", regex=False)
    copy_viral_verify_df['Contig_ID'] = copy_viral_verify_df['contig_name'].astype(str).str.split('|').str[0]
    
    if 'virus_score' in copy_geNomad_df.columns and type_seq == "viral":
        copy_geNomad_df.loc[(copy_geNomad_df['topology']=='No terminal repeats') & (copy_geNomad_df['virus_score'].notnull()) & (copy_geNomad_df['coordinates'].isna()), 'Virus_completeness'] = 'Complete viral sequence suspected'
        copy_geNomad_df.loc[(copy_geNomad_df['topology']!='No terminal repeats') , 'Virus_completeness'] = 'Integration of partial viral sequence within bacterial DNA suspected'

    # to keep in genomad : contig id, topology, length, coordinates, n genes , scores, hallmarks & marker enrichment
    # to keep in viral verify : contig id, classif & prob depending on the classif
    List_col_geNomad = [col for col in copy_geNomad_df.columns if col in ['Contig_ID','length', 'topology', 'coordinates', 'n_genes', 'plasmid_score', 'virus_score', 'n_hallmarks', 'marker_enrichment'] and col != 'taxonomy']
    List_col_viral_verify = ['Contig_ID', 'classification'] + [col for col in copy_viral_verify_df.columns if col not in ['Contig_ID', 'contig_name', 'classification', 'protein_domains', 'taxonomy'] and type_seq in col.lower()]

    copy_geNomad_df, copy_viral_verify_df = copy_geNomad_df[List_col_geNomad], copy_viral_verify_df[List_col_viral_verify]

    # Merge the geNomad summary with the viral_verify summary on 'Contig_ID'
    merged_df = pa.merge(copy_geNomad_df, copy_viral_verify_df, on='Contig_ID', how='outer', suffixes=('_geNomad', '_viral_verify'))
    
    # Reorder columns and include classification for relevant dataframes
    first_cols = ['Contig_ID','topology']
    if 'classification' in merged_df.columns:
        first_cols += ['classification']

    merged_df=merged_df[['Contig_ID','topology'] + [col for col in merged_df.columns if col != 'Contig_ID']]
    
    # Fill NaN values in 'Viral_Verification' with 'Not Verified'
    if 'Viral_Verification' in merged_df.columns:
        merged_df['Viral_Verification'] = merged_df['Viral_Verification'].fillna('Not Verified')
    
    return merged_df

# Function to compute probabilities from log probabilities and compare them to a threshold (e.g. pvalue)

def compute_probabilities_and_classify(merged_df, threshold=0.05):
    return()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Summarize and merge geNomad and viral_verify outputs.")
    parser.add_argument("-V", "--geNomad_v", required=True, help="geNomad summary file for viruses.")
    parser.add_argument("-P", "--geNomad_p", required=True, help="geNomad summary file for plasmids.")
    parser.add_argument("-R", "--viral_verify", required=True, help="viral_verify summary file.")
    parser.add_argument("-ov", "--out_v", required=True, help="Output file for viruses summary.")
    parser.add_argument("-op", "--out_p", required=True, help="Output file for plasmids summary.")
    args = parser.parse_args()
    csv_creation(args.geNomad_v, args.geNomad_p, args.viral_verify, args.out_v, args.out_p)

    