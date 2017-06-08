## =========================================
##
## QUERY DATA FROM THE DB
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("flexdashboard", "shiny", "dplyr", "highcharter", "rsconnect", "ggplot2", "DT", "htmltools")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(flexdashboard) # need to run compile this tool
library(shiny) # need for render functions
library(dplyr) # most of the code is written using dplyr functions ( e.g. %>% filter(), %>% summarise(), %>% select() )
library(highcharter) # need for highchart() vizes (eg. bar charts, box plots, scatter plots)
library(rsconnect) # need for supporting R markdown 
library(ggplot2) # for ggplot vizes (i.e. square colored box with status suchc as: 36 fiber targets) 
library(DT) # need for datatables
library(htmltools) # need for html use in code (I think)


