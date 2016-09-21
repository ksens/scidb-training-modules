rm(list=ls())
library(scidb)
library(scidbstrm)
scidbconnect()

################################################################
##### Streaming (identity function) #####
# Execute the following at the Unix terminal

## ``````````````````````````````````````
cat << END | iquery -af /dev/stdin

stream(build(<val:double> [i=1:5,5,0], i),
       'R --slave -e "library(scidbstrm); map(I)"',
       'format=df', 'types=double')

END
## ``````````````````````````````````````

##### Streaming (simple aggregate) #####

# First note that we are using slightly different variant arrays for this example than the Geuvadis data

# List of human gene coordinates from https://www.pharmgkb.org/ 
gene1 = scidb("genes")
head(gene1)
count(gene1) # About 23k genes

# All the variants in the 1000 genomes dataset (combined sum of all file sizes is about 15 GB)
variant1 = scidb("variants")
count(variant1)
counts = aggregate(variant1, FUN="count(*)", by="chromosome")[]
counts[order(counts$chromosome), ]

# Just for a reference, compare the data size with that of the Geuvadis dataset
VARIANT = scidb("GEUV_VARIANT")
counts = aggregate(VARIANT, FUN="count(*)", by="chromosome_id")[]
counts[order(counts$chromosome), ]

# Execute the following at the Unix terminal

## ``````````````````````````````````````
source ~/eqtl/training/session3/simple_stream.sh
## ``````````````````````````````````````

# Now inspect the code

### View the file using your file browser: 
# ==> /home/scidb/eqtl/training/simple_example.sh

##### Streaming (range join) #####

# Let's inspect the R code first this time

### View the file using your file browser: 
# ==> /home/scidb/eqtl/training/session3/range.R

# Then let us run the code via SciDB in RStudio
x = scidb("stream(apply(variants, chrom, int32(chromosome)),
          'Rscript /home/scidb/eqtl/training/session3/range.R', 
          'format=df', 
          'types=string,int32,int32', 
          'names=gene,chromosome,count',
          _sg(genes,0))")
t1 = proc.time(); ans = x[, drop=TRUE]; proc.time()-t1

ans = ans[order(ans$count, decreasing=TRUE), ]
head(ans, n=10)

################################################################
##### OVERFLOW ITEMS FROM SESSION 2 NOW ####

################################################################
##### scidbeval ####

T=scidb("build(<val:double>[i=0:3,4,0], random())")
T=scidbeval(T, temp = TRUE)
T@name  # this is a temp array created in SciDB by the R interface
head(T)

################################################################
##### Exercise: Advanced analytics ####
# Hardy-Weinberg Equilibrium: As an example of usage of different operations described in previous session

source('~/eqtl/lappalainen/2-genotype-qc/genotype_qc.R') 

# Note that we are back to working on the Geuvadis dataset (i.e. data shared in Lappalainen et al.)
hardy_weinberg_equilibrium(chromosome = 20, start_coord = 10000240, end_coord = 12000240)

################################################################
##### Exercise: Load Gene coordinates ####

# View the code for loading Entrez gene coordinates at:
# https://github.com/Paradigm4/eQTL/blob/master/lappalainen/0-metadata/loaders.sh

# Now view the loaded data
GENE = scidb("ENTREZ_GENE")
str(GENE)
head(GENE)
# Note that chromosome is a string and may need to be mapped to int64-s. Shown in the steps below. 

################################################################
##### Non-integer dimensions ####

# use index_lookup
CHROMOSOME = scidb("GEUV_CHROMOSOME")
head(index_lookup(GENE, CHROMOSOME, attr="chromosome", new_attr="chromosome_id"))
