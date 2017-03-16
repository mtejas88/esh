## =========================================
##
## FIGURES: Generate visualizations
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("ggplot2", "gridExtra")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(ggplot2)
library(gridExtra) ## for grid.arrange function

##**************************************************************************************************************************************************
## read in data

dta <- read.csv("data/interim/clustered_all_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dta.agg <- read.csv("data/processed/aggregated_means_clusters_all_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dta.mega.large.agg <- read.csv("data/processed/aggregated_means_clusters_mega_and_large_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## generate figures

## plot clusters -- all
pdf("figures/visualize_clusters.pdf", height=6, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

## plot clusters -- mega and large
pdf("figures/visualize_clusters_mega_large.pdf", height=4, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id_mega_large)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=cluster_id_mega_large)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

dta$cluster_id <- as.numeric(as.character(dta$cluster_id))
dta$cluster_id_mega_large <- as.numeric(as.character(dta$cluster_id_mega_large))

pdf("figures/distribution_of_cluster_id.pdf", height=5, width=5)
hist(dta$cluster_id, col=rgb(0,0,0,0.6), border=F, xlim=c(0,20),
     main="All Districts", xlab="cluster id")
dev.off()

pdf("figures/distribution_of_cluster_id_mega_large.pdf", height=5, width=5)
hist(dta$cluster_id_mega_large, col=rgb(0,0,0,0.6), border=F, xlim=c(1,8),
     main="Mega and Large", xlab="cluster id")
dev.off()
