#!/bin/bash

sudo apt update && sudo apt install \
    texlive-latex-base texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-fonts-extra -y

# python TEX package
## example: chevron config.yaml template.tex > output.tex
pip install chevron
