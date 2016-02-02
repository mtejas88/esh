###	Expected Percentags ###
#	Author: Carson Forter
#	Created On Date: 2/2/2016
#	Last Modified Date: 2/2/2016
#	Name of QAing Analyst: Still needs to be QAed

library(dplyr)

# Pull in all districts
dists <- dbGetQuery(con, paste0(
  'select * 
  from districts'))

# Convert to numeric dummy variable
# Indicates if district is meeting goals or not.
dists$ia_bandwidth_per_student <- as.numeric(as.character(dists$ia_bandwidth_per_student))
dists$meet_goals <- ifelse(dists$ia_bandwidth_per_student >= 100, 1, 0)

# Function for computing expected percentage overall
# and percentage grouped by factor, e.g. locale
expect <- function(factor, dummy) {
  cat(noquote(paste0("Expected, if independent: ", round(mean(dummy, na.rm=T) * 100, 1), "%")))
  factor_percentage <- aggregate(dummy ~ factor, FUN=function(x) paste0(round(mean(x, na.rm=T)*100,1),"%"))
  factor_count <- aggregate(dummy ~ factor, FUN=function(x) length(x))
  cat(noquote("\n\nActual observed:\n"))
  factor_data <- data.frame(merge(factor_percentage, factor_count, by.x="factor", by.="factor"))
  colnames(factor_data) <- c("Factor","Percentage", "Count")
  print(factor_data)
  }

# Test function on locale, size, and state
expect(dists$locale, dists$meet_goals)
expect(dists$district_size, dists$meet_goals)
expect(dists$postal_cd, dists$meet_goals)
