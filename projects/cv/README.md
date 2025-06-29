
##  Approach
We’ll use:
✅ A config.yaml file with your data
✅ A template (.tex or .md)
✅ A tool to render it — e.g. Pandoc + mustache / pandoc templates / LaTeX directly


## Render with Pandoc
pandoc + mustache installed or use pandoc's native --template:

```{bash}
pandoc cv_template.md --metadata-file=config.yaml -o cv.pdf
```

or for HTML/Word:

```{bash}
pandoc cv_template.md --metadata-file=config.yaml -o cv.html
pandoc cv_template.md --metadata-file=config.yaml -o cv.docx
```


## Install Packages

```{bash}
sudo apt update && sudo apt install \
    texlive-latex-base texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-fonts-extra -y


## python TEX package
pip install chevron
chevron config.yaml template.tex > output.tex
pdflatex output.tex

## clean-up
rm output.*
```