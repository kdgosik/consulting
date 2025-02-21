import os
import sys
import subprocess
import yaml
import re
import wget

import numpy as np
import pandas as pd

import matplotlib.pyplot as plt
import seaborn as sns
import plotly



def rounddown(x, sig):
    return np.floor(x / sig) * sig


def calculate_egfr(scr, sex, age):
    """https://www.niddk.nih.gov/research-funding/research-programs/kidney-clinical-research-epidemiology/laboratory/glomerular-filtration-rate-equations/adults
    """
    a = np.where(sex == 0, -0.241, -0.302)
    k = np.where(sex == 0, 0.7, 0.9)
    min_calc=np.min(scr/k,1)
    max_calc=np.max(scr/k,1)
    egfr = 142 * (min_calc**a) * (max_calc**-1.2) * (0.9938**age) * (1.012 * sex==0)
    
    return egfr


def create_ids(genomic_coordinates=None, chrom=None, pos=None, ref=None, alt=None):
    """
    """
    if genomic_coordinates is not None:
        m = re.search(r'chr([0-9]{1,2}):g.(\d+)([ACTG])>([ACTG])', genomic_coordinates)
        try:
            ukbid = ':'.join(m.groups())
            gnomadid = '-'.join(m.groups())
        except:
            ukbid=''
            gnomadid=''
    else:
        ukbid = ':'.join([chrom, pos, ref, alt])
        gnomadid = '-'.join([chrom, pos, ref, alt])
    return {
        'ukbid':ukbid,
        'gnomadid':gnomadid
    }


def read_reformat_gnomad(data_path):
    """
    
    Parameters
    ----------

    Returns
    -------
    """
    clinvar_collapse_dict = {
        'Likely benign':'B/LB',
        'Uncertain significance':'VUS',
        'Benign':'B/LB',
        'Conflicting interpretations of pathogenicity':'VUS',
        'Benign/Likely benign':'B/LB',
        'Pathogenic/Likely pathogenic':'P/LP',
        'Likely pathogenic':'P/LP',
        'Pathogenic':'P/LP'
    }

    # df = pd.read_csv(f'{DATA_PATH}/strativar/gnomAD_v4.1.0_ENSG00000157764_2024_08_13_16_15_20.csv')
    df = pd.read_csv(data_path)
    df['ClinVar Clinical Significance'] = df['ClinVar Clinical Significance'].map(clinvar_collapse_dict)
    df['Position_floor'] = [rounddown(x,100) for x in df['Position']]
    
    vareffect_mapdf = (
        df.filter(['VEP Annotation', 'Protein Consequence', 
                   'ClinVar Clinical Significance',
                   'cadd', 'revel_max', 'spliceai_ds_max',
                   'pangolin_largest_ds', 'phylop', 'sift_max', 'polyphen_max'])
        .query('`VEP Annotation`=="missense_variant"')
        .assign(AA = lambda x: [s[-3:] for s in x['Protein Consequence'].values],
                aa_position =  lambda x: [int(re.search('[0-9]{1,3}', s).group(0)) for s in x['Protein Consequence'].values])
        .drop_duplicates()
        .sort_values('aa_position')
        .assign(clinvar = lambda x: x['ClinVar Clinical Significance'].fillna('VUS'))
    )

    return vareffect_mapdf


## Transvar Section ###############
def _download_transvar_reference():
    """Download and setup transvar.
    """

    print('Downloading hg38 annotation files ...')
    subprocess.run('transvar config --download_anno --download_ref --refversion hg38', shell=True)

    print('Downloading hg38 reference files ...')
    subprocess.run('wget https://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.chromFa.tar.gz', shell=True)
    subprocess.run('tar -zxvf hg38.chromFa.tar.gz', shell=True)
    subprocess.run('cat chroms/chr*.fa > hg38.fa', shell=True)

    ## get config path
    res = subprocess.run('transvar config', shell=True, capture_output=True, text=True)
    config = yaml.load(res.stdout, Loader=yaml.FullLoader)
    download_path = config['Download path'][0]
    
    print('Moving to transvar download directory ...')
    subprocess.run(f'cp hg38.fa {download_path}', shell=True)

    print('Indexing reference ...')
    subprocess.run(f'samtools faidx {download_path}/hg38.fa', shell=True)
    print('Download Complete!')


def _test_transvar():
    """Test to see if transvar installed correctly.
    """
    res = subprocess.run("transvar panno -i 'PIK3CA:p.E545K' --ucsc --ccds --refversion hg38", shell=True, capture_output=True, text=True)
    print(res.stdout)


def process_transvar_results(res):
    """Takes CLI output from transvar panno and formats 
    to a pandas dataframe.

    Parameters
    ----------
    res:

    Returns:
    -------
    """
    out=[]
    for text in res.stdout.split('\n'):
        out.append(text.split('\t'))
    tmpdf = pd.DataFrame(out)
    df = pd.DataFrame(tmpdf.iloc[1:-1].values, columns = tmpdf.iloc[0])
    df[['genomic_coordinates', 'nt_variant', 'aa_variant']] = df['coordinates(gDNA/cDNA/protein)'].str.split('/', expand=True)

    return df


