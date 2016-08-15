#/bin/bash

# Primary load step
INPUT="aio_input('/home/scidb/eqtl/training/loading/1000genomes_populations.tsv', 'num_attributes=6', 'header=2')"
iquery -aq "$INPUT" | head

# Basic error checking
SCREEN="filter($INPUT, error IS null)"
iquery -aq "$SCREEN" | head

# Some conditions
FILTER="filter($SCREEN, a2 = 'EAS' or a2 = 'EUR' or a2 = 'AFR')"
iquery -aq "$FILTER" | head

# Flatten the data
UNPACK="unpack($FILTER, i)"
iquery -aq "$UNPACK" | head

# Redimension to keep only the data you want
REDIM="redimension($UNPACK, <a0:string, a1:string, a2:string>[i])"
iquery -aq "$REDIM" | head

# Finally store the array (first remove the temp array if it exists)
iquery -aq "remove(temp)" > /dev/null 2>&1
echo
echo "Final query:"
echo $REDIM
echo
iquery -aq "store($REDIM, temp)"

# Now run a count on the stored array
echo "Run a final count:"
iquery -aq "op_count(temp)"