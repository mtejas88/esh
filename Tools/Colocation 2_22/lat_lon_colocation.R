library(geosphere)
library(caTools)
library(ggmap)
library(dplyr)
library(formattable)

### Select all schools ###
schools_query <- "
select * 
from schools
"
#schools <- dbGetQuery(con, schools_query)
schools <- read.csv('sc131a.csv')
schools$NCESSCH <- as.character(schools$NCESSCH)
length(unique(schools$NCESSCH))
length(unique(schools$LEAID))
all_districts <- unique(schools$LEAID)

#NCESSCH == school_id
#LEAID == district_id
#LATCOD
#LONCOD
### Function to compute distance ###
distance <- function(lat1,lon1,lat2, lon2) {
  distm(c(lon1, lat1), c(lon2, lat2), fun = distHaversine)
}


### Remove huge districts ###
school_counts <- schools %>% group_by(LEAID) %>% summarise(n = n())
options(scipen=100)
to_exclude <- school_counts %>% group_by(LEAID) %>% filter(n > 200) %>% summarise(n=n, district_id = LEAID)
school_counts_adj <- school_counts %>% filter %>% filter(n <= 200)
nrow(school_counts_adj)
combos <- sapply(school_counts_adj$n, function(x) choose(x, 2))
max(combos)
sum(combos)

schools_adj <- schools %>% filter(!schools$LEAID %in% to_exclude$district_id)

### Make list of all distances within district ###
# Only retain distances less than .25 miles
pairwise_distance <- function(data, dist_id) {
  schools_d1 <- data[data$LEAID == dist_id,]
  distances_d1 <- c()
  names1 <- c()
  names2 <- c()
  if(nrow(schools_d1) > 1) {
    school_comb <- combs(1:nrow(schools_d1), 2)
    
    for(i in 1:nrow(school_comb)) {
      distances_d1 <- append(distances_d1,
                             distance(schools_d1[school_comb[i,1], 25], 
                                      schools_d1[school_comb[i,1], 26], 
                                      schools_d1[school_comb[i,2], 25], 
                                      schools_d1[school_comb[i,2], 26]) * 0.000621371) # converts to miles
      names1 <- append(names1, schools_d1[school_comb[i,1], 2])
      names2 <- append(names2, schools_d1[school_comb[i,2], 2])
    }
    data.frame(cbind(names1, names2 , distances_d1))[distances_d1 < .25,]
  }
}
nrow(final)
View(final)
final <- do.call(rbind, lapply(all_districts, function(x) pairwise_distance(schools_adj, x)))
nrow(final)
write.csv(final, 'all_distances_1_23.csv')
test <- read.csv('all_distances_1_23.csv')
test <- test %>% filter(distances_d1 < .1)

### Reduce distance - need to make a decision ###
final <- final %>% filter(distances_d1 < .1)

### Collapse into campus groups ###
final_collapsed <- final %>% group_by(names1) %>% summarise(total_group = paste(names2, collapse=","))
nrow(final_collapsed) == length(unique(final$names1))

# Add center school to its own campus group
final_collapsed$all_schools <- paste(final_collapsed$total_group, final_collapsed$names1, sep = ",")
final_collapsed <- final_collapsed[,c(1,3)]
final_collapsed$group_name <- paste0('group_', final_collapsed$names1)

# Function for exapnding array and campus group names
flatten <- function(ids, name) {
  split_ids <- unlist(strsplit(ids, split=","))
  split_names <- rep(name, length(split_ids))
  data.frame(cbind(split_ids, split_names))
}

final_expanded <- do.call(rbind,apply(final_collapsed, 1, function(x) flatten(x[2], x[3])))

nrow(final_expanded)
length(unique(final_expanded$split_ids))
final_expanded %>% group_by(split_names) %>% summarise(n=n()) #%>% filter(n > 1)

# Recollapse by id, aggregate campus groups into one field
recollapsed <- final_expanded %>% group_by(split_ids) %>% summarise(total_group = paste(split_names, collapse=","))
length(unique(recollapsed$split_ids))

reco_state <- merge(recollapsed, schools, by.x='split_ids', by.y='esh_id')
state_co <- table(reco_state$postal_cd)
state_all <- table(schools$postal_cd[schools$postal_cd != 'HI'])

table(reco_state$locale) / table(schools$locale[schools$postal_cd != 'HI'])

write.csv(recollapsed, 'campus_groupings_1_23.csv')

write.table(round(state_co/state_all, digits=2), 'state_collocation.csv')

# Find those that belong to more than one campus group
test <- final_expanded %>% group_by(split_ids) %>% summarise(n = n(), total_group = paste(split_names, collapse=",")) %>% filter(n >1)
test <- final_expanded %>% group_by(split_names) %>% summarise(n = n()) %>% filter(n <2)

test <- read.csv('campus_groupings_1_19.csv') 