def extract_genomic_coordinates(gene, variant_list, set_env=False):
    """

    Parameters
    ----------
    gene - str:
    variant_list - list:

    Returns
    -------
    pd.DataFrame of genomic region of variants
    """

    if set_env:
        os.environ["TRANSVAR_CFG"] = "/home/jovyan/work/data/reference/transvar.cfg"
        os.environ["TRANSVAR_DOWNLOAD_DIR"] = "/home/jovyan/work/data/reference/hg38"
    
    out=[]
    for variant in variant_list:
        res = subprocess.run(["transvar", "panno", "-i", f"{gene}:{variant}", "--ucsc", "--ccds", "--refversion", "hg38"], capture_output=True, text=True)
        out.append(process_transvar_results(res))

    return pd.concat(out)


def extract_protein_translatiion(variant_list):
    """

    Parameters
    ----------
    variant_list - list:

    Returns
    -------
    pd.DataFrame of genomic region of variants
    """
    # os.environ["TRANSVAR_CFG"] = "/home/jovyan/work/data/reference/transvar.cfg"
    # os.environ["TRANSVAR_DOWNLOAD_DIR"] = "/home/jovyan/work/data/reference/hg38"

    
    out=[]
    for variant in variant_list:
        # l = '19:11089552:G:C'.split(':')
        # 'chr{0}:g.{1}{2}>{3}'.format(*l)
        l = variant.split(':')
        # transvar ganno -i 'chr19:g.11089552G>C' --ucsc
        res = subprocess.run(["transvar", "ganno", "-i", 'chr{0}:g.{1}{2}>{3}'.format(*l), "--ucsc", "--refversion", "hg38"], capture_output=True, text=True)
        out.append(process_transvar_results(res))

    return pd.concat(out)


## Regenie Section ############
def _download_regnie():
    """
    """
    # Download and expand the pre-compiled regenie from github
    print("Downloading Regenie from github ...")
    wget.download("https://github.com/rgcgithub/regenie/releases/download/v2.2.4/regenie_v2.2.4.gz_x86_64_Linux_mkl.zip")
    # !wget https://github.com/rgcgithub/regenie/releases/download/v2.2.4/regenie_v2.2.4.gz_x86_64_Linux_mkl.zip
    subprocess.run("unzip regenie_v2.2.4.gz_x86_64_Linux_mkl.zip", shell=True)


def _test_regenie():
    """
    """
    # Now we can start use it on the notebook
    res = subprocess.run("./regenie_v2.2.4.gz_x86_64_Linux_mkl", shell=True, capture_output=True, text=True)
    
    print(res.stdout)


def run_regenie(gene, mask_file, genotype_prefix, phenotype_file, covariate_file, pheno_col, set_list, annotation_file, ouput_name):
    """
    """
    cmd_regenie=f'''./regenie_v2.2.4.gz_x86_64_Linux_mkl \
    --step 2 \
    --ignore-pred \
    --bgen "{genotype_prefix}.bgen" \
    --ref-first \
    --sample "{genotype_prefix}.sample" \
    --phenoFile {phenotype_file} \
    --covarFile {covariate_file} \
    --phenoCol {pheno_col} \
    --covarColList Sex,Age,Age_Sq,Age_x_Sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10 \
    --set-list "{set_list}" \
    --anno-file "{annotation_file}" \
    --mask-def "{mask_file}" \
    --nauto 23 \
    --aaf-bins 0.01,0.001 \
    --bsize 200 \
    --extract-setlist "{gene}" \
    --out {ouput_name}'''
    
    result = subprocess.run(cmd_regenie, shell=True, stdout=subprocess.PIPE)
    print(result.stdout.decode())
    
    
## 0pen-cravat Section ###############

def _download_open_cravat():
    """
    """
    def _check_oc_installed():
        res = subprocess.run("oc", shell=True, capture_output=True, text=True)
        if res.returncode != 0:
            return False
        return True

    if not _check_oc_installed():
        print("Downloading Open-CRAVAT ...")
        subprocess.run("pip3 install open-cravat", shell=True)
        subprocess.run("oc module install-base", shell=True)

    else:
        print("Open-CRAVAT already installed!")


def _test_open_cravat():
    """
    """
    res = subprocess.run("oc", shell=True, capture_output=True, text=True)
    print(res.stdout)
    

def check_annotators():
    """
    Check which annotators are installed
    
    Returns
    -------
    pd.DataFrame - annotators installed
    """
    
    res = subprocess.run("oc module ls -a -t annotator", shell=True, capture_output=True, text=True)
    res_list = res.stdout.split('\n')
    res_list2 = [s.split()[0:2] for s in res_list]
    df = pd.DataFrame(res_list2[1:],columns=res_list2[0])
    df['installed']=['yes' in s for s in res_list][1:]
    
    return df


def install_annotator(annotator):
    """Installs clinvar and the other annotator used as the input parameter.
    
    Parameters
    ----------
    annotator - str: annotator to install
    
    Returns
    -------
    print statement of the annotator installed
    """
    
    res = subprocess.run(f"oc module install clinvar {annotator} -y", shell=True, capture_output=True, text=True)
    print(res.stdout)




## seqkit commands and stesp
# Step 1: filter GTF
# grep NM_004333 genomic.gtf > BRAF.gtf

# Step 2: identify features in fasta, look for start_codon and stop_codon
# seqkit subseq --gtf BRAF.gtf --gtf-tag transcript_id GCF_000001405.40_GRCh38.p14_genomic.fna > BRAF_genomic_features.fa

## TODO: get flanking sequences of start and stop codon as well
# Step 3: identify start and stop codons

# Step 4: select transcript from transcript fasta (fna.fa)

# Step 5: identify CDS based off of start and stop codons and flanking sequences

## TODO: exapand steps
# Step 6: run through saturation mutatgenesis code

## Output order ready files (like in the R code)
## name sequence variants by hgvs nomenclature