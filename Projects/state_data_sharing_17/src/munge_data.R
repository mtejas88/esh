## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())
library(dplyr)
library(xlsx)
library(stringr)

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
valid.values <- read.xlsx("other_tabs/values_and_dictionary.xlsx", 1)
data.dictionary <- read.xlsx("other_tabs/values_and_dictionary.xlsx", 2)



all_states <- district.master.detail$state %>% unique()


head(district.master.detail)

valid.values$purpose_of_service <- as.character(valid.values$purpose_of_service)
valid.values[is.na(valid.values)] <- ''
data.dictionary$Source <- as.character(data.dictionary$Source)
data.dictionary[is.na(data.dictionary)] <- ''


#General Spreadsheets
for (i in 1:length(all_states)) {
#for (i in 1:1) {
  print(all_states[i])
  district <- district.master[district.master$state == all_states[i],]
  consortia <- consortia.master[consortia.master$state == all_states[i],]
  district <- district[,-4]
  consortia <- consortia[,-4]
  
  #writing out results to the general folder
  if(nrow(consortia) == 0) {
    save.xlsx(paste('data/general/',all_states[i],'_data_summary.xlsx', sep = ''), district, data.dictionary)
  } else {
    save.xlsx(paste('data/general/',all_states[i],'_data_summary.xlsx', sep = ''), district, consortia, data.dictionary)
  }

}

#replacing NAs with blanks
district.master.detail[is.na(district.master.detail)] <- ''
consortia.master.detail[is.na(consortia.master.detail)] <- ''





#Detailed Spreadsheets
for (i in 1:length(all_states)) {
#for (i in 1:1) {
  print(all_states[i])
  district <- district.master.detail[district.master.detail$state == all_states[i],]
  consortia <- consortia.master.detail[consortia.master.detail$state == all_states[i],]
  district <- district[,-4]
  consortia <- consortia[,-4]
  district[is.na(district)] <- ''
  consortia[is.na(consortia)] <- ''
  
  file <- paste('data/detailed/',all_states[i],'_data_summary.xlsx', sep = '')
  #writing out results to the detailed folder
  if(nrow(consortia) == 0) {
    save.xlsx(file, district, valid.values, data.dictionary)
    sheetname <- 'district'
  } else {
    save.xlsx(file, district, consortia, valid.values, data.dictionary)
    sheetname <- c('district', 'consortia')
  }
  
  wb <- loadWorkbook(file)              # load workbook
  fo <- Fill(foregroundColor="#FFC7CE")  # create fill object
  cs <- CellStyle(wb, fill=fo)          # create cell style
  sheets <- getSheets(wb)               # get all sheets
  for (i in 1:length(sheetname)) {
    sheet <- sheets[[sheetname[i]]]
    if(sheetname[i] == 'district') {
      mydata <- district
    } else {
      mydata <- consortia
    }
    rows <- getRows(sheet, rowIndex=2:(nrow(mydata)+1))     # get rows
    cells <- getCells(rows, colIndex = 25:30)
    values <- lapply(cells, getCellValue) # extract the values
    highlight <- "test"
    for (i in names(values)) {
      x <- values[i]
      if (x=='Yes') {
        highlight <- c(highlight, i)
      }    
    }
    
    highlight <- highlight[-1]
    
    all.cells <- getCells(rows, colIndex = 1:30)
    all.values <- lapply(all.cells, getCellValue) # extract the values
    if (length(highlight) > 0) {
      for (i in 1:length(highlight)) {
        if (str_sub(highlight[i], -2, -1) == '26') {
          cell.to.highlight <- paste0(str_sub(highlight[i], 1, -3), '6')
          highlight <- c(highlight, cell.to.highlight)
        } else if (str_sub(highlight[i], -2, -1) == '25') {
          cell.to.highlight <- paste0(str_sub(highlight[i], 1, -3), '8')
          highlight <- c(highlight, cell.to.highlight)
        } else if (str_sub(highlight[i], -2, -1) == '28') {
          cell.to.highlight <- paste0(str_sub(highlight[i], 1, -3), '12')
          highlight <- c(highlight, cell.to.highlight)
        } else if (str_sub(highlight[i], -2, -1) == '27') {
          cell.to.highlight <- paste0(str_sub(highlight[i], 1, -3), '14')
          highlight <- c(highlight, cell.to.highlight)
        } else if (str_sub(highlight[i], -2, -1) == '29') {
          highlight <- append(highlight,paste0(str_sub(highlight[i], 1, -3), '16'))
          highlight <- append(highlight,paste0(str_sub(highlight[i], 1, -3), '18'))
          highlight <- append(highlight,paste0(str_sub(highlight[i], 1, -3), '21'))
        } else if (str_sub(highlight[i], -2, -1) == '30') {
          cell.to.highlight <- paste0(str_sub(highlight[i], 1, -3), '24')
          highlight <- c(highlight, cell.to.highlight)
        }
      }
    }
    
    lines.cells <- getCells(rows, colIndex = 12)
    lines.values <- lapply(lines.cells, getCellValue) # extract the values
    for (i in names(lines.values)) {
      x <- values[i]
      if (x=='0' | is.null(x)) {
        highlight <- append(highlight, i)
      }
    }
    
    highlight <- unique(highlight)
    
    #lapply(names(cells[highlight]),
    #       function(ii)setCellStyle(cells[[ii]],cs))
    lapply(names(all.cells[highlight]),
           function(ii)setCellStyle(all.cells[[ii]],cs))
  }
  
  saveWorkbook(wb, file)
} 


#Detailed Spreadsheets without formatting
#removing AR for now
all_states <- all_states[all_states != 'AR']
for (i in 1:length(all_states)) {
  #for (i in 1:1) {
  print(all_states[i])
  district <- district.master.detail[district.master.detail$state == all_states[i],]
  consortia <- consortia.master.detail[consortia.master.detail$state == all_states[i],]
  district <- district[,-4]
  consortia <- consortia[,-4]
  district[is.na(district)] <- ''
  consortia[is.na(consortia)] <- ''
  
  if(nrow(consortia) == 0) {
    save.xlsx(paste('data/detailed/',all_states[i],'_data_summary.xlsx', sep = ''), district, valid.values, data.dictionary)
  } else {
    save.xlsx(paste('data/detailed/',all_states[i],'_data_summary.xlsx', sep = ''), district, consortia, valid.values, data.dictionary)
  }
} 

