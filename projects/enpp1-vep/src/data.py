import os
import sys
import re

import numpy as np
import pandas as pd

sys.path.append('../../../src')
from consulting import data

if __name__ == '__main__':
    clinvar_df = data.read_clinvar(test_set=True)