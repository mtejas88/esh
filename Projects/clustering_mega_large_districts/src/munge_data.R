## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("gridExtra", "ggplot2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(ggplot2)
library(gridExtra) ## for grid.arrange function

##**************************************************************************************************************************************************
## read in data

dd.2016 <- read.csv("data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)
dta.470 <- read.csv("data/raw/form_470.csv", as.is=T, header=T, stringsAsFactors=F)
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## subset and format data

## 470 data formatting
## format the column names (take out capitalization and spaces)
names(dta.470) <- tolower(names(dta.470))
names(dta.470) <- gsub(" ", ".", names(dta.470))
## rename column "function"
names(dta.470)[names(dta.470) == 'function'] <- 'function1'

## merge in BENs to DD
dd.2016 <- merge(dd.2016, bens, by.x='esh_id', by.y='entity_id', all.x=T)
## keep only unique bens (since some districts file multiple Form 470s)
dta.470 <- dta.470[which(!duplicated(dta.470$ben)),]
## merge in form 470 info (to determine if they've filed one)
dd.2016 <- merge(dd.2016, dta.470[,c('ben', 'x470.number')], by='ben', all.x=T)
## create an indicator for whether a district has filed a form 470
dd.2016$form_470 <- ifelse(!is.na(dd.2016$x470.number), TRUE, FALSE)
## take out duplicated esh_ids
dd.2016 <- dd.2016[!duplicated(dd.2016$esh_id),]

## select mega and large districts
dta <- dd.2016
dta.mega.large <- dd.2016[which(dd.2016$district_size %in% c('Large', 'Mega')),]

##**************************************************************************************************************************************************
## plot the raw data

pdf("figures/visualize_raw.pdf", height=4, width=10)
plot1 <- ggplot(dta, aes(num_students, num_schools, color=district_size)) + geom_point()
plot2 <- ggplot(dta, aes(num_students, num_schools, color=district_size)) + xlim(0,225000) + ylim(0,400) + geom_point()
grid.arrange(plot1, plot2, ncol=2)
dev.off()

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(dta, "data/interim/all_districts.csv", row.names=F)
write.csv(dta.mega.large, "data/interim/mega_large_districts.csv", row.names=F)
