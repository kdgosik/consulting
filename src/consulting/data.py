import os
import sys
import re
import subprocess

import numpy as np
import pandas as pd

from consulting.config import *
from consulting.utils import *


#####################################################
###  CORE FUNCTIONS - CALL THESE TO LOAD AND SAVE ###
#####################################################

def download_clinvar():
    """
    Downloads the clinvar data from the NCBI website

    Parameters
    ----------

    Returns
    -------
    """
    root_dir = get_project_root().replace('/src', '')

    print('Downloading clinvar data...')
    url = 'ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz'
    output_path = f"{root_dir}/data/external/variant_summary.txt.gz"
    
    command = f"wget {url} -O {output_path}"
    output, error = execute_command(command)
    

def read_clinvar(test_set=False):
    """
    Reads in the clinvar data and processes it to be used in the variant effect map

    Parameters
    ----------
    test_set - bool - whether to read in a small subset of the data for testing purposes

    Returns
    -------
    df - pd.DataFrame - clinvar data
    """
    
    root_dir = get_project_root().replace('/src', '')
    file_path = f"{root_dir}/data/external/variant_summary.txt.gz"
    
    if not os.path.exists(file_path):
        download_clinvar()
        
    nrows = None
    if test_set:
        nrows = 1000
    
    print('Reading in clinvar data...')
    df = (
        pd.read_csv(file_path, sep='\t', compression='gzip', nrows=nrows)
    )

    return df


def download_findlay_brac1():
    """
    Downloads the Findlay BRCA1 data from the Journal website
    https://www.nature.com/articles/s41586-018-0461-z#Sec8

    Parameters
    ----------

    Returns
    -------
    """

    print('Downloading Findlay BRCA1 data...')
    url = 'https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-018-0461-z/MediaObjects/41586_2018_461_MOESM3_ESM.xlsx'
    output_path = "../../data/external/41586_2018_461_MOESM3_ESM.xlsx"
    
    command = f"wget {url} -O {output_path}"
    output, error = execute_command(command)
    
    
    
def read_findlay_brca1():
    """
    Reads in the Findlay BRCA1 data and processes it to be used in the variant effect map
    https://github.com/ArcInstitute/evo2/blob/main/notebooks/brca1/brca1_zero_shot_vep.ipynb
    """
    
    brca1_df = pd.read_excel(
        os.path.join('../../data', 'external', '41586_2018_461_MOESM3_ESM.xlsx'),
        header=2
    )
    
    # brca1_df.columns
    ## select columns
    # brca1_df = brca1_df[[
    #     'chromosome', 'position (hg19)', 'reference', 'alt', 'function.score.mean', 'func.class'
    #     ]]


    # Rename columns
    brca1_df = brca1_df.rename(columns={
        'chromosome': 'chrom',
        'position (hg19)': 'pos',
        'reference': 'ref',
        'alt': 'alt',
        'function.score.mean': 'score',
        'func.class': 'class',
        })

    # Convert to two-class system
    brca1_df['class2'] = brca1_df['class'].replace(['FUNC', 'INT'], 'FUNC/INT')
    brca1_df['clinvar_category'] = brca1_df['clinvar_simple'].map(ANNOTATION_MAP)
    
    return brca1_df



#############################
###  Processing Functions  ##
#############################


def get_mappings():
    """
    """
    uniprot_to_gene_dict = get_uniprot_to_gene_dict()
    uniprot_ids = [uniprot_id for uniprot_id, gene in uniprot_to_gene_dict.items() if gene in GENE_LIST]
    ensembl_to_gene_dict = get_ensembl_to_gene_dict()
    ensembl_ids = [ensembl_id for ensembl_id, gene in ensembl_to_gene_dict.items() if gene in GENE_LIST]
    return uniprot_to_gene_dict, uniprot_ids, ensembl_to_gene_dict, ensembl_ids




##############################################
###  HELPER FUNCTIONS - DO NOT CALL THESE!  ##
##############################################

def filter_from_gzip(gzip_filename, filter_value, filter_col, delim):
    """
    Reads a gzipped CSV file, filters rows based on a value in the first column,
    and writes the filtered rows to a new CSV file.

    :param gzip_filename: Path to the gzipped CSV file
    :param filter_value: Value to filter the rows by (in the first column)
    :param filter_col: index of column to filter
    :param delim: check delimintar
    """
    out = []
    hi=0
    # gzip_filename='/mnt/project/reference/REVEL/DataS3_REVEL_with_gene_names.csv.gz'
    with gzip.open(gzip_filename, 'rt', newline='') as gz_file:
        if delim == ",":
            csv_reader = csv.reader(gz_file)      
            for row in csv_reader:
                if hi == 0:
                    header = row
                    hi +=1
                if row[filter_col] == filter_value: # "ENST00000252444":
                    out.append(row)
            df = pd.DataFrame(out, columns = header)
        else:
            for line in gz_file:
                # print(line.decode('utf-8').split())
                row = line.split()
                if row[filter_col] == filter_value: # "ENST00000252444":
                    out.append(row)  
            df = pd.DataFrame(out)

    return df


