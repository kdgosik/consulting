import models



def plot_functional_code_countplot(score_df):
    """_summary_

    Parameters
    ----------
    score_df pd.DataFrame: _description_
    """
    
    plt.figure(figsize=(10, 6))
    ax = sns.countplot(x='functional_evidence_code', 
                       data=score_df, 
                       order=[l['code'] for l in ACMG_FUNCTIONAL_EVIDENCE_CODES], 
                       palette=ANNOTATION_COLOR_PALETTE)
    plt.title('Variant Counts of Functional Annotation')
    plt.xlabel('Functional Annotation')
    plt.xticks(rotation=90)
    plt.ylabel('Count')

    # Add counts on top of bars
    for p in ax.patches:
        ax.annotate(f'{int(p.get_height())}', 
                    (p.get_x() + p.get_width() / 2., 
                     p.get_height()),
                    ha='center', 
                    va='center',
                    xytext=(0, 10), 
                    textcoords='offset points')

    plt.show()
    

def plot_functional_code_kde(score_df, vep, save_fig=False):
    """_summary_
    
    Parameters
    ----------
    score_df pd.DataFrame: _description_
    vep str: _description_
    save_fig bool: _description_ 
    
    Returns
    -------
    """
    
    gene = score_df['gene'].unique()[0]
    vep = vep.upper()
    
    sns.kdeplot(x='score',hue = 'clinical_annotation', data=score_df, fill=True, palette=color_palette, common_norm=False)
    plt.title(gene, fontsize=12)
    plt.suptitle(f'{vep} Scores by ClinVar Annotation', fontsize=14,fontweight='bold')
   
    if save_fig:
        plt.savefig(f'{gene}_kde_{vep}_by_clinvar.png')
        
        
        
        
if __main__ == '__main__':
    score_df = models.load_score_data()
    plot_functional_code_countplot(score_df)
    plot_functional_code_kde(score_df, 'vep', save_fig=True)
    plot_functional_code_kde(score_df, 'sift', save_fig=True)