# 1.   Counting variants by chromosome (really easy example)
# More to demonstrate the way in which streaming API works

# using SciDB...
#time iquery -aq "grouped_aggregate(variants, count(*) as count, chromosome)"

# using streaming...
time cat << END | iquery -af /dev/stdin
sort(
  stream(
    project(
      apply(
        variants, 
        chrom, int32(chromosome)
      ), 
      chrom
    ), 
    'R --slave -e "library(scidbstrm); map(function(x) {data.frame(as.integer(x[1,1]), count=as.integer(nrow(x)))})"', 
    'format=df', 
    'types=int32,int32', 
    'names=chromosome,count'
  ), 
  chromosome
)
END
