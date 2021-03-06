## =========================================
##
## CLUSTER DATA: Generate K-Means Clusters
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("fpc", "cluster")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(fpc) ## for pamk function
library(cluster) ## for pam and clusGap function

##**************************************************************************************************************************************************
## read in data

dta <- read.csv("data/interim/all_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dta.mega.large <- read.csv("data/interim/mega_large_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## Cluster data

## K-Means:
## K-means clustering can handle larger datasets than hierarchical cluster approaches.
## Additionally, observations are not permanently committed to a cluster.
## They are moved when doing so improves the overall solution.
## However, the use of means implies that all variables must be continuous and the approach can be severely affected by outliers.
## They also perform poorly in the presence of non-convex (e.g., U-shaped) clusters.
set.seed(455)
dtaCluster <- kmeans(dta[,c('num_students', 'num_schools')], 20, nstart=20)
dta$cluster_id <- as.factor(dtaCluster$cluster)
dtaCluster <- kmeans(dta.mega.large[,c('num_students', 'num_schools')], 8, nstart=20)
dta.mega.large$cluster_id_mega_large <- as.factor(dtaCluster$cluster)

## merge in both indicators
dta <- merge(dta, dta.mega.large[,c('esh_id', 'cluster_id_mega_large')], by='esh_id', all.x=T)

## aggregate cluster means to reorder
dta.agg <- aggregate(dta[,c('num_students', 'num_schools')], by=list(dta$cluster_id), FUN=mean, na.rm=T)
dta.mega.large.agg <- aggregate(dta.mega.large[,c('num_students', 'num_schools')], by=list(dta.mega.large$cluster_id_mega_large), FUN=mean, na.rm=T)
## order clusters based on decreasing mean
dta.agg <- dta.agg[order(dta.agg$num_students, decreasing=T),]
## reassign cluster ids
dta.agg$new_cluster_id <- 1:nrow(dta.agg)
## merge in new cluster ids
dta <- merge(dta, dta.agg[,c('Group.1', 'new_cluster_id')], by.x='cluster_id', by.y='Group.1', all.x=T)
dta$cluster_id <- as.factor(dta$new_cluster_id)
## order clusters based on decreasing mean
dta.mega.large.agg <- dta.mega.large.agg[order(dta.mega.large.agg$num_students, decreasing=T),]
## reassign cluster ids
dta.mega.large.agg$new_cluster_id_mega_large <- 1:nrow(dta.mega.large.agg)
## merge in new cluster ids
dta <- merge(dta, dta.mega.large.agg[,c('Group.1', 'new_cluster_id_mega_large')], by.x='cluster_id', by.y='Group.1', all.x=T)
dta$cluster_id_mega_large <- as.factor(dta$new_cluster_id_mega_large)

## subset to variables: num_students, num_schools, district_size, form_470, cluster_id
dta.subset <- dta[,c('esh_id', 'form_470', 'cluster_id', 'cluster_id_mega_large')]

##**************************************************************************************************************************************************
## write out the processed datasets

write.csv(dta, "data/interim/clustered_all_districts.csv", row.names=F)
write.csv(dta.subset, "data/processed/final_clustered_districts.csv", row.names=F)
write.csv(dta.agg, "data/processed/aggregated_means_clusters_all_districts.csv", row.names=F)
write.csv(dta.mega.large.agg, "data/processed/aggregated_means_clusters_mega_and_large_districts.csv", row.names=F)
