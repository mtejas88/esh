###	Percent Fiber By District ###
#	Author: Carson Forter
#	Created On Date: 11/17/2015
#	Last Modified Date: 11/17/2015
#	Name of QAing Analyst: Still needs to be QAed

library(dplyr)
library(ggplot2)

district_pct <- querydb("percent_fiber_district.sql") # modification of Justine's fiber query
hist(district_pct$pct_scalable, breaks=10, col="dodgerblue", border="white", xlab= "Percent Scalable", main="Distribution of Scalable Buildings By District")
write.csv(district_pct, "Percent_Fiber_By_District.csv")
district_pct %>%
  group_by(postal_cd) %>%
  summarise(state_means = mean(pct_scalable)) %>%
  with(barplot(state_means), names.ar=postal_cd)

state_hists

ggplot(district_pct, aes(x=pct_scalable, fill=postal_cd)) +
  geom_histogram(binwidth=.1, alpha=.5, position="identity")

ggplot(district_pct, aes(x=pct_scalable, fill=postal_cd)) +
  geom_density()
state_hists
?barplot
 