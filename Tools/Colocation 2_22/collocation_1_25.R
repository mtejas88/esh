#### Collocation 1/25 ###
library(dplyr)
library(reshape2)

setwd("~/Desktop/R Projects/Collocation")
distances <-read.csv('all_distances_1_23.csv')
colnames(distances)
distances <- distances %>% filter(distances_d1 < .1)
distances_sub <- distances[,c(2,3)]
options(scipen=100)

### Function for creating campus groups recursively ###
find_campuses <- function(id_list, distances, master = c()) { # structure creates record for each entry in col1, not unique
  if(length(id_list) == 0) { # is this the right base case? 
    master <- unique(master) # remove dups
    na_length <- 28 - length(master) # max campus size = 28 and we want to be equal length for rbind
    master <- c(master, rep(NA, na_length))
    return(master)
  }
  else {
    id <- id_list[1]
    col1_matches <- distances$names1[distances$names2 == id]
    col2_matches <- distances$names2[distances$names1 == id]
    master <- append(master, c(col1_matches, col2_matches, id))  # add id for first one, remove dups later, not efficient
    
    distances <- distances[distances$names2 != id,] # remove any schools that are now included in campus
    distances <- distances[distances$names1 != id,] # from both lists!
    print(nrow(distances))
    id_list <- append(id_list, c(col1_matches, col2_matches))
    id_list <- id_list[-1]
    id_list <- unique(id_list)
    # recursive function
    find_campuses(id_list, distances, master)
  }
}

### Call function on each ID ###
campuses <- do.call(rbind, lapply(distances$names1, function(x, distances) find_campuses(c(x), distances), distances = distances))
View(campuses)

### QA ###
test <- do.call(rbind, list(find_campuses(c(120126001278), distances)))
test2 <- do.call(rbind, list(find_campuses(c(120126003431), distances)))

test2 <- do.call(rbind, list(find_campuses(c(120126003431), distances$names1, distances$names2)))
test[!test %in% test2]
distances$names1[distances$names2 == 120126003431]
length(distances$names2[-c(which(distances$names1 == 120126007738))])

### Remove duplicates ###
sorted <- t(apply(campuses,1,sort, na.last = T)) # needs to be sorted by row to find all dups
unique_campuses <- unique(sorted)
View(unique_campuses)

### QA ###
# Distribution of number of schools in campuses
campus_size_dist <- apply(unique_campuses, 1, function(x) length(x[!is.na(x)]))
table(campus_size_dist)

### Write CSV
write.csv(unique_campuses, 'unique_campuses_1_26.csv')

### Tranform Data ###
raw <- read.csv('unique_campuses_1_26.csv')
raw$campus_group <- paste0('group_', 1:nrow(raw))
raw <- raw[,-c(1)]

long <- melt(raw, idvars='campus_group', na.rm = T)
size_counts <- long %>% group_by(campus_group) %>% summarise(number = n()) %>% group_by(number) %>% summarise(final_number = n())
size_counts

table(long$campus_group)
long <- long[,c(1,3)]

### One School Campuses ###
schools <- read.csv('sc131a.csv')

one_school <- schools$NCESSCH[!schools$NCESSCH %in% long$value]
one_school_df <- data.frame(cbind(campus_group = paste0('campus_group_', one_school), value = one_school))

combined <- rbind(long, one_school_df)
size_counts <- final_campuses_merge %>% group_by(campus_group) %>% summarise(number = n()) %>%
  group_by(number) %>% summarise(final_number = n())

colnames(combined) <- c('campus_group', 'school_id')

### Join to Schools ### 
final_campuses_merge <- merge(combined, schools, by.x='school_id', by.y='NCESSCH')
nrow(final_campuses_merge)

write.csv(final_campuses_merge, 'campuses_upload_1_27.csv')


### QA ###
test <- read.csv('campuses_upload_1_27.csv')
colnames(test)
test[test$school_id == '913579']
