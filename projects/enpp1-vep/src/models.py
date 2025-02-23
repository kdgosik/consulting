import features


def calculate_oddspath_for_predictor(df):
    """_summary_

    Parameters
    ----------
    df pd.DataFrame: processed clinvar data with VEP scores

    Returns:
    pd.DataFrame: _description_
    """
    std_dev_proportion = 0.1

    # pathogenic scores subset
    pathogenic_df = df[df["clinical_annotation"] == "P/LP"]
    pathogenic_scores = np.array(df["score"].values)
    num_pathogenic_total = len(pathogenic_scores)
    
    # benign scores subset
    benign_df = df[df["clinical_annotation"] == "B/LB"]
    benign_scores = np.array(benign_df["score"].values)
    num_benign_total = len(benign_scores)
    
    num_reference_total = num_pathogenic_total + num_benign_total
    all_reference_scores = np.concatenate((pathogenic_scores, benign_scores))
    all_scores = np.sort(df["score"].values)

    if num_benign_total == 0 or num_pathogenic_total == 0:
        likelihood_ratios = np.ones_like(all_scores)

    else:
        std_dev = (max(all_scores) - min(all_scores)) * std_dev_proportion
        likelihood_ratios = []
        for score in all_scores:
            window_pathogenic_gaussian_values = gaussian(
                pathogenic_scores, score, std_dev
            ).sum()
            window_benign_gaussian_values = gaussian(
                benign_scores, score, std_dev
            ).sum()
            likelihood_ratio = (
                window_pathogenic_gaussian_values / num_pathogenic_total
            ) / (window_benign_gaussian_values / num_benign_total)
            likelihood_ratios.append(likelihood_ratio)
        likelihood_ratios = np.array(likelihood_ratios)
        mask = np.isnan(likelihood_ratios)
        likelihood_ratios[mask] = np.interp(
            np.flatnonzero(mask), np.flatnonzero(~mask), likelihood_ratios[~mask]
        )
    likelihood_ratio_dict = dict(zip(all_scores, likelihood_ratios))
    df["oddspath"] = df["score"].map(likelihood_ratio_dict)



    df["functional_evidence_code"] = pd.cut(
        df["oddspath"], 
        bins=[l['cutoff'] for l in ACMG_FUNCTIONAL_EVIDENCE_CODES], 
        labels=[l['code'] for l in ACMG_FUNCTIONAL_EVIDENCE_CODES]
    ).astype(object)

    return df
