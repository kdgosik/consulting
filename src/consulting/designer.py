import os
import sys

import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import seaborn as sns
import plotly

# https://biopython.org/docs/1.75/api/Bio.Restriction.html#examples
# from Bio.Seq import Seq
# from Bio.Restriction import *
# pBs_mcs = 'GGTACCGGGCCCCCCCTCGAGGTCGACGGTATCGATAAGCTTGATATCGAATTCCTG'
# pBs_mcs += 'CAGCCCGGGGGATCCACTAGTTCTAGAGCGGCCGCCACCGCGGTGGAGCTC'
# seq = Seq(pBs_mcs)  # Multiple-cloning site of pBluescript SK(-)
# a = Analysis(AllEnzymes, seq)
# a.print_that()       
def _common_enzmes():
    """Return a dictionary of common enzyme recognition sites
    """
    ##some common enzymes
    {'bamh1':'GGATCC-BamHI',
    'mlu1':'ACGCGT-MluI',
    'nhe1':'GCTAGC-NheI',
    'ecor1':'GAATTC-EcoRI',
    'nde1':'CATATG-NdeI',
    'hind3':'AAGCTT-HindIII',
    'xba1':'TCTAGA-XbaI',
    'spe1':'ACTAGT-SpeI',
    'ecor5':'GATATC-EcoRV' 
    }


import Bio.Data.CodonTable
#HumanCodonUsageFreq_201912.csv
codonTableFreq<-tibble(
  "CODON"=c('GCT','GCC','GCA','GCG','TGT','TGC','GAT','GAC','GAA','GAG','TTT','TTC','GGT','GGC','GGA','GGG','CAT','CAC','ATT','ATC','ATA','AAA','AAG','TTA','TTG','CTT','CTC','CTA','CTG','ATG','AAT','AAC','CCT','CCC','CCA','CCG','CAA','CAG','CGT','CGC','CGA','CGG','AGA','AGG','TCT','TCC','TCA','TCG','AGT','AGC','TAA','TAG','TGA','ACT','ACC','ACA','ACG','GTT','GTC','GTA','GTG','TGG','TAT','TAC'),
  "AA"=c('A','A','A','A','C','C','D','D','E','E','F','F','G','G','G','G','H','H','I','I','I','K','K','L','L','L','L','L','L','M','N','N','P','P','P','P','Q','Q','R','R','R','R','R','R','S','S','S','S','S','S','Z','Z','Z','T','T','T','T','V','V','V','V','W','Y','Y'),
  "AA3"=c('Ala','Ala','Ala','Ala','Cys','Cys','Asp','Asp','Glu','Glu','Phe','Phe','Gly','Gly','Gly','Gly','His','His','Ile','Ile','Ile','Lys','Lys','Leu','Leu','Leu','Leu','Leu','Leu','Met','Asn','Asn','Pro','Pro','Pro','Pro','Gln','Gln','Arg','Arg','Arg','Arg','Arg','Arg','Ser','Ser','Ser','Ser','Ser','Ser','stop','stop','stop','Thr','Thr','Thr','Thr','Val','Val','Val','Val','Trp','Tyr','Tyr'),
  "Aalong"=c('Alanine','Alanine','Alanine','Alanine','Cysteine','Cysteine','Asparticacid','Asparticacid','Glutamicacid','Glutamicacid','Phenylalanine','Phenylalanine','Glycine','Glycine','Glycine','Glycine','Histidine','Histidine','Isoleucine','Isoleucine','Isoleucine','Lysine','Lysine','Leucine','Leucine','Leucine','Leucine','Leucine','Leucine','Methionine','Asparagine','Asparagine','Proline','Proline','Proline','Proline','Glutamine','Glutamine','Arginine','Arginine','Arginine','Arginine','Arginine','Arginine','Serine','Serine','Serine','Serine','Serine','Serine','Stop_codon','Stop_codon','Stop_codon','Threonine','Threonine','Threonine','Threonine','Valine','Valine','Valine','Valine','Tryptophan','Tyrosine','Tyrosine'),
  "Freq"=c(0.26592161,0.39978112,0.22812126,0.106176,0.45615733,0.54384267,0.46454242,0.53545758,0.42245266,0.57754734,0.46413427,0.53586573,0.16308651,0.33710936,0.24992165,0.24988248,0.41851521,0.58148479,0.36107219,0.46986629,0.16906152,0.43404935,0.56595065,0.07656765,0.12905785,0.13171591,0.19557683,0.07138017,0.39570159,1,0.47036699,0.52963301,0.28673133,0.3234704,0.27660253,0.11319575,0.26501676,0.73498324,0.08010753,0.18377663,0.10881248,0.20155434,0.21465775,0.21109127,0.18758584,0.21795953,0.15051715,0.05439771,0.14960182,0.23993794,0.29701912,0.23673791,0.46624297,0.24676884,0.35523154,0.28418773,0.11381189,0.18177011,0.23830638,0.11657741,0.4633461,1,0.44333811,0.55666189),
  "Rank"=c(2,1,3,4,2,1,2,1,2,1,2,1,4,1,2,3,2,1,2,1,3,2,1,5,4,3,2,6,1,1,2,1,2,1,3,4,2,1,6,4,5,3,1,2,3,2,4,6,5,1,2,3,1,3,1,2,4,3,2,4,1,1,2,1)
)



# https://github.com/broadinstitute/SatMut_VariantLibrary_Designer/blob/main/SatMut_VariantLibrary_Designer.R#L132
# fromCodonTo123nt<-function(codon){
#   cdnIn<-codon
#   cdn1nt<-c()
#   cdn2nt<-c()
#   cdn3nt<-c()
#   nts<-c("A","C","G","T")
#   codon64<-c()
#   for(nt1 in nts){
#     for(nt2 in nts){
#       for(nt3 in nts){
#         codon64<-c(codon64, paste(nt1,nt2,nt3,sep=''))
#       }
#     }
#   }
#   for (cdn in codon64){
#     if(stringdist(cdn,cdnIn, method='hamming')==1){
#       cdn1nt<-c(cdn1nt,cdn)
#     }
#     else if(stringdist(cdn,cdnIn,method='hamming')==2){
#       cdn2nt<-c(cdn2nt,cdn)
#     }
#     else if(stringdist(cdn,cdnIn,method='hamming')==3){
#       cdn3nt<-c(cdn3nt,cdn)
#     }
#   }
#   print(cdnIn)
#   print (cdn1nt)
#   print ('=======')
#   print (cdn2nt)
#   print ('=======')
#   print (cdn3nt)
#   return(list("delta1nt"=cdn1nt,"delta2nt"=cdn2nt,"delta3nt"=cdn3nt))
# }

# TODO: look here for an alternative https://biopython.org/docs/1.75/api/Bio.Data.CodonTable.html
def fromCodonTo123nt(codon):
    """creates a list of adjacent codons

    Parameters
    ----------
    codon: str

    Returns
    -------

    """
    cdnIn=codon
    cdn1nt=[]
    cdn2nt=[]
    cdn3nt=[]
    nts=["A","C","G","T"]
    ## TODO: replace with  np.array(np.meshgrid(nts,nts,nts)).T.reshape(-1,3)
    #### codon64=[''.join(s) for s in np.array(np.meshgrid(nts,nts,nts)).T.reshape(-1,3)]
    codon64=[]
    for nt1 in nts:
        for nt2 in nts:
            for nt3 in nts:
                codon64.append(''.join([nt1,nt2,nt3]))
    
    ## TODO: update from here
    for cdn in codon64:
        if stringdist(cdn,cdnIn, method='hamming')==1){
      cdn1nt<-c(cdn1nt,cdn)
    }
    else if(stringdist(cdn,cdnIn,method='hamming')==2){
      cdn2nt<-c(cdn2nt,cdn)
    }
    else if(stringdist(cdn,cdnIn,method='hamming')==3){
      cdn3nt<-c(cdn3nt,cdn)
    }
  }
  print(cdnIn)
  print (cdn1nt)
  print ('=======')
  print (cdn2nt)
  print ('=======')
  print (cdn3nt)
  return(list("delta1nt"=cdn1nt,"delta2nt"=cdn2nt,"delta3nt"=cdn3nt))
