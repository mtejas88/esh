## =========================================================================
##
## MONTANA CONNECTIVITY REPORT
##
## PURPOSE: To replicate the statistics found in the Shiny App
## (https://educationsuperhighway.shinyapps.io/shiny/)
##
## The code is organized by the following sections:
## 1) Initial dive into the districts: DEMOGRAPHICS
## 2) Calculating summary statistics regarding broadband status: GOALS
## 3) FIBER
## 4) AFFORDABILITY
## 5) MAPS
##
## AJB 07/16
## =========================================================================

## Clearing memory
rm(list=ls())

setwd("~/Google Drive/Montana CR/code/")

## load packages
#install.packages("rgdal")
#install.packages("ggplot2")
#install.packages("maptools")
#install.packages("rgeos")
#install.packages("gpclib", type="source")
library(rgdal)
library(ggplot2)
library(gpclib)
library(maptools)
library(rgeos)

##*********************************************************************************************************
## READ IN FILES

## ESH Deluxe table (district-level)
deluxe <- read.csv("../data/ESH/district/deluxe-districts-table_MT-2016-07-11.csv", as.is=T, header=T)

## ESH Services Received table (circuit-level)
serv.rec <- read.csv("../data/ESH/circuit/services-received_MT-2016-07-11.csv", as.is=T, header=T)

## Shapefiles -- for plotting
#state.shp <- readOGR(dsn="../data/External/Shapefiles/US State 5m/", layer = "cb_2015_us_state_5m")
#county.shp <- readOGR(dsn="../data/External/Shapefiles/US County 5m/", layer = "cb_2015_us_county_5m")

##*********************************************************************************************************
## 1) Initial dive into the districts: DEMOGRAPHICS

## subset deluxe to districts fit for analysis
deluxe.clean <- deluxe[deluxe$exclude_from_analysis == 'false',]

## clean vs dirty records
## percentage of districts we have clean
## 60.84%
round((nrow(deluxe.clean) / nrow(deluxe)) * 100, 2)

## What is the breakdown of locale across the state?
## all
table(deluxe$locale)
## clean
table(deluxe.clean$locale)
## percentage clean of each locale type
deluxe$counter <- 1
deluxe.clean$counter <- 1
locale.agg <- aggregate(deluxe$counter, by=list(deluxe$locale), FUN=sum)
names(locale.agg) <- c('locale', 'total')
locale.agg$category <- 'all'
locale.agg.clean <- aggregate(deluxe.clean$counter, by=list(deluxe.clean$locale), FUN=sum)
names(locale.agg.clean) <- c('locale', 'total')
locale.agg.clean$category <- 'clean'
## rbind the two datasets
dta.locale.agg <- rbind(locale.agg, locale.agg.clean)
## calculate percentage
dta.locale.agg$percent <- paste(round((dta.locale.agg$total / nrow(deluxe))*100, 1), "%", sep='')
## order by the most prevalent to least
dta.locale.agg <- dta.locale.agg[order(dta.locale.agg$total, decreasing=T),]
## Grouped Bar Plot
pdf("../figures/districts_by_locale_clean_vs_dirty.pdf", height=5, width=6)
## capture ESH colors (per the marketing pamphlet: Golden Yellow = 253, 185, 19)
## capture ESH colors (per the marketing pamphlet: Aqua = 0, 146, 150)
colors <- c(all=rgb(253/255, 185/255, 19/255, 1), clean=rgb(0/255, 146/255, 150/255, 1))
ggplot(data=dta.locale.agg, aes(factor(locale), total, fill=category)) + labs(title="Districts within Locale", x="", y="") + 
  geom_bar(stat="identity", position="dodge", colour="white") + scale_fill_manual(values=colors) +
  ## add labels to bars
  geom_text(aes(label=percent), position=position_dodge(width=0.9), vjust=-0.25) + 
  ## remove background grey grid
  theme_bw()
dev.off()

