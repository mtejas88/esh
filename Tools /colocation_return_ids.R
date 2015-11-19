### Algorithm For Sorting Schools Into Campuses ###
#	Author: Carson Forter
#	Created On Date: 11/18/2015
#	Last Modified Date: 11/18/2015
#	Name of QAing Analyst: Still needs to be QAed

### Function for Sorting Schools Into Campuses ###
# Sorts so that no pair of schools in the campus are more than 
# three blocks frome each other. Assumes schools with null 
# addresses are not colocated with any other schools. Returns 
# a list schools, where colocated schools are grouped together
# in an array.
GroupAddress <- function (array, return.array=null, blocks) {
  return.array <- return.array[order(array, na.last=T)]
  array <- sort(array, na.last=T)
  idx <- 1
  output <- list(c())
  output.index <- list(c())
  num.location <- 1
  for(num in array) {
    if(!is.null(output[[idx]])) {
      if(is.na(num)) {
        idx <- idx + 1
      }
      else if(max(dist(c(num, output[[idx]]))) > blocks) {
        idx <- idx + 1
      }
    }
    if(length(output) < idx) {
      output[[idx]] <- c(num)
      output.index[[idx]] <- c(num.location)
    }
    else {
      output[[idx]] <- append(output[[idx]], num)
      output.index[[idx]] <- append(output.index[[idx]], num.location)
    }
    num.location <- num.location + 1
  }
  lapply(output.index, function(x) return.array[x])
}

### Converts SQL array to R Array ###
MakeArray <- function(x) {
  arr <- unlist(strsplit(substring(x, 2, nchar(x)-1), ","))
  final <- sapply(arr, function(y) as.numeric(y))
  return(final)
}

### Function that combines array conversion with algorithm ### 
AdjustCampus <- function(adds, esh_ids) {
  adds <- MakeArray(adds)
  esh_ids <- MakeArray(esh_ids)
  return(GroupAddress(adds, esh_ids,3))
}

### Apply campus count to all arrays in data ### 
data$adjusted_campus <- apply(data, 1, function(all_data) toString(AdjustCampus(all_data[3], all_data[4])))

### View Data, Write to CSV ###
View(data)
write.csv(data, "campus_groups.csv")
