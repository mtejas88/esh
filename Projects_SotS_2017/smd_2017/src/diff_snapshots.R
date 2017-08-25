## =========================================
##
## DIFF SNAPSHOTS: FRIDAY VS LIVE
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Projects_SotS_2017/smd_2017/")
#setwd("~/Documents/R_WORK/ficher/Projects_SotS_2017/smd_2017/")

## retrieve date (in order to accurately timestamp files)
actual.date <- Sys.time()
weekday <- weekdays(actual.date)
actual.date <- gsub("PST", "", actual.date)
actual.date <- gsub(" ", "_", actual.date)
actual.date <- gsub(":", ".", actual.date)

##**************************************************************************************************************************************************
## READ DATA

## Snapshots
#live_ss <- read.csv("data/processed/snapshots_raw.csv", as.is=T, header=T, stringsAsFactors=F)
live_ss <- read.csv("data/processed/2017_snapshots_2017-08-09_15.00.33.csv", as.is=T, header=T, stringsAsFactors=F)
friday_ss <- read.csv("data/processed/snapshots_raw_live.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

friday_ss <- friday_ss[which(friday_ss$postal_cd %in% live_ss$postal_cd),]
friday_ss <- friday_ss[,which(names(friday_ss) %in% names(live_ss))]

live_ss <- live_ss[which(live_ss$postal_cd %in% friday_ss$postal_cd),]
live_ss <- live_ss[,which(names(live_ss) %in% names(friday_ss))]

## for the numeric columns, calculate the differences
nums <- sapply(live_ss, is.numeric)
cols <- names(live_ss)[nums]

diff.dta <- data.frame(matrix(NA, nrow=nrow(live_ss), ncol=ncol(live_ss)))
names(diff.dta) <- names(live_ss)

## for each numeric column, when any total is >= 1,000, format with commas
for (col in cols){
  diff.dta[,col] <- friday_ss[,col] - live_ss[,col]
}
diff.dta$postal_cd <- live_ss$postal_cd
diff.dta$state_name <- live_ss$state_name

##**************************************************************************************************************************************************
## WRITE OUT DATA

write.csv(diff.dta, paste("data/processed/diff_snapshots_friday_live_", actual.date, ".csv", sep=""), row.names=F)
