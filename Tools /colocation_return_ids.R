### Algorithm For Sorting Schools Into Campuses ###
#	Author: Carson Forter
#	Created On Date: 11/18/2015
#	Last Modified Date: 11/20/2015
#	Name of QAing Analyst: Still needs to be QAed

### NOTE:
# Need to mske this so that each school has a record
# as opposed to each street, and have a columns
# that has a unique identifier for each
# campuse, likely a concatenation of street
# plus a number

### Load data ###
# This query was authored by justine
# and returns a record for each street in each district
# with a list of schools on that street
data <- querydb("colocate.sql")

### Function for Sorting Schools Into Campuses ###
# Sorts so that no pair of schools in the campus are more than 
# three blocks frome each other. Assumes schools with null 
# addresses are not colocated with any other schools. Returns 
# a list schools, where colocated schools are grouped together
# in an array.
GroupAddress <- function (array, return.array=null, blocks) {
  return.array <- return.array[order(array, na.last=T)]
  array <- sort(array, na.last=T)
  idx <- 1 # keeps track of array in list
  output <- list(c())
  output.index <- list(c())
  num.location <- 1 # keeps track of index within each array
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
adjusted_campus <- apply(data, 1, function(all_data) AdjustCampus(all_data[3], all_data[4]))
length(adjusted_campus)

data$adjusted_campus <- apply(data, 1, function(all_data) AdjustCampus(all_data[3], all_data[4]))

### Restructure data ###

### Right Approach ###
# Represent the number of campuses
# Achieves this by counting total arrays created by function above
original_length <- lapply(adjusted_campus, function(x) length(x))
original_length <- unlist(original_length)

# Replicates campus street and district esh id
# equal to the number of campuses
campus_street <- c(rep(data$address_street, original_length))
district_id <- c(rep(data$district_esh_id, original_length))

# Creates a sequemnce of numbers for each street
# Starts at one and goes up to the number campuses on that street
campus_num <- sapply(original_length, function(x) 1:x)
campus_num <- unlist(campus_num)

# Concatenates street and numbers
campus_id <- paste0(campus_street, "_", campus_num)

# Represents the number of schools
# Achieves this by summing the length of all arrays created by function above
length_campuses <- lapply(adjusted_campus, function(x) lapply(x, function(x) length(x)))
length_campuses <- unlist(length_campuses)

# Replicates district id for each school
district_id_expanded <- rep(district_id, length_campuses)

# Replicates campus id for each school
expanded_id <- rep(campus_id, length_campuses)

# Flattens out list of schools to a single array
school_ids <- unlist(unlist(adjusted_campus))

#Combine columns
final <- data.frame(cbind(school_ids, expanded_id, district_id_expanded))
final$final_campus_id <- paste0(district_id_expanded, "_", expanded_id)
final <- final[c(-2)]

### View data, write to csv ###
View(final)
View(data)
write.csv(final, "campus_lookup_v3.csv")
length(unique(final$final_campus_id))


##########################################################################
### Bad Approaches - for reference ###
schools <- c()
campus_id <- c()
id_index <- 1
for(record in adjusted_campus){
  for(campus_group in adjusted_campus) {
    id <- paste0("_", toString(id_index))
    for(school in campus_group) {
      schools <- append(schools, school)
      campus_id <- append(campus_id, id)
    }
    id_index <- id_index + 1
  }
}

campus_id <- c()
id_index <- 1
for(record in adjusted_campus){
  for(campus_group in adjusted_campus) {
    id <- paste0("_", toString(id_index))
      campus_id <- append(campus_id, rep(id, length(campus_group)))
    }
    id_index <- id_index + 1
}

campus_id <- c()
id_index <- 1
for(record in adjusted_campus){
  campus_id <- append(campus_id, lapply(adjusted_campus, function(x, arg1) {
    id <- paste0("_", toString(arg1))
    rep(id, length(campus_group))
    
  },
  arg1=id_index
  ))
  id_index <- id_index + 1
}