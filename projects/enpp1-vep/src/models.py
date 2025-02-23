import features


def calculate_oddspath_for_predictor(df):
    std_dev_proportion = 0.1
    
    # ACMG_FUNCTIONAL_EVIDENCE_CODES
    # cutoffs = [0, 0.053, 0.23, 0.48, 2.1, 4.3, 18.7, 350, float("inf")]
    # functional_evidence_codes = [
    #     "BS3_strong",
    #     "BS3_moderate",
    #     "BS3_supporting",
    #     "Indeterminate",
    #     "PS3_supporting",
    #     "PS3_moderate",
    #     "PS3_strong",
    #     "PS3_very_strong",
    # ]


    assays = df["assay"].unique()

    assay_dfs = []
    for assay in assays:
        assay_df = df[df["assay"] == assay]
        pathogenic_df = assay_df[assay_df["clinical_annotation"] == "P/LP"]
        pathogenic_scores = np.array(pathogenic_df["score"].values)
        num_pathogenic_total = len(pathogenic_scores)
        benign_df = assay_df[assay_df["clinical_annotation"] == "B/LB"]
        benign_scores = np.array(benign_df["score"].values)
        num_benign_total = len(benign_scores)
        num_reference_total = num_pathogenic_total + num_benign_total
        all_reference_scores = np.concatenate((pathogenic_scores, benign_scores))
        all_scores = np.sort(assay_df["score"].values)

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
        assay_df["oddspath"] = assay_df["score"].map(likelihood_ratio_dict)
        assay_dfs.append(assay_df)
    oddspath_df = pd.concat(assay_dfs)

    oddspath_df["functional_evidence_code"] = pd.cut(
        oddspath_df["oddspath"], bins=cutoffs, labels=functional_evidence_codes
    ).astype(object)

    return oddspath_df
