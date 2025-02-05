from pathlib import Path
from typing import NamedTuple

import matplotlib.pyplot as plt
import pandas as pd
import requests
from flytekit import conditional, kwtypes, task, workflow
from flytekit.extras.tasks.shell import OutputLocation, ShellTask
from flytekit.types.file import FlyteFile, PNGImageFile


blastx_on_shell = ShellTask(
    name="blastx",
    debug=True,
    script="""
    mkdir -p {inputs.outdir}

    query={inputs.datadir}/{inputs.query}
    db={inputs.datadir}/{inputs.db}
    blastout={inputs.outdir}/{inputs.blast_output}

    blastx -out $blastout -outfmt 6 -query $query -db $db >> {outputs.stdout} 2>&1
    """,
    inputs=kwtypes(datadir=str, query=str, outdir=str, blast_output=str, db=str),
    output_locs=[
        OutputLocation(var="stdout", var_type=FlyteFile, location="stdout.txt"),
        OutputLocation(
            var="blastout",
            var_type=FlyteFile,
            location="{inputs.outdir}/{inputs.blast_output}",
        ),
    ],
)


@task
def is_batchx_success(stdout: FlyteFile) -> bool:
    if open(stdout).read():
        return False
    else:
        return True


@workflow
def blast_wf(
    datadir: str = "kitasatospora",
    outdir: str = "output",
    query: str = "k_sp_CB01950_penicillin.fasta",
    db: str = "kitasatospora_proteins.faa",
    blast_output: str = "AMK19_00175_blastx_kitasatospora.tab",
) -> BLASTXOutput:
    stdout, blastout = blastx_on_shell(datadir=datadir, outdir=outdir, query=query, db=db, blast_output=blast_output)
    result = is_batchx_success(stdout=stdout)
    final_result, plot = (
        conditional("blastx_output")
        .if_(result.is_true())
        .then(blastx_output(blastout=blastout))
        .else_()
        .fail("BLASTX failed")
    )
    return BLASTXOutput(result=final_result, plot=plot)


if __name__ == "__main__":
    print("Downloading dataset...")
    download_dataset()
    print("Running BLASTX...")
    print(f"BLASTX result: {blast_wf()}")