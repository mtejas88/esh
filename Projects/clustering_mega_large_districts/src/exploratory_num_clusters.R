## =========================================
##
## DETERMINE NUMBER OF CLUSTERS: Exploratory
## find the ideal number of clusters
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
