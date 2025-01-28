import os
import requests, sys

from typing import Dict

from flytekit import task, workflow


@task
def call_ensembl(id:str) -> Dict:
    server = "https://rest.ensembl.org"
    ext = f"/overlap/id/{id}?feature=gene"
    r = requests.get(server+ext, headers={ "Content-Type" : "application/json"})
    if not r.ok:
       r.raise_for_status()
       sys.exit()

    decoded = r.json()
    return repr(decoded)

@workflow
def wf_ensembl(id: str="ENSG00000157764") -> Dict:
    """
    Calling ensembl API

    This workflow takes an ensembl id and calls the API to return 
    any overlapping features.

    Parameters
    ----------
    id : str
        id string
    
    Returns
    -------
    out : Dict
        return dictionary output
    """
    
    return call_ensembl(id)
  