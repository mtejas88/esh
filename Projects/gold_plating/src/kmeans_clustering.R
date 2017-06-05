## =========================================
##
## clustering by bw, 
##  initial query, for internal comparisons
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("dplyr" ,"rgl")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(rgl)

##districts_deluxe and manipulations
districts <- read.csv("C:/Users/Justine/Documents/GitHub/ficher/Projects/gold_plating/data/raw/districts_deluxe.csv")
districts$ia_monthly_cost_total <- ifelse (districts$ia_monthly_cost_total > 0, districts$ia_monthly_cost_total, 0)
districts$wan_monthly_cost_total <- ifelse (districts$wan_monthly_cost_total > 0, districts$wan_monthly_cost_total, 0)
districts$monthly_cost_total <- districts$ia_monthly_cost_total + districts$wan_monthly_cost_total

districts$ia_bw_mbps_total <- ifelse (districts$ia_bw_mbps_total > 0, districts$ia_bw_mbps_total, 0)

districts$include_in_universe_of_districts_all_charters <- ifelse (districts$include_in_universe_of_districts_all_charters== 'true', 
                                                                   TRUE,
                                                                   FALSE)
districts$exclude_from_ia_cost_analysis <- ifelse (districts$exclude_from_ia_cost_analysis== 'true',
                                                   TRUE,
                                                   FALSE)

#clean districts
districts_clean <- filter(districts, include_in_universe_of_districts_all_charters == TRUE)
districts_clean <- filter(districts_clean, exclude_from_ia_cost_analysis == FALSE)

#correlation analysis
districts_clean_clust <- select(districts_clean, esh_id, num_students, monthly_cost_total, ia_bw_mbps_total)
round(cor(districts_clean_clust[,2:4]), 2)

#pca
pc <- princomp(districts_clean_clust[,2:4], cor=TRUE, scores=TRUE)
summary(pc)

#pca plots
plot(pc,type="lines")
biplot(pc)
plot3d(pc$scores)

#k-means
set.seed(42)
k = 6
cl <- kmeans(districts_clean_clust[,2:4],k)
districts_clean_clust$cluster <- as.factor(cl$cluster)
#plot k-means
plot3d(pc$scores, col=districts_clean_clust$cluster, main="k-means clusters")

di <- dist(districts_clean_clust[,2:4], method="euclidean")
tree <- hclust(di, method="ward")
districts_clean_clust$hcluster <- as.factor((cutree(tree, k=k)-2) %% 3 +1)
plot(tree, xlab="")

#comparing averages 
summarize(districts_clean_clust, 
          average_cost = mean(monthly_cost_total, na.rm = T), 
          average_bandwidth = mean(ia_bw_mbps_total, na.rm = T), 
          average_students = mean(num_students, na.rm = T),
          districts = n())

clusters <- group_by(districts_clean_clust, cluster)
summarize(clusters, 
          average_cost = mean(monthly_cost_total, na.rm = T), 
          average_bandwidth = mean(ia_bw_mbps_total, na.rm = T), 
          average_students = mean(num_students, na.rm = T),
          districts = n())
