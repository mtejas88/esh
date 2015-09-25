### Load packages ###
# If reshape2 is not already installed also run install.packages(reshape2)
require(reshape2)

### Set working directory. This may vary depending on computer ###
setwd("~/Desktop/R Projects/Rep Sampling")

### Load Data ###
districts <- read.csv("rep_sample_districts_9_24.csv")
#districts_verified <- districts[which(districts$num_open_dirty_flags==0), ]
districts_verified <- districts[which(districts$exclude_from_analysis=="FALSE"), ]


### Load sample size requirements and collapse to single vector ###
sample_90 <- read.csv("sample_90_923.csv")
sample_95 <- read.csv("sample_95.csv")
sample_99 <- read.csv("sample_99.csv")

melt_samples <- function(data) {
  sample_melt <- melt(data, id.vars="postal_cd")
  sample_melt$locale <- factor(c(rep(c(rep("Urban", 51),
                                          rep("Suburban",51),
                                          rep("Small Town",51),
                                          rep("Rural",51)),5))) 
  sample_melt$district_size <- factor(c(rep("Tiny", 204),
                                  rep("Small",204),
                                  rep("Medium",204),
                                  rep("Large",204),
                                  rep("Mega",204)))
  return(sample_melt)
}

sample_90_melt <- melt_samples(sample_90)
sample_95_melt <- melt_samples(sample_95)
sample_99_melt <- melt_samples(sample_99)

### Include clean states only ### 

clean_states <- c("AK","AL","AZ","DC","DE","GA","IL","IN","KS","KY","LA","MA","ME","MN","MO","MT","NC","OK","OR","RI",
                  "SC", "SD","VA","VT","WA")

# Also use this list to return samples only from a particular state 
# For example to just return Arizona sample run: 
clean_states <- c("OH")

sample_90_melt <- subset(sample_90_melt, sample_90_melt$postal_cd %in% clean_states)
sample_95_melt <- subset(sample_95_melt, sample_95_melt$postal_cd %in% clean_states)
sample_99_melt <- subset(sample_99_melt, sample_99_melt$postal_cd %in% clean_states)

### Subsets ###
area_type <- unique(districts$locale)
size <- unique(districts$district_size)

### Function for taking sample and writing to csv ###
make_sample <- function(subset_state, subset_locale, subset_size, sample_size) {
  population_subset <- districts_verified[which(districts_verified$postal_cd == subset_state & 
                                                  districts_verified$locale == subset_locale & 
                                                  districts_verified$district_size == subset_size), ]
  # Raises error if subset > population
  tryCatch(
    sample_subset <- population_subset[sample(nrow(population_subset), sample_size), ],
    error = function(e) {stop(paste(
      'Not enough clean districts for',subset_state, subset_locale, subset_size, toString(nrow(population_subset)),toString(sample_size))); 
      print(e); e })
  if(nrow(population_subset) == 0 && sample_size == 1) {
    print(paste('Not enough clean districts for',subset_state, subset_locale, subset_size, toString(nrow(population_subset)),toString(sample_size)))
  }
  csv_name <- paste0(subset_state, "_", subset_locale, "_", toString(subset_size), "_sample_90.csv")
  write.csv(sample_subset, file = csv_name)
}


### Function for creating sample at different confidenc levels ###
create_tables <- function(confidence_level) {
  if(confidence_level == 90) {
    errors <- apply(sample_90_melt, 1, function(variables) try(make_sample(variables[1], variables[4], variables[5], variables[3])))
    errors_clean <- unlist(errors)
    print(errors_clean)
  }
  else if(confidence_level == 95) {
    errors <- apply(sample_95_melt, 1, function(variables) try(make_sample(variables[1], variables[4], variables[5], variables[3])))
    errors_clean <- unlist(errors)
    print(length(errors_clean))
  }
  else if(confidence_level == 99) {
    errors <- apply(sample_99_melt, 1, function(variables) try(make_sample(variables[1], variables[4], variables[5], variables[3])))
    errors_clean <- unlist(errors)
    print(length(errors_clean))
  }
}

### Run sampling here ###
setwd("~/Desktop/R Projects/Rep Sampling/CSVs")
create_tables(90)

 ### Combine CSVs ###
setwd("~/Desktop/R Projects/Rep Sampling/CSVs")
filenames <- list.files()
master <- do.call("rbind", lapply(filenames, read.csv, header = T, stringsAsFactors = F))
setwd("~/Desktop/R Projects/Rep Sampling")
write.csv(master, "OH_9_24_EFA.csv")

### REMOVES ALL FILES IN DIRECTORY ###
setwd("~/Desktop/R Projects/Rep Sampling/CSVs")
filenames <- list.files()
do.call(file.remove,list(filenames))

### Testing ###
NE_sample <- subset(districts_verified, districts_verified$postal_cd == "AR" & districts_verified$locale == "Rural" & districts_verified$district_size == "Small")

sample_subset <- NE_sample[sample(nrow(NE_sample), 1), ]
nrow(NE_sample)
