import data


def extract_features_clinvar():
    """
    Reads in the clinvar data and processes it to be used in the variant effect map

    Parameters
    ----------

    Returns
    -------
    clinvar_df - pd.DataFrame - processed clinvar data
    """
    
    def _extract_protein_change(text):
        """Extracts the protein change from a text string

        Parameters
        ----------
        text - str - text string to extract protein change from

        Returns
        -------
        match.group() - str - protein change
        """

        match = re.search(r'p\.[A-Za-z]+[0-9]+[A-Za-z]+', text)

        if match:
            return match.group()
        else:
            return None

    df = (
        data.read_clinvar(test_set=True)
        .assign(protein_change = lambda x: x['Name'].apply(_extract_protein_change))
        .assign(protein_variant = lambda x: x['protein_change'].apply(shorten_protein_change)) 
        .assign(aa_pos = lambda x: x['protein_change'].str.extract(r'(\d+)').astype(float),
                aa_ref = lambda x: x['protein_change'].str[2],
                aa_alt = lambda x: x['protein_change'].str[-1])
        .dropna()
    )

    return df


def add_vep_scores(df, vep, gene):
    """
    Processes the clinvar data to be used in the variant effect map
    
    Parameters
    ----------
    df - pd.DataFrame - clinvar data
    vep - str - vep score to add to
    gene - str - gene to filter the data on
    
    Returns
    -------
    clinvar_df - pd.DataFrame - processed clinvar data
    """
    
    df = (
        df
        .query('GeneSymbol == @gene')
        .query('Type == "single nucleotide variant"')
        .assign(strand = "+")
        .filter(['Chromosome', 'PositionVCF','strand', 'ReferenceAlleleVCF', 'AlternateAlleleVCF'])
    )
    
    # save data to file for open-cravat
    os.makedirs(f'../data/processed/{gene}', exist_ok=True)
    data_file=f'../data/processed/{gene}/{gene}_clinvar_oc.tsv'
    df.to_csv(data_file, sep='\t', index=False, header=False)

    # run open-cravat annotator
    run_annotator(data_file, vep)
    
    # read in open-cravat output
    oc_output_file = f'{data_file}.xlsx'
    clinvar_df = pd.read_excel(oc_output_file, sheet_name=1, header=1)
    clinvar_df['assay'] = vep
    clinvar_df.columns = clinvar_df.columns.str.lower().str.replace(' ', '_')
    clinvar_df['protein_variant'] = 'p.'+clinvar_df['protein_variant']
    
    return clinvar_df
    

if __name__ == '__main__':
    gene = 'BRCA1'
    vep = 'alphamissense'
    
    ## Read in BRCA1 data from clinvar
    clinvar_df =  data.read_clinvar(test_set=False)
    clinvar_df = add_vep_scores(clinvar_df, vep, gene)
    
    ## Read in BRCA1 data from Findlay DMS
    brca1_df = data.read_findlay_brca1()

    plot_df = (
        clinvar_df
        .set_index('protein_variant')
        .filter(['score','assay','clinical_significance'])
        .join(brca1_df
              .set_index('protein_variant')
              .filter(['score','class','class2','clinvar_category']), 
              lsuffix='_alphamissense',rsuffix='_findlay')
        .dropna()
        .reset_index()
    )


    sns.scatterplot(plot_df,x='score_alphamissense', y='score_findlay')
    sns.kdeplot(plot_df,x='score_alphamissense', hue='clinvar_category', common_norm=False)
    sns.kdeplot(plot_df,x='score_findlay', hue='clinvar_category', common_norm=False)