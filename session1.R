######################################################################################################
## SciDB is a good backend for R

# data in R
str(iris)

# Connect with SciDB cluster
library(scidb)
scidbconnect()

# Upload to SciDB
IRIS=as.scidb(iris)
IRIS

# Now download and inspect the data in R
str(IRIS[])

######################################################################################################
## Selection in SciDB (Variant Data)

# Create an R reference to Variant data for Geuvadis project (Lappalainen et al. 2003)
VARIANT=scidb("GEUV_VARIANT") 

# Now select a subset of the data (chromosome 20, and given bp position range)
selection=
  project(
    subset(VARIANT, 
           chromosome_id == 20 && 
             end >= 35000110 && 
             start <= 36000110), 
    'reference, alternate')

# finally view the first few elements of this query only
head(selection)

######################################################################################################
## Aggregation in SciDB

# Overall count
count(VARIANT)

# Count by chromosome
aggregate(VARIANT, 
          'count(*)',
          by='chromosome_id')[]

# Now connect with the Genotype array, and run some counts
GENOTYPE = scidb('GEUV_GENOTYPE')

# note we use a smarter way of running the count here
source('~/eqtl/internal/ami_functions.R') #Will output "creating a generic function for 'image'... that is normal
summarize(GENOTYPE)$count

######################################################################################################
## Combining multiple lines of evidence

#Non-reference variant calls
gt_selection = subset(GENOTYPE,
                      "allele_1=TRUE or allele_2=TRUE")

# Now merge it with the selection on variant made previously 
gt_selection = merge(gt_selection, selection)

# Finally view the first few lines of this join
head(gt_selection)

######################################################################################################
## PCA (principal component analysis) for visualizing sub-groups

svded = scidb("GEUV_VAR_SVD")
str(svded)
#Download just the 3 vectors into R and make a matrix out of them:
svd_top = df2xyvm(iqdf(subset(svded, i<=2), n=Inf))
#Do kmeans clustering of these vectors in R now:
clustering = kmeans(svd_top, 5, nstart=50)
#Convert the kmeans cluster assignments to colors
color=gsub("[0-9]","",palette()[clustering$cluster+1])
#Plot. You can mouse over the plot and spin it around:
library(threejs)
scatterplot3js(svd_top, size=0.4, color=color, renderer="canvas")  

######################################################################################################
## SciDB array schema

# First, for a very simple array - 1 dimension, 1 attribute
SAMPLE = scidb("GEUV_SAMPLE")
head(SAMPLE, 3)
str(SAMPLE)

# Now, a multidimensional array -- multiple dimensions, multiple attributes
VARIANT = scidb("GEUV_VARIANT")
head(VARIANT, 3)
str(VARIANT)

######################################################################################################
## RESTful API

# Run the following from the Unix command line

# Obtain a new shim session ID
s=`curl -s "http://localhost:8080/new_session"`

# The URL-encoded SciDB query in the next line is just:
# build(<x:double>[i=1:10,10,0],u)
curl -s "http://localhost:8080/execute_query?id=${s}&query=build(%3Cx:double%3E%5Bi=1:10,10,0%5D,i)&save=(double)"

# Pass the double-precision binary result through the `od` program to view:
curl -s "http://localhost:8080/read_bytes?id=${s}" | od -t f8

# Release the session
curl -s "http://localhost:8080/release_session?id=${s}"
