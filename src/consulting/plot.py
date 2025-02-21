import os
import sys

import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import seaborn as sns
import plotly


def plot_variant_effect_map(df, value_col):
    """

    Parameters
    ----------
    df: - pd.DataFrame - processed assay dataframe from read_and_process_assay(gene, assay)

    Returns
    -------

    """
    ## variant effect map
    # value_col = 'oddspath'
    plotdf = (
        df
        .reset_index()
        .assign(aaalt = lambda x: x['protein_coordinates'].str[-1])
        .filter(['aaalt','aa_position',value_col])
        .pivot(index = 'aaalt',columns = 'aa_position', values = value_col)
        )
    
    ax=sns.heatmap(plotdf)
    ax.set_title('Variant Effect Map: Functional Assay')
    
    return ax


def gnomad_to_variant_effect_map(gnomad_gene_dataset, column):
    """Takes in export from gnomAD and processes the data to create a variant effect map

    Parameters
    ----------
    gnomad_gene_dataset - pd.DataFrame from utils._read_reformat_gnomad(data_path)
    column - 

    
    Returns
    -------
    
    """
    if column is None:
        column = 'clinvar_num'
    
    plot_longdf = (
        gnomad_gene_dataset
        .drop_duplicates()
        .sort_values('aa_position')
        .assign(clinvar = lambda x: x['ClinVar Clinical Significance'].fillna('VUS'))
        .drop(columns=['VEP Annotation','ClinVar Clinical Significance'])
        .drop_duplicates()
    )
    
    plot_widedf = (
        plot_longdf
        .assign(clinvar_num = lambda x: x['clinvar'].map({'VUS':0,'B/LB':1,'P/LP':-1}))
        .filter(['AA','aa_position','clinvar_num','revel_max','cadd'])
        .groupby(['AA','aa_position'])
        .min()
        .reset_index()
        .pivot(index='AA', columns = 'aa_position', values=column)
    )
    
    return sns.heatmap(plot_widedf, cmap='RdBu')

