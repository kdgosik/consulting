import pandas as pd
import numpy as np
from sklearn.metrics import roc_curve, auc

def gaussian(x, mean, std_dev):
    return (1 / (std_dev * np.sqrt(2 * np.pi))) * np.exp(
        -0.5 * ((x - mean) / std_dev) ** 2
    )

def calculate_oddspath(score_and_clinvar_dfs):
    oddspath_dfs = {}
    for predictor, df in score_and_clinvar_dfs.items():
        oddspath_dfs[predictor] = calculate_oddspath_for_predictor(df)
    return oddspath_dfs

def calculate_oddspath_for_predictor(df):
    std_dev_proportion = 0.1
    cutoffs = [0, 0.053, 0.23, 0.48, 2.1, 4.3, 18.7, 350, float("inf")]
    functional_evidence_codes = [
        "BS3_strong",
        "BS3_moderate",
        "BS3_supporting",
        "Indeterminate",
        "PS3_supporting",
        "PS3_moderate",
        "PS3_strong",
        "PS3_very_strong",
    ]


    assays = df["assay"].unique()

    assay_dfs = []
    for assay in assays:
        assay_df = df[df["assay"] == assay]
        pathogenic_df = assay_df[assay_df["clinical_annotation"] == "Pathogenic"]
        pathogenic_scores = np.array(pathogenic_df["score"].values)
        num_pathogenic_total = len(pathogenic_scores)
        benign_df = assay_df[assay_df["clinical_annotation"] == "Benign"]
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

def evaluate_assay_quality(oddspath_dfs):
    assay_quality_dfs = {}
    for predictor, df in oddspath_dfs.items():
        assay_quality_dfs[predictor] = evaluate_assay_quality_for_predictor(df)
    return assay_quality_dfs

def evaluate_assay_quality_for_predictor(df):
    assays = df["assay"].unique()
    assay_quality_data = []
    for assay in assays:
        assay_df = df[df['assay'] == assay]
        pathogenic_df = assay_df[assay_df['clinical_annotation'] == 'Pathogenic']
        pathogenic_scores = np.array(pathogenic_df['score'].values)
        num_pathogenic_total = len(pathogenic_scores)
        benign_df = assay_df[assay_df['clinical_annotation'] == 'Benign']
        benign_scores = np.array(benign_df['score'].values)
        num_benign_total = len(benign_scores)

        if num_pathogenic_total == 0 or num_benign_total == 0:
            assay_quality_data.append({
                'assay': assay,
                'auroc': 0,
                'num_pathogenic': num_pathogenic_total,
                'num_benign': num_benign_total,
                'total_variants': num_pathogenic_total + num_benign_total
            })
            continue

        all_reference_scores = np.concatenate((pathogenic_scores, benign_scores))
        binaries_list = [1]*len(pathogenic_scores) + [0]*len(benign_scores)

        fpr, tpr, thresholds = roc_curve(binaries_list, np.array(all_reference_scores), pos_label=1)
        assay_auc = auc(fpr, tpr)
        assay_quality_data.append({
            'assay': assay,
            'auroc': assay_auc,
            'num_pathogenic': num_pathogenic_total,
            'num_benign': num_benign_total,
            'total_variants': num_pathogenic_total + num_benign_total
        })

    assays_df = pd.DataFrame(assay_quality_data)
    return assays_df.sort_values(by='auroc', ascending=False)
