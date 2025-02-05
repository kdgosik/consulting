from pathlib import Path
from typing import NamedTuple

import matplotlib.pyplot as plt
import pandas as pd
import requests
from flytekit import conditional, kwtypes, task, workflow
from flytekit.extras.tasks.shell import OutputLocation, ShellTask
from flytekit.types.file import FlyteFile, PNGImageFile

