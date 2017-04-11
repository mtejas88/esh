## =========================================
##
## EXAMINE DATA: Bandwidth
## Look into cutoff points for bucketing
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("lattice")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(lattice)

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## subset to clean districts
dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]

## assign groupings:
## < 100K/student = *
## [100, 200)/student = **
## [200, 500)/student = ***
## [500, 1000)/student = ****
## >= 1000/student = *****
dd.2016$group <- ifelse(dd.2016$ia_bandwidth_per_student_kbps < 100, 1,
                           ifelse(dd.2016$ia_bandwidth_per_student_kbps >= 100 & dd.2016$ia_bandwidth_per_student_kbps < 200, 2,
                                  ifelse(dd.2016$ia_bandwidth_per_student_kbps >= 200 & dd.2016$ia_bandwidth_per_student_kbps < 500, 3,
                                         ifelse(dd.2016$ia_bandwidth_per_student_kbps >= 500 & dd.2016$ia_bandwidth_per_student_kbps < 1000, 4,
                                                ifelse(dd.2016$ia_bandwidth_per_student_kbps >= 1000, 5, NA)))))

## add in grouping for concurrency factor for Megas and Larges (do it both ways)
dd.2016$ia_bandwidth_per_student_kbps_concurrency <- dd.2016$ia_bandwidth_per_student_kbps * dd.2016$ia_oversub_ratio
## grouping with concurrency
dd.2016$group_concurrency <- ifelse(dd.2016$ia_bandwidth_per_student_kbps < 100, 1,
                        ifelse(dd.2016$ia_bandwidth_per_student_kbps_concurrency >= 100 & dd.2016$ia_bandwidth_per_student_kbps_concurrency < 200, 2,
                               ifelse(dd.2016$ia_bandwidth_per_student_kbps_concurrency >= 200 & dd.2016$ia_bandwidth_per_student_kbps_concurrency < 500, 3,
                                      ifelse(dd.2016$ia_bandwidth_per_student_kbps_concurrency >= 500 & dd.2016$ia_bandwidth_per_student_kbps_concurrency < 1000, 4,
                                             ifelse(dd.2016$ia_bandwidth_per_student_kbps_concurrency >= 1000, 5, NA)))))

## subset columns
sub <- dd.2016[,c('esh_id', 'name', 'postal_cd', 'district_size', 'ia_bandwidth_per_student_kbps', 'ia_bandwidth_per_student_kbps_concurrency', 'group', 'group_concurrency')]
sub$counter <- 1
## aggregate groups
groups <- aggregate(sub$counter, by=list(sub$group), FUN=sum)
names(groups) <- c('groups', 'count')
groups$type <- 'original'
groups.con <- aggregate(sub$counter, by=list(sub$group_concurrency), FUN=sum)
names(groups.con) <- c('groups', 'count')
groups.con$type <- 'concurrency'
dta.groups <- rbind(groups, groups.con)
dta.groups$type <- factor(dta.groups$type, levels=c('original', 'concurrency'))
dta.groups$groups <- factor(dta.groups$groups)

## look at distribution of original groupings next to concurrency
pdf("figures/distribution_bw_groupings.pdf", height=5, width=6)
barchart(dta.groups$count ~ dta.groups$groups,
         groups=dta.groups$type, auto.key = list(columns = 2), ylim=c(0,max(dta.groups$count)+50),
         ylab='', xlab='Rating', main='Groupings with/without\n Concurrency')
dev.off()


## look at distribution by district size
## aggregate unique groups and district_size
groups.ds <- aggregate(sub$counter, by=list(sub$group, sub$district_size), FUN=sum)
names(groups.ds) <- c('groups', 'district_size', 'count')
groups.ds.con <- aggregate(sub$counter, by=list(sub$group_concurrency, sub$district_size), FUN=sum)
names(groups.ds.con) <- c('groups', 'district_size', 'count')
groups.ds$district_size <- factor(groups.ds$district_size,
                                     levels=c('Tiny', 'Small', 'Medium', 'Large', 'Mega'))
groups.ds$groups <- as.factor(groups.ds$groups)
groups.ds.con$district_size <- factor(groups.ds.con$district_size,
                                         levels=c('Tiny', 'Small', 'Medium', 'Large', 'Mega'))
groups.ds.con$groups <- as.factor(groups.ds.con$groups)
sub$counter <- NULL

## look at distribution of original groupings broken out by district size
pdf("figures/distribution_bw_groupings_district_size_original.pdf", height=5, width=6)
barchart(groups.ds$count ~ groups.ds$groups,
         groups=groups.ds$district_size, auto.key = list(columns = 2),
         ylim=c(0,max(groups.ds$count)+50),
         ylab='', xlab='Rating', main='Original Groupings Broken out\nby District Size')
dev.off()

## look at distribution of concurrency groupings broken out by district size
pdf("figures/distribution_bw_groupings_district_size_concurrency.pdf", height=5, width=6)
barchart(groups.ds.con$count ~ groups.ds.con$groups,
         groups=groups.ds.con$district_size, auto.key = list(columns = 2),
         ylim=c(0,max(groups.ds.con$count)+50),
         ylab='', xlab='', main='Concurrency Groupings Broken out\nby District Size')
dev.off()

## subset to each group
for (i in 1:5){
  sub.sub <- sub[sub$group_concurrency == i,]
  sub.sub <- sub.sub[order(sub.sub$ia_bandwidth_per_student_kbps, decreasing=F),]
  write.csv(sub.sub, paste("data/interim/bandwidth_group_", i, ".csv", sep=''))
  assign(paste("sub", i, sep="."), sub.sub)
}

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(sub, "data/interim/bandwidth_grouping.csv", row.names=F)
