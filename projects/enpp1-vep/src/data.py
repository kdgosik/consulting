import os
import sys
import wget
import re

import numpy as np
import pandas as pd

sys.path.append('../../../src')
from consulting.config import *
from consulting.utils import *



def download_clinvar():
    """
    Downloads the clinvar data from the NCBI website

    Parameters
    ----------

    Returns
    -------
    """

    print('Downloading clinvar data...')
    url = 'ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz'
    output_path = "../data/external/variant_summary.txt.gz"
    
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
    
    if not os.path.exists('../data/external/variant_summary.txt.gz'):
        download_clinvar()
        
    nrows = None
    if test_set:
        nrows = 1000
    
    print('Reading in clinvar data...')
    df = (
        pd.read_csv('../data/external/variant_summary.txt.gz', sep='\t', compression='gzip', nrows=nrows)
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
    output_path = "../data/external/41586_2018_461_MOESM3_ESM.xlsx"
    
    command = f"wget {url} -O {output_path}"
    output, error = execute_command(command)
    
    
    
def read_findlay_brca1():
    """
    Reads in the Findlay BRCA1 data and processes it to be used in the variant effect map
    """
    
    brca1_df = pd.read_excel(
        os.path.join('../data', 'external', '41586_2018_461_MOESM3_ESM.xlsx'),
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
    brca1_df['class'] = brca1_df['class'].replace(['FUNC', 'INT'], 'FUNC/INT')
    
    return brca1_df