library(scidbstrm)
library(IRanges)
# Obtain the replicated genes array from SciDB
genes <- data.frame(getChunk(), stringsAsFactors=FALSE)
# function mapped on streaming chunks
f <- function(x)
{
  chromosome <- as.integer(x$chrom[1]) # ... a bit wasteful (they are all the same)
  ir1 <- IRanges(start=x$start, end=x$start + nchar(x$ref))
  g <- genes[genes$chromosome==chromosome, c("start", "end", "gene")] # filter down to our chunk's range
  ir2 <- IRanges(start=g$start, end=g$end)
  ans <- findOverlaps(ir1, ir2)
  # return string,int32,int32
  data.frame(gene=g$gene, chromosome=chromosome, count=as.integer(countRnodeHits(ans)), stringsAsFactors=FALSE)
}

map(f)
