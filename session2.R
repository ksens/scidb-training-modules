rm(list=ls())
library(scidb)
scidbconnect()


################################################################
##### Project #####
#Create a reference to an array called VARIANT. 
#This array stores all the variations in the Lappalainen dataset (chromosomes 20 and 21 so far)
#When we run this line, no data is moved - only a description of the array is retrieved and stored:
VARIANT    = scidb("GEUV_VARIANT")

# Inspect the first three elements
head(VARIANT, 3)

# Project any attribute
head(project(VARIANT, "id"), 3)

################################################################
##### Subset #####

# Now select a subset of the data (chromosome 20, and given bp position range)
selection=
  project(
    subset(VARIANT, 
           chromosome_id == 20 && 
             end >= 35000110 && 
             start <= 36000110), 
    'reference, alternate')

head(selection)

################################################################
##### Subset (contd.) #####

#Now the GENOTYPE array has all the variant calls in the dataset: all the variants in VARIANT,
#called with a true/false on both alleles across 465 samples. This array is larger! 
GENOTYPE   = scidb("GEUV_GENOTYPE")


#Non-reference variant calls
gt_selection = subset(GENOTYPE,
                      "allele_1=TRUE or allele_2=TRUE")

################################################################
##### Merge (variant info with variant call info per sample) #####

# Now merge it with the selection on variant made previously 
gt_selection = merge(gt_selection, selection)

# Finally view the first few lines of this join
head(gt_selection)

################################################################
##### Aggregate (find the most frequently occuring variants) #####

#Now do a count of non-reference calls, per variant:
aggregated = aggregate(gt_selection, 
                       FUN="count(*)", 
                       by=list("start","reference", "alternate"))

#Sort and return the top 1000 most frequent:
aggregated = sort(aggregated, attributes="count", decreasing=TRUE)
aggregated = subset(aggregated, n<1000)

# Return the top 1000 variants
top_vars = iquery(aggregated, return=TRUE)
head(top_vars) 
tail(top_vars)

################################################################
##### Transform (calculate a score for non-reference variant calls) #####

selected_gt = subset(GENOTYPE, allele_1 == TRUE || allele_2 == TRUE)
selected_gt = transform(selected_gt, v="double(iif(allele_1 and allele_2, 2.0, 1.0))")
selected_gt = project(selected_gt, "v")
head(selected_gt, 3)

################################################################
##### Redimension (convert from flat array to multi-D array) #####

# We had made a selection on the `VARIANT` array before; for this example, let us assume we have a flat list
flat = unpack(selection)
str(flat)
head(flat, 3)

# Now we move from the flat array to a multi-D array.
redim = redimension(flat, dim = c("chromosome_id", "start", "end", "alternate_id"))
str(redim)
head(redim, 3)

# NOTE: You can dimension only on integer64 fields.
# The following will fail
# redim2 = redimension(flat, dim = c("chromosome_id", "start", "end", "reference"))



################################################################
##### Loading data ####

FILE='/home/scidb/eqtl/training/loading/1000genomes_populations.tsv'
system(paste("cat ", FILE))

# Primary load step
INPUT=paste("aio_input('", FILE, 
                  "', 'num_attributes=6', 'header=2')")
iquery(INPUT, return=TRUE)

# Basic error checking
SCREEN=paste("filter(", INPUT, ", error IS null)")
iquery(SCREEN, return=TRUE)

# Applying conditions on the data
FILTER=paste("filter(", SCREEN, ", a2 = 'EAS' or a2 = 'EUR' or a2 = 'AFR')")
iquery(FILTER, return=TRUE)

# Flatten the data
UNPACK=paste("unpack(", FILTER, ", i)")
iquery(UNPACK, return=TRUE)

# Redimension to keep only the data you want
REDIM=paste("redimension(", UNPACK, ", <a0:string, a1:string, a2:string>[i])")
iquery(REDIM, return=TRUE)

# Finally store the data into a new array called `temp`
# Delete the `temp` array if it already exists
if (length(scidbls("temp")) > 0) scidbrm("temp", force=TRUE)
STORE=paste("store(", REDIM, ", temp)")
iquery(STORE)

TEMP=scidb("temp")
head(TEMP)
# Check the shell script `scidb_session2_load.sh`