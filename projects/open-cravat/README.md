

```
grep -v '^#' genome_Kirk_Gosik_v4_Full_20250130212959.txt |  awk -v OFS='\t' '{print "chr"$2, $3,"+", substr($4, 1, 1), substr($4,2,1)}' > genome_clean.txt
```

```
pip install open-cravat
oc module install-base
oc module install clinvar cosmic
oc run -a clinvar -l hg19 genome_clean.txt 
```

