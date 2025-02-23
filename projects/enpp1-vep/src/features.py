import data



def read_clinvar():
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