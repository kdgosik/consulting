import numpy as np


AA_THREE_TO_ONE_DICT = {
    'Ala':'A', 'Arg':'R', 'Asn':'N', 'Asp':'D', 'Cys':'C',
    'Glu':'E', 'Gln':'Q', 'Gly':'G', 'His':'H', 'Ile':'I',
    'Leu':'L', 'Lys':'K', 'Met':'M', 'Phe':'F', 'Pro':'P',
    'Ser':'S', 'Thr':'T', 'Trp':'W', 'Tyr':'Y', 'Val':'V', 
    'Ter':'*'
}


ANNOTATION_MAP = {
    'Benign':'B/LB',
    'Likely benign':'B/LB',
    'Benign/Likely benign': 'B/LB',
    'Uncertain significance':'VUS',
    'Conflicting interpretations of pathogenicity':'VUS',
    'Pathogenic':'P/LP',
    'Likely pathogenic':'P/LP',
    'Pathogenic/Likely pathogenic':'P/LP',
}


ANNOTATION_COLOR_PALETTE = {
    'B/LB':'darkblue',
    'Benign':'darkblue',
    'Likely benign':'darkblue',
    'BS3':'darkblue',
    'BS3_moderate':'blue',
    'BS3_strong':'darkblue',
    'BS3_supporting':'lightblue',
    'BS3_very_strong':'darkblue',
    'P/LP':'darkred',
    'Pathogenic':'darkred',
    'Likely pathogenic':'darkred',
    'PS3':'darkred',
    'PS3_moderate':'red',
    'PS3_strong':'darkred',
    'PS3_supporting':'pink',
    'PS3_very_strong':'darkred',
    'VUS':'gray',
    'Uncertain significance':'darkgray',
    'Conflicting interpretations of pathogenicity':'lightgray',
    'Indeterminate':'lightgray'
}


ACMG_FUNCTIONAL_EVIDENCE_CODES = [
    {"code": "BS3_strong", "cutoff": 0},
    {"code": "BS3_moderate", "cutoff": 0.053},
    {"code": "BS3_supporting", "cutoff": 0.23},
    {"code": "Indeterminate", "cutoff": 0.48},
    {"code": "PS3_supporting", "cutoff": 2.1},
    {"code": "PS3_moderate", "cutoff": 4.3},
    {"code": "PS3_strong", "cutoff": 18.7},
    {"code": "PS3_very_strong", "cutoff": 350},
    {"code": "PS3_very_strong", "cutoff": np.inf},
]

# https://www.ncbi.nlm.nih.gov/clinvar/docs/acmg/
ACMG_GENE_LIST = [
    {"gene": "ABCA4", "disease": "Stargardt Syndrome", "icd10_code": "H35.5"},
    {"gene": "ACTA2", "disease": "Aortic aneurysm, familial thoracic", "icd10_code": "I71.2"},
    {"gene": "APC", "disease": "Adenomatous polyposis coli", "icd10_code": "D12.6"},
    {"gene": "APOB", "disease": "Familial hypercholesterolemia", "icd10_code": "E78.0"},
    {"gene": "ASPA", "disease": "Canavan disease", "icd10_code": "E75.28"},
    {"gene": "BRCA1", "disease": "Breast cancer", "icd10_code": "C50.9"},
    {"gene": "BRCA2", "disease": "Breast cancer", "icd10_code": "C50.9"},
    {"gene": "CALM1", "disease": "Long QT syndrome", "icd10_code": "I45.81"},
    {"gene": "CBS", "disease": "Homocystinuria", "icd10_code": "E72.11"},
    {"gene": "CFTR", "disease": "Cystic fibrosis", "icd10_code": "E84.9"},
    {"gene": "DSP", "disease": "Arrhythmogenic right ventricular cardiomyopathy", "icd10_code": "I42.8"},
    {"gene": "DSG2", "disease": "Arrhythmogenic right ventricular cardiomyopathy", "icd10_code": "I42.8"},
    {"gene": "ENPP1", "disease": "ENPP1 Deficiency", "icd10_code": "E83.39"},
    {"gene": "FKRP", "disease": "Limb girdle muscular dystrophy", "icd10_code": "G71.033"},
    {"gene": "GAA", "disease": "Pompe Disease", "icd10_code": "E74.02"},
    {"gene": "GBA1", "disease": "Gaucher Disease", "icd10_code": "E75.22"},
    {"gene": "GLA", "disease": "Fabry Disease", "icd10_code": "E75.21"},
    {"gene": "HFE", "disease": "Hereditary hemochromatosis", "icd10_code": "E83.110"},
    {"gene": "HMBS", "disease": "Disorders of porphyrin and bilirubin metabolism", "icd10_code": "E80.2"},
    {"gene": "KCNH2", "disease": "Long QT syndrome", "icd10_code": "I45.81"},
    {"gene": "KCNQ1", "disease": "Long QT syndrome", "icd10_code": "I45.81"},
    {"gene": "LARGE1", "disease": "spinal muscular atrophies", "icd10_code": "G12.8"},
    {"gene": "LDLR", "disease": "Familial hypercholesterolemia", "icd10_code": "E78.0"},
    {"gene": "MEN1", "disease": "Multiple endocrine neoplasia type 1", "icd10_code": "E31.21"},
    {"gene": "MLH1", "disease": "Lynch syndrome", "icd10_code": "Z15.09"},
    {"gene": "MSH2", "disease": "Lynch syndrome", "icd10_code": "Z15.09"},
    {"gene": "MSH6", "disease": "Lynch syndrome", "icd10_code": "Z15.09"},
    {"gene": "MTHFR", "disease": "Hyperhomocysteinaemia", "icd10_code": "E72.11"},
    {"gene": "MYBPC3", "disease": "Hypertrophic cardiomyopathy", "icd10_code": "I42.2"},
    {"gene": "MYH11", "disease": "Aortic aneurysm, familial thoracic", "icd10_code": "I71.2"},
    {"gene": "MYH7", "disease": "Hypertrophic cardiomyopathy", "icd10_code": "I42.2"},
    {"gene": "NF2", "disease": "Neurofibromatosis type 2", "icd10_code": "Q85.02"},
    {"gene": "NPC1", "disease": "Niemann-Pick Disease Type C", "icd10_code": "E75.242"},
    {"gene": "PCSK9", "disease": "Familial hypercholesterolemia", "icd10_code": "E78.0"},
    {"gene": "PKP2", "disease": "Arrhythmogenic right ventricular cardiomyopathy", "icd10_code": "I42.8"},
    {"gene": "PMS2", "disease": "Lynch syndrome", "icd10_code": "Z15.09"},
    {"gene": "PRKN", "disease": "Parkinson", "icd10_code": "G20"},
    {"gene": "PTEN", "disease": "PTEN hamartoma tumor syndrome", "icd10_code": "Q85.8"},
    {"gene": "RB1", "disease": "Retinoblastoma", "icd10_code": "C69.2"},
    {"gene": "RET", "disease": "Multiple endocrine neoplasia type 2", "icd10_code": "E31.22"},
    {"gene": "RHO", "disease": "Autosomal dominant retinitis pigmentosa", "icd10_code": "H35.52"},
    {"gene": "RYR1", "disease": "Malignant hyperthermia susceptibility", "icd10_code": "T88.3"},
    {"gene": "RYR2", "disease": "Catecholaminergic polymorphic ventricular tachycardia", "icd10_code": "I47.2"},
    {"gene": "SCN5A", "disease": "Long QT syndrome", "icd10_code": "I45.81"},
    {"gene": "SGCB", "disease": "Limb girdle muscular dystrophy", "icd10_code": "G71.033"},
    {"gene": "STK11", "disease": "Peutz-Jeghers syndrome", "icd10_code": "Q85.8"},
    {"gene": "TMEM43", "disease": "Arrhythmogenic right ventricular cardiomyopathy", "icd10_code": "I42.8"},
    {"gene": "TPK1", "disease": "Thiamine deficiency", "icd10_code": "E51"},
    {"gene": "TSC1", "disease": "Tuberous sclerosis complex", "icd10_code": "Q85.1"},
    {"gene": "TSC2", "disease": "Tuberous sclerosis complex", "icd10_code": "Q85.1"},
    {"gene": "VHL", "disease": "Von Hippel-Lindau syndrome", "icd10_code": "Q85.8"}
]