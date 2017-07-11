## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())
library(dplyr)
library(xlsx)

save.xlsx <- function (file, ...)
{
  require(xlsx, quietly = TRUE)
  objects <- list(...)
  fargs <- as.list(match.call(expand.dots = TRUE))
  objnames <- as.character(fargs)[-c(1, 2)]
  nobjects <- length(objects)
  for (i in 1:nobjects) {
    if (i == 1)
      write.xlsx(objects[[i]], file, sheetName = objnames[i], row.names = F)
    else write.xlsx(objects[[i]], file, sheetName = objnames[i],
                    append = TRUE, row.names = F)
  }
  print(paste("Workbook", file, "has", nobjects, "worksheets."))
}

##**************************************************************************************************************************************************
## read in data

district.master <- read.csv("data/raw/districts.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
consortia.master <- read.csv("data/raw/consortia.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
district.master.detail <- read.csv("data/raw/districts_detailed.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
consortia.master.detail <- read.csv("data/raw/consortia_detailed.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

all_states <- district.master$state %>% unique()


#General Spreadsheets
for (i in 1:length(all_states)) {
  print(all_states[i])
  district <- district.master[district.master$state == all_states[i],]
  consortia <- consortia.master[consortia.master$state == all_states[i],]
  district <- district[,-4]
  consortia <- consortia[,-4]
  
  #writing out results to the general folder
  if(nrow(consortia) == 0) {
    save.xlsx(paste('data/general/',all_states[i],'_data_summary.xlsx', sep = ''), district)
  } else {
    save.xlsx(paste('data/general/',all_states[i],'_data_summary.xlsx', sep = ''), district, consortia)
  }

}

#replacing NAs with blanks
district.master.detail[is.na(district.master.detail)] <- ''
consortia.master.detail[is.na(consortia.master.detail)] <- ''

#Detailed Spreadsheets
for (i in 1:length(all_states)) {
  print(all_states[i])
  district <- district.master.detail[district.master.detail$state == all_states[i],]
  consortia <- consortia.master.detail[consortia.master.detail$state == all_states[i],]
  district <- district[,-4]
  consortia <- consortia[,-4]
  
  #writing out results to the detailed folder
  if(nrow(consortia) == 0) {
    save.xlsx(paste('data/detailed/',all_states[i],'_data_summary.xlsx', sep = ''), district)
  } else {
    save.xlsx(paste('data/detailed/',all_states[i],'_data_summary.xlsx', sep = ''), district, consortia)
  }
}
