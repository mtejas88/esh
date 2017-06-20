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

apply_state_names <- function(dta){
  ## add state name to state aggregation
  dta$state_name <- state.name[match(dta$postal_cd, state.abb)]
  dta$state_name[dta$postal_cd == 'DC'] <- "Washington DC"
  return(dta)
}


##**************************************************************************************************************************************************
## read data

state_2017 <- read.csv("tool/data/2017_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
state_2016 <- read.csv("tool/data/2016_state_aggregation.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2017 <- read.csv("tool/data/2017_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2016 <- read.csv("tool/data/2016_deluxe_districts.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## format data

## add state name to state aggregation
state_2016 <- apply_state_names(state_2016)
state_2017 <- apply_state_names(state_2017)










##**************************************************************************************************************************************************
## write out data

## write out generically
write.csv(state_2017, paste("tool/data/2017_state_aggregation.csv", sep=""), row.names=F)
write.csv(state_2016, paste("tool/data/2016_state_aggregation.csv", sep=""), row.names=F)
write.csv(dd_2017, paste("tool/data/2017_deluxe_districts.csv", sep=""), row.names=F)
write.csv(dd_2016, paste("tool/data/2016_deluxe_districts.csv", sep=""), row.names=F)

##**************************************************************************************************************************************************
## deploy tool

if (deploy == 1){
  options(repos=c(CRAN="https://cran.rstudio.com"))
  rsconnect::setAccountInfo(name='educationsuperhighway',
                            token='0199629F81C4DEC2466F106048613D4E',
                            secret='AZuGIeV6axGnzmBI1GQ6hFLdHN0ojUaA+U/wi8YT')
  rsconnect::deployDoc("tool/2017_State_Metrics_Dashboard.Rmd")
}