######################
###  UKB Functions  ##
######################

def create_phenotype_file(pheno_fieldid, phenotype_file):
    """Create a phenotype file to be able to process into Regenie input.

    NOTE: must be run on the DNANexus platform at current state
    
    Parameters
    ----------
    pheno_fieldid: str - UKB field ID to use as the phenotype
    phenotype_file: str - name of the output file
    
    Returns
    -------
    
    """
    
    if not isinstance(pheno_fieldid, list):
        pheno_fieldid = [pheno_fieldid]
    
    dataset='project-GjjY4j0JYgZk9b7ypz3bK1Xx:record-Gjjy6qjJ78vVYvKPFp9qB0Vq'
    
    sex_fields = ['p31']
    age_fields = ['p21003_i0', 'p21003_i1', 'p21003_i2', 'p21003_i3']
    pc_fields = ['p22009_a1', 'p22009_a2', 'p22009_a3', 'p22009_a4', 'p22009_a5',
                 'p22009_a6', 'p22009_a7', 'p22009_a8', 'p22009_a9', 'p22009_a10',
                 'p22009_a11', 'p22009_a12', 'p22009_a13', 'p22009_a14','p22009_a15', 
                 'p22009_a16', 'p22009_a17', 'p22009_a18','p22009_a19', 'p22009_a20']
                 # 'p22009_a21', 'p22009_a22','p22009_a23', 'p22009_a24', 'p22009_a25', 
                 # 'p22009_a26','p22009_a27', 'p22009_a28', 'p22009_a29', 'p22009_a30',
                 # 'p22009_a31', 'p22009_a32', 'p22009_a33', 'p22009_a34','p22009_a35', 
                 # 'p22009_a36', 'p22009_a37', 'p22009_a38','p22009_a39', 'p22009_a40']
    
    field_names = ['eid']+sex_fields+age_fields+pc_fields+pheno_fieldid
    field_names_str = [f"participant.{f}" for f in field_names]
    field_names_cmd = ",".join(field_names_str)

    cmd = ['dx', 'extract_dataset',dataset,'--fields',field_names_cmd,
           '--delimiter',',','--output', phenotype_file]
    print(cmd)
    subprocess.check_call(cmd)


def reformat_phenotype_file(phenotype_file, gene, phenotype, pheno_fieldid):
    """Reformats UKB file to pass into regenie for burden testing

    NOTE: must be run on the DNANexus platform at current state
    
    Parameters
    ----------
    
    Returns
    -------
    
    """
    if not isinstance(pheno_fieldid, list):
        pheno_fieldid = [pheno_fieldid]
    
    phenotype_file_out = phenotype_file.replace('.csv','.txt')
    pheno_df = pd.read_csv(phenotype_file)
    
    ## extract covariates and rename
    cnames_dict = {s:s.replace('participant.p22009_a', 'PC') for s in pheno_df.columns if 'p22009' in s}
    cnames_dict['participant.eid'] = 'IID'
    cnames_dict['participant.p21003_i0'] = 'Age'
    for pid,p in zip(pheno_fieldid, phenotype):
        cnames_dict['participant.'+pid] = p
    
    pheno_df = pheno_df.rename(columns = cnames_dict)
    pheno_out_df = (
        pheno_df
        .assign(FID = lambda x: x['IID'],
                Sex = lambda x: x['participant.p31']+1) # 1 - Female, 2 - Male
        .assign(Age_Sq = lambda x: x['Age']**2,
                Age_x_Sex = lambda x: x['Age']*x['Sex'])
        .filter(['FID','IID','Sex','Age', 'Age_Sq', 'Age_x_Sex',]+phenotype+[f'PC{i}' for i in range(1,41)])
    )
    
    print("Saving to DNANexus ...")
    pheno_out_df.dropna().to_csv(phenotype_file_out, sep = '\t', index=False)
    dxpy.upload_local_file(phenotype_file_out, folder = f'/mavevidence/genes/{gene}/')


def run_plink(plink_file_set, gene, chrom, start, end, output):
    """Run plink filtering for a given gene position
    
    """
    plink_cmd=f'''plink --bfile "{plink_file_set}" \
    --chr {chrom} --from-bp {start} --to-bp {end} \
    --recode A --make-bed --out {gene}_{output}'''
    
    result = subprocess.run(plink_cmd, shell=True, stdout=subprocess.PIPE)
    print(result.stdout.decode())


    
# plink --bfile GLA_snps --recode vcf --out GLA_snps_vcf 
# ./vep -i input.vcf --cache --format vcf --output_file output.txt 