import os
import sys
import subprocess
import re

# Data
import numpy as np
import pandas as pd

# ML
import sklearn

#Plotting
import matplotlib.pyplot as plt
import seaborn as sns


sys.path.append('../../../src')
from consulting.config import *
from consulting.utils import *

def read_cyp_enzyme_data():
    """
    Reads in the cyp enzyme data and processes it to be used in the variant effect map

    Parameters
    ----------

    Returns
    -------
    df - pd.DataFrame - cyp enzyme data
    """
    
    
    print('Reading in CYP data...')
    ## variant - cDNA position
    df = (
        pd.read_csv('../data/raw/DMS-CYP-Enzymes - table1_cyp2c9.csv')
    )

    return df
