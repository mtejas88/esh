### Fuzzy Matching ###
#	Author: Carson Forter
#	Created On Date: 12/28/2015
#	Last Modified Date: 12/28/2015
#	Name of QAing Analyst: Still needs to be QAed

# Find best matches in list of service providers
# Uses fuzzy matching to find similar text strings

# Daniel's list
sps <- read.csv("sps.csv")
sps <- data.frame(sps[,-2])
colnames(sps) <- "potential_sps"
View(sps)

# All SPs in line_items table
li_sps <- dbGetQuery(con, "select service_provider_name from line_items")
nrow(li_sps)
li_sps <- unique(li_sps)
nrow(li_sps)

# Matching
dist.name <- adist(sps$potential_sps, li_sps$service_provider_name, partial = TRUE, ignore.case = TRUE)
dist.name
min.name <- apply(dist.name, 1, min)
min.name
match.s1.s2<- NULL

for(i in 1:nrow(dist.name))
{
  s2.i <- match(min.name[i],dist.name[i,])
  s1.i <- i
  match.s1.s2 <- rbind(data.frame(s2.i=s2.i,s1.i=s1.i,
                                  s2name=li_sps$service_provider_name[s2.i], 
                                  s1name=sps$potential_sps[s1.i], adist=min.name[i]),match.s1.s2)
}

final <- match.s1.s2[,-c(1,2)]
colnames(final) <- c('line_items_sp', 'daniels_sp', 'distance')
View(final)

write.csv(final, "sps_with_match.csv")
