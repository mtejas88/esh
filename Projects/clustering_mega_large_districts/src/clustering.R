## ==============================================================================================================================
##
## CLUSTERING MEGA AND LARGE DISTRICTS
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/Org-Wide Projects/Clustering Mega and Large Districts/code/")

## load packages
## force rJava to load on Mac 10 El Capitan
dyn.load('/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/jre/lib/server/libjvm.dylib')
options(java.parameters = "-Xmx4g" )
library(rJava)
library(RJDBC)
library(ggplot2)
library(gridExtra) ## for grid.arrange function
library(fpc) ## for pamk function
library(cluster) ## for pam and clusGap function

## source function
source("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/General Resources/R_database_access/correct_dataset.R")
source("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/General Resources/R_database_access/db_credentials.R")

##**************************************************************************************************************************************************
## QUERY THE DB -- SQL

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "~/Downloads/postgresql-9.4.1209.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=url, user=user, password=password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dd.2016 <- querydb("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/General Resources/R_database_access/SQL Scripts/2016_deluxe_districts_crusher_materialized.SQL")
dd.2016 <- correct.dataset(dd.2016, sots.flag=0, services.flag=0)
dta.470 <- querydb("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/General Resources/R_database_access/SQL Scripts/Form470s.SQL")
bens <- querydb("~/Google Drive/ESH Main Share/Strategic Analysis Team/2017/General Resources/R_database_access/SQL Scripts/Entity_Bens.SQL")

## disconnect from database
dbDisconnect(con)

##**************************************************************************************************************************************************
## subset and format data

## 470 data formatting
## format the column names (take out capitalization and spaces)
names(dta.470) <- tolower(names(dta.470))
names(dta.470) <- gsub(" ", ".", names(dta.470))
## rename column "function"
names(dta.470)[names(dta.470) == 'function'] <- 'function1'
## rename column "470.number"
names(dta.470)[names(dta.470) == '470.number'] <- 'X470.number'

## merge in BENs to DD
dd.2016 <- merge(dd.2016, bens, by.x='esh_id', by.y='entity_id', all.x=T)
## keep only unique bens (since some districts file multiple Form 470s)
dta.470 <- dta.470[which(!duplicated(dta.470$ben)),]
## merge in form 470 info (to determine if they've filed one)
dd.2016 <- merge(dd.2016, dta.470[,c('ben', 'X470.number')], by='ben', all.x=T)
## create an indicator for whether a district has filed a form 470
dd.2016$form_470 <- ifelse(!is.na(dd.2016$X470.number), TRUE, FALSE)
## take out duplicated esh_ids
dd.2016 <- dd.2016[!duplicated(dd.2016$esh_id),]

## select mega and large districts
dta <- dd.2016
dta.mega.large <- dd.2016[which(dd.2016$district_size %in% c('Large', 'Mega')),]

pdf("../figures/visualize_raw.pdf", height=4, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=district_size)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=district_size)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

##**************************************************************************************************************************************************
## Determine number of clusters

## Option 1: Sum of Squared Error plot
wss <- (nrow(dta)-1)*sum(apply(dta[,c('num_students', 'num_schools')],2,var))
for (i in 2:25){
  wss[i] <- sum(kmeans(dta[,c('num_students', 'num_schools')], centers=i)$withinss)
}
## plot shows 7 clusters as the bend in the elbow
pdf("../figures/visualize_num_clusters.pdf", height=5, width=4)
plot(1:25, wss, type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares")
dev.off()

## Option 2: Partitioning Around Medoids (PAM)
## PAM says 3 clusters
#pamk(dta[,c('num_students', 'num_schools')], krange=2:20, criterion="asw", usepam=TRUE)
## 2 ways to show how to get the number:
## A)
pamk.best <- pamk(dta[,c('num_students', 'num_schools')])
cat("number of clusters estimated by optimum average silhouette width:", pamk.best$nc, "\n")
plot(pam(dta[,c('num_students', 'num_schools')], pamk.best$nc))

## B)
asw <- numeric(20)
for (k in 2:20){
  asw[[k]] <- pam(dta[,c('num_students', 'num_schools')], k) $ silinfo $ avg.width
}
k.best <- which.max(asw)
cat("silhouette-optimal number of clusters:", k.best, "\n")

## 3) Calinsky criterion
## 11 clusters
require(vegan)
fit <- cascadeKM(scale(dta[,c('num_students', 'num_schools')], center = TRUE,  scale = TRUE), 1, 20, iter = 1000)
plot(fit, sortg = TRUE, grpmts.plot = TRUE)
calinski.best <- as.numeric(which.max(fit$results[2,]))
cat("Calinski criterion optimal number of clusters:", calinski.best, "\n")

## 4) Gap Statistic
clusGap(dta[,c('num_students', 'num_schools')], kmeans, 30, B = 100, verbose = interactive())

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

## plot clusters -- all
pdf("../figures/visualize_clusters.pdf", height=6, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

## plot clusters -- mega and large
pdf("../figures/visualize_clusters_mega_large.pdf", height=4, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id_mega_large)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id_mega_large)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

dta$cluster_id <- as.numeric(as.character(dta$cluster_id))
dta$cluster_id_mega_large <- as.numeric(as.character(dta$cluster_id_mega_large))

pdf("../figures/distribution_of_cluster_id.pdf", height=5, width=5)
hist(dta$cluster_id, col=rgb(0,0,0,0.6), border=F, xlim=c(0,20),
     main="All Districts", xlab="cluster id")
dev.off()

pdf("../figures/distribution_of_cluster_id_mega_large.pdf", height=5, width=5)
hist(dta$cluster_id_mega_large, col=rgb(0,0,0,0.6), border=F, xlim=c(1,8),
     main="Mega and Large", xlab="cluster id")
dev.off()

##**************************************************************************************************************************************************
## write out data

## subset to variables: num_students, num_schools, district_size, form_470, cluster_id
dta <- dta[,c('esh_id', 'form_470', 'cluster_id', 'cluster_id_mega_large')]

write.csv(dta, "../data/clustered_all_districts.csv", row.names=F)
write.csv(dta.agg, "../data/aggregated_means_clusters_all_districts.csv", row.names=F)
write.csv(dta.mega.large.agg, "../data/aggregated_means_clusters_mega_and_large_districts.csv", row.names=F)