## What is the breakdown of district size across the state?
## all
table(deluxe$district_size)
## clean
table(deluxe.clean$district_size)
## percentage clean of each district size type
district.size.agg <- aggregate(deluxe$counter, by=list(deluxe$district_size), FUN=sum)
names(district.size.agg) <- c('district_size', 'total')
district.size.agg$category <- 'all'
district.size.agg.clean <- aggregate(deluxe.clean$counter, by=list(deluxe.clean$district_size), FUN=sum)
names(district.size.agg.clean) <- c('district_size', 'total')
district.size.agg.clean$category <- 'clean'
## rbind the two datasets
dta.district.size.agg <- rbind(district.size.agg, district.size.agg.clean)
## calculate percentage
dta.district.size.agg$percent <- paste(round((dta.district.size.agg$total / nrow(deluxe))*100, 1), "%", sep='')
## order by the most prevalent to least
dta.district.size.agg <- dta.district.size.agg[order(dta.district.size.agg$total, decreasing=T),]
## Grouped Bar Plot
pdf("../figures/districts_by_district_size_clean_vs_dirty.pdf", height=5, width=6)
## capture ESH colors (per the marketing pamphlet: Golden Yellow = 253, 185, 19)
## capture ESH colors (per the marketing pamphlet: Aqua = 0, 146, 150)
colors <- c(all=rgb(253/255, 185/255, 19/255, 1), clean=rgb(0/255, 146/255, 150/255, 1))
ggplot(dta.district.size.agg, aes(factor(district_size), total, fill=category)) + labs(title="Districts broken out by Size", x="", y="") + 
  geom_bar(stat="identity", position="dodge", colour="white") + scale_fill_manual(values=colors) +
  ## add labels to bars
  geom_text(aes(label=percent), position=position_dodge(width=0.9), vjust=-0.25) +
  ## remove background grey grid
  theme_bw()
dev.off()

##*********************************************************************************************************
## 2) Calculating summary statistics regarding broadband status: GOALS

##======================================
## TOGGLES

## Set Highest IA Connection Type(s) for Districts
## select (0/1)
fiber <- 1
cable <- 1
dsl <- 1
fixed.wireless <- 1
copper <- 1
other <- 1

## Select District Size(s)
## select (0/1)
tiny <- 1
small <- 1
medium <- 1
large <- 1
mega <- 1

## Select District Locale(s)
## select (0/1)
rural <- 0
small.town <- 0
suburban <- 0
urban <- 1

##======================================
connect.type.str <- c("Fiber", "Cable", "DSL", "Fixed Wireless", "Copper", "Other/Uncategorized")
connect.type <- c(fiber, cable, dsl, fixed.wireless, copper, other)
districts.size.str <- c("Tiny", "Small", "Medium", "Large", "Mega")
districts.size <- c(tiny, small, medium, large, mega)
locales.str <- c("Rural", "Small Town", "Suburban", "Urban")
locales <- c(rural, small.town, suburban, urban)

## create subset based on the toggles chosen above
deluxe.clean$ia_bandwidth_per_student <- as.numeric(deluxe.clean$ia_bandwidth_per_student)
dta.sub <- deluxe.clean[deluxe.clean$hierarchy_connect_category %in% connect.type.str[which(connect.type == 1)] &
                          deluxe.clean$district_size %in% districts.size.str[which(districts.size == 1)] &
                          deluxe.clean$locale %in% locales.str[which(locales == 1)],]

## A) Percentage of districts meeting the 2014 goal (100 kbps/student)
## number of districts
paste("Number of Districts: ", nrow(dta.sub), sep='')
## percentage of districts meeting the goal
paste("Percentage of Districts Meeting the Goal: ",
      round((nrow(dta.sub[dta.sub$ia_bandwidth_per_student >= 100,]) / nrow(dta.sub)) * 100, 2), '%', sep='')
## number of students
paste("Number of Students: ", sum(dta.sub$num_students), sep='')
## percentage of students meeting the goal
paste("Percentage of Students Meeting the Goal: ",
      round((sum(dta.sub$num_students[dta.sub$ia_bandwidth_per_student >= 100]) / sum(dta.sub$num_students)) * 100, 2), '%', sep='')

## B) Districts, Broken out by highest internet access technology
## Extra Toggles:
## select (0/1)
meeting.goal <- 1
not.meeting.goal <- 1

## subset the data even further to make the histogram broken out by hierarchy_connect_category
if (meeting.goal == 1 | not.meeting.goal == 1){
  dta.sub <- dta.sub[dta.sub]
}

## when plotting, add in the outline of 100% goal

## C) Schools that are curently or need to be meeting the FCC WAN goal


## D) Hypothetical pricing analysis: districts meeting the 2014 FCC goal


##*********************************************************************************************************
## 5) Plotting the districts -- MAPS

## format the shapefiles
## change geoid to character
state.shp$GEOID <- as.character(state.shp$GEOID)
county.shp$GEOID <- as.character(county.shp$GEOID)
## convert polygons to data frame
ggstate.shp <- fortify(state.shp, region = "GEOID")

