### Algorithm for counting unique campuses to solve colocation ###
### Computes minimum groups of schools within 3 blocks of one another and calls that one campus ###
library(sqldf)

### Load data from Justine's Query ###
data <- querydb("colocate.sql")

### Converts SQL array to R Array ###
makeArray <- function(x) {
  arr <- unlist(strsplit(substring(x, 2, nchar(x)-1), ","))
  final <- sapply(arr, function(y) as.numeric(y))
  return(final)
}

### Main Algorithm ###
countArrs <- function(arr, total_count = 0) {
  if(all(is.na(arr))) { # If all nulls return number of nulls
    total_count = length(arr)
    return(total_count)
  }
  
  else if(any(is.na(arr))) { # If mixed nulls and numbers, add number of nulls to total_count then call function on numbers
    arr_no_na <- arr[!is.na(arr)]
    num_nas <- length(arr[is.na(arr)])
    return(countArrs(arr_no_na, num_nas))
  }
  
  arr <- sort(arr) # needs to be sorted, because [3,5,1,7] e.g. would return 3 instead of 2 if not
  total_count = total_count + 1 # recursively increments count of arrays created

  if(length(arr) == 1| length(arr) == 0) {
    return(total_count) # base case, return 1
  }
  
  else {
    new_arr <- arr[1] # start with first number
    others <- arr[2:length(arr)] # the rest
    added <- c() # index for keeping track of numbers added to current array
    
    for(i in 1:length(others)) {
      if(max(dist(c(new_arr, others[i]))) <= 3){ # for each of the rest, add if it is within +/- 3 of all numbers already in array
        added <- append(added, i) # add index
        new_arr <- append(new_arr, others[i]) # adds after each iteration through loop, so next number can be compared to all
      }
      
    }
    
    if(length(others) == length(added)) { # to avoid error when we don't need to recur the function, because remaining number is 0
      return(total_count) # this is an alternate base case when length of original array > 1
    }
    
    if(!is.null(added)) {
    others_greater_than_3 <- others[-added] # numbers that weren't added to current array
    }
    
    else {
      others_greater_than_3 <- others
    }
    
    return(countArrs(others_greater_than_3, total_count)) # recursively call function with remaining numbers, and updated total count of arrays
  }
}

### Function that combines array conversion with algorithm ### 
adjustCampus <- function(x) {
  arr <- makeArray(x)
  return(countArrs(arr))
}

### Apply campus count to all arrays in data ### 
data$adjusted_campus <- sapply(data$array_agg, function(x) toString(adjustCampus(x)))
data$adjusted_campus <- sapply(data$adjusted_campus, function(x) toString(x)) # convert to string cause of weird behavior
table(data$adjusted_campus)

### Grou By Esh ID ###
agg_by_eshid <- sqldf(
"Select district_esh_id, sum(num_campus) as num_schools, sum(adjusted_campus) as adj_num_campus
from data
group by district_esh_id
order by district_esh_id
")

### Write to csv ###
View(agg_by_eshid)
write.csv(agg_by_eshid, "colocation.csv")

