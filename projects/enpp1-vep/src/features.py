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
        read_clinvar(test_set=True)
        .assign(protein_change = lambda x: x['Name'].apply(_extract_protein_change))
        .assign(aa_position = lambda x: x['protein_change'].str.extract(r'(\d+)').astype(float))
        #.assign(aaalt = lambda x: x['protein_change'].str[-1])
        .dropna()
    )

    return df


def add_vep_scores(vep):
    """_summary_

    Parameters
    ----------
    vep (_type_): _description_
    
    Returns
    -------
    _type_: _description_
    """
    
    clinvar_df = extract_features_clinvar()
    
    process_clinvar_for_oc(clinvar_df)
    
    ## TODO: open-cravat functions
    # reformat clinvar data for open-cravat
    # run open-cravat for desired vep scores
    # extract vep scores from open-cravat output
    # add vep scores to clinvar_df
    
    return clinvar_df