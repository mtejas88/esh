# CR - NH - analysis - 11/05/2015
setwd("~/Desktop/ESH/CR_NH")
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggmap)
library(grid)
library(maps)

DT_NH_clean <- read.csv("~/DT_NH_clean.csv")
DT_NH_clean <- DT_NH_clean[-16,]
View(DT_NH_clean)




DT_NH_clean %>% summarise(districts = n(), schools = sum(num_schools), students = sum(num_students))
# districts   schools   students
#    66         208      93446

summary(DT_NH_clean$consortium_member) #41 districts are not, 26 districts are (consortium at district level)


##### GOALS & FIBER SECTIONS #####

### Function: Calculating Percentages ###
calc_percent <- function(sub, total, digs){
  frac <- round((nrow(sub)/nrow(total))*100, digits=digs)
  print(frac)
}

### Highest Connection Type (n=67) ###
summary(DT_NH_clean$highest_connect_type)
#Fiber: 45    Cable/DSL: 19    Copper: 2
round((45/nrow(DT_NH_clean)*100), digits = 0) #Fiber Districts: 68% 
round((19/nrow(DT_NH_clean))*100, digits=0) #Cable/DSL Districts: 29%


### Bandwidth Per Student (Still at District Level) ###
hist(DT_NH_clean$ia_bandwidth_per_student)
summary(DT_NH_clean$ia_bandwidth_per_student)

### Function: Making Subsets Meeting Goals ###
meeting_goals <- function(data, column, low, high){
  args <- as.list(match.call())
  data %>% 
    filter(eval(args$column, data) >= low & eval(args$column,data) < high)
}

## Districts Not Meeting 2014 Goals ##
bw_low <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 0, 100)
View(bw_low)
nrow(bw_low) #22

# Schools Not Meeting 2014 Goals
sum(bw_low$num_schools) #74

## Districts Meeting 2014 Goals but Excluding Districts Meeting 2018 Goals ##
mg_2014 <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 100, 1000)
View(mg_2014)
nrow(mg_2014) #41

## Districts Meeting 2018 Goals ##
mg_2018 <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 1000, 2000)
View(mg_2018)
nrow(mg_2018) #3

#Meeting 2014 Goals (which is the sum of districts meeting 2014 and those meeting 2018 goals)
(nrow(mg_2014) + nrow(mg_2018))/ nrow(DT_NH_clean) #67%

#Districts Meeting 2018 Goals
round(nrow(mg_2018) / nrow(DT_NH_clean), digits = 3) 

## Percentage of Not Meeting Goals ##
calc_percent(bw_low, DT_NH_clean, 2) %>% round(0)

## Percentage of Meeting 2014 Goals ##
calc_percent(mg_2014, DT_NH_clean, 2) %>% round(0)

## Percentage of Meeting 2018 Goals ##
calc_percent(mg_2018, DT_NH_clean, 2) %>% round(0)

### Among Districts Below 2014 Goals, Which Are < 50 Kbps ? ###
bw_low_50 <- bw_low %>% filter(ia_bandwidth_per_student < 50) 
nrow(bw_low_50) #12 districts
round((12/22)*100, digits=0) #About 55% range between 0-49 kbps 


summary(bw.low$highest_connect_type) #16 on Fiber; 4 are on Cable/DSL


# Meeting 2018 Goals (n=3) #
summary(mg_2018$highest_connect_type)
#Fiber: 0    Cable/DSL: 3    Copper: 0
#Found that these are all tiny, rural districts (<100 students)


### How Districts Meet Goals based on FRL ### NOTE: SWITCHED DATA SETS HERE TO EXPANDED VERSION
CR_MDT_NH <- read.csv("~/Desktop/ESH/CR_NH/CR_Master_Districts_Table_NH.csv") #need to use Master DT. 
CR_MDT_NH <- CR_MDT_NH[-16,] #Removed Contoocook


###FRL WAS NOT USED
frl.bw.low <- CR_MDT_NH %>% filter(ia_bandwidth_per_student < 100) %>% summarise(Min = min(frl_percent, na.rm=TRUE), 
                                                                                 Median = median(frl_percent, na.rm=TRUE), Mean = mean(frl_percent, na.rm=TRUE), 
                                                                                 Max = max(frl_percent, na.rm=TRUE)) 
frl.bw.low

frl.bw2014 <- CR_MDT_NH %>% filter(ia_bandwidth_per_student >= 100 & ia_bandwidth_per_student < 1000) %>% 
  summarise(Min = min(frl_percent, na.rm=TRUE), Median = median(frl_percent, na.rm=TRUE), 
            Mean = mean(frl_percent, na.rm=TRUE), Max = max(frl_percent, na.rm=TRUE)) 
frl.bw2014

frl.bw2018 <- CR_MDT_NH %>% filter(ia_bandwidth_per_student >= 1000) %>% 
  summarise(Min = min(frl_percent, na.rm=TRUE), Median = median(frl_percent, na.rm=TRUE), 
            Mean = mean(frl_percent, na.rm=TRUE), Max = max(frl_percent, na.rm=TRUE)) 
frl.bw2018

### Distribution of districts by FRL ###
d.frl <- density(as.numeric(CR_MDT_NH$frl_percent), na.rm=TRUE) #3 districts do not have available frl_percent
plot(d.frl, main = "FRL Percentage Distribution by District")


### Of The Districts Meeting Goals: which barely surpass goals, which are on good track ### 
# n = 41
barely <- DT_NH_clean %>% filter(ia_bandwidth_per_student >= 100 & ia_bandwidth_per_student < 500) 
nrow(barely) #35 schools
round((35/41)*100, digits=0) #85%

barely2 <- DT_NH_clean %>% filter(ia_bandwidth_per_student >= 100 & ia_bandwidth_per_student < 400) 
nrow(barely2) #33 schools
round((33/41)*100, digits=0) #80%

barely3 <- DT_NH_clean %>% filter(ia_bandwidth_per_student >= 100 & ia_bandwidth_per_student < 300) 
nrow(barely3) #27 schools
round((27/41)*100, digits=0) #66%

barely4 <- DT_NH_clean %>% filter(ia_bandwidth_per_student >= 100 & ia_bandwidth_per_student < 200) 
nrow(barely4) #17 schools
round((17/41)*100, digits=0) #41%

##### AFFORDABILITY SECTION #####
#Use the LI_NH_clean dataset
LI_NH_clean <- read.csv("~/Desktop/ESH/CR_NH/LI_NH_clean.csv")
View(LI_NH_clean)
### Clean imported csv file ###
LI_NH_clean <- LI_NH_clean[,-1]
LI_NH_clean <- sapply(LI_NH_clean, as.character)
colnames(LI_NH_clean) <- LI_NH_clean[1, ]
LI_NH_clean <- as.data.frame(LI_NH_clean[-1,])
LI_NH_clean <- LI_NH_clean[,1:56] #only want to keep columns with info
View(LI_NH_clean)

### Circuit Size Cost ###
csc <- LI_NH_clean %>% filter(internet_conditions_met == TRUE & applicant_name != "CONTOOCOOK VALLEY REG SCH DIST") 
nrow(csc) #Filtered out for internet_conditions_met. This reduces dataset to n=116.
summary(csc$connect_type) #8 categories

rural3 <- csc %>% filter(applicant_locale == "Rural")
nrow(rural3) #50

## Local == RURAL and Percentile values for CONNECT_TYPE == Lit Fiber Service @ 100 Mbps ##
rural2 <- rural3 %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service") 
rural100 <- rural2 %>% filter(bandwidth_in_mbps==100)
nrow(rural100) #n=3

rural.cdsl <- rural3 %>% filter(connect_category == "Cable / DSL")
nrow(rural.cdsl) #n=25
rural3$bandwidth_in_mpbs <- as.numeric(gsub(",","",rural3$bandwidth_in_mbps))


##Density points spread for Fiber
## Monthly cost per circuit by connection type ##
csc$total_cost <- as.numeric(gsub(",","",csc$total_cost))
csc$num_lines <- as.numeric(gsub(",","",csc$num_lines))
csc <- transform(csc, cpl_m = round((total_cost / num_lines)/12, digits=0)) #cost per line now in new column
#View(csc)

## Percentile values for CONNECT_TYPE == Cable Modem @ 100 Mbps ##
cm <- csc %>% filter(connect_type == "Cable Modem") 
cm100 <- cm %>% filter(bandwidth_in_mbps==100)
quantile(cm100$cpl_m, c(.10, .25, .50, 0.75, 0.90)) #percentile values for Monthly Cable Modem at 100 MBPS
nrow(cm100) #n=17

## Percentile values for CONNECT_TYPE == Lit Fiber Service @ 100 Mbps ##
lfs <- csc %>% filter(connect_type == "Lit Fiber Service") 
lfs100 <- lfs %>% filter(bandwidth_in_mbps==100)
nrow(lfs100) #n=10
quantile(lfs100$cpl_m, c(.10, .25, .50, 0.75, 0.90)) #percentile values for Lit Fiber Service at 100 MBPS


## lit fiber and ethernet (together) at 200 Mbps (if the n is > than 15 lines) ##
eth.lfs <- csc %>% filter(connect_type == "Ethernet" | connect_type == "Lit Fiber Service") 
eth.lfs200 <- eth.lfs %>% filter(bandwidth_in_mbps==200)
quantile(eth.lfs200$cpl_m, c(.10, .25, .50, 0.75, 0.90)) #cost per line now in new column
#View(eth.lfs200)
nrow(eth.lfs200) #n=8; label in RED that n < 10!!

## lit fiber and ethernet (together) at 500 Mbps ##
eth.lfs500 <- eth.lfs %>% filter(bandwidth_in_mbps==500)
nrow(eth.lfs500) #n=0
#View(eth.lfs)

##lit fiber and ethernet (together) at 1000 Mbps (also referred to as 1 G) ##
eth.lfs1G$bandwidth_in_mbps <- as.numeric(gsub(",","",eth.lfs1G$bandwidth_in_mbps))
eth.lfs1G <- eth.lfs %>% filter(bandwidth_in_mbps==1000)
nrow(eth.lfs500) #n=0
#View(eth.lfs)

## Percentile values for CONNECT_TYPE == DSL @ 30 Mbps ##
dsl <- csc %>% filter(connect_type == "Digital Subscriber Line (DSL)") 
dsl30 <- eth.lfs %>% filter(bandwidth_in_mbps==30)
nrow(dsl30) #n=2
quantile(dsl30$cpl_m, c(.10, .25, .50, 0.75, 0.90)) 

## Percentile values for CONNECT_TYPE == Cable Modem @ 50 Mbps ##
cm50 <- cm %>% filter(bandwidth_in_mbps==50)
nrow(cm50) #n=7
quantile(cm50$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Percentile values for CONNECT_TYPE == Cable Modem @ 1000 Mbps ##
cm$bandwidth_in_mbps <- as.numeric(gsub(",","",cm$bandwidth_in_mbps))
cm1000 <- cm %>% filter(bandwidth_in_mbps==1000)
nrow(cm1000) #n=0
quantile(cm1000$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Percentile values for CONNECT_TYPE == DS-1 (T-1) for all Mbps ##
ds1 <- csc %>% filter(connect_type == "DS-1 (T-1)") 
nrow(ds1) #4
quantile(ds1$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## No copper/T3 in dataset 

## Percentile values for CONNECT_TYPE == Standalone Internet Access for all Mbps ##
sia <- csc %>% filter(connect_type == "Standalone Internet Access") 
nrow(sia) #n=5
quantile(sia$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Percentile values for CONNECT_TYPE == E.g., Microwave Service for all Mbps ##
other <- csc %>% filter(connect_type == "E.g., Microwave Service") 
nrow(other) #n=1

## CONNECT_TYPE == Dark Fiber Service (n=0) ##
dfs <- csc %>% filter(connect_type == "Dark Fiber Service") 
nrow(dfs) 
#n=0


### Affordability According to CONNECT_CATEGORY ###
summary(csc$connect_category)

#We want to group BW values in ranges for each connect category since n's are overall very small.
#E.g. 1-10 kpbs, 11-50 kbps
bw_range <- factor(rep(NA, dim(csc)[1]), levels=c("0-99 Mbps", "100-199 Mbps", "200-299 Mbps", "300-399 Mbps", "1000+ Mbps"))
csc$bandwidth_in_mbps <- as.numeric(gsub(",","",csc$bandwidth_in_mbps))
csc$bandwidth_in_mbps[is.na(csc$bandwidth_in_mbps)] <- 1000

bw_range[csc$bandwidth_in_mbps >=0 & csc$bandwidth_in_mbps <= 99] <- "0-99 Mbps"
bw_range[csc$bandwidth_in_mbps > 99 & csc$bandwidth_in_mbps <= 199] <- "100-199 Mbps"
bw_range[csc$bandwidth_in_mbps > 199 & csc$bandwidth_in_mbps <= 299] <- "200-299 Mbps"
bw_range[csc$bandwidth_in_mbps > 299 & csc$bandwidth_in_mbps <= 399] <- "300-399 Mbps"
bw_range[csc$bandwidth_in_mbps >= 1000] <- "1000+ Mbps"
csc$bw_range <- bw_range
#View(csc)

#Recall, fiber (n=57)
nrow(csc %>% filter(connect_category=="Fiber"))
two <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "0-99 Mbps")
nrow(two) #19

four <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "100-199 Mbps")
nrow(four) #n=18

five <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "200-299 Mbps")
nrow(five) #n=13

six <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "300-399 Mbps")
nrow(six) #n=5

seven <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "1000+ Mbps")
nrow(seven) #n=2

##Average Internet cost is more expensive than other states (include ME, MA, and avg cost from A-B from above slide, $3 dotted line target)
round(quantile(two$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #0-99 Mbps
round(quantile(four$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #100-199 Mbps
round(quantile(five$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #200-299 Mbps

## percentile cost per circuit for districts just at 100 Mbps ##
cpl_m_100 <- csc %>% filter(bandwidth_in_mbps==100)
summary(cpl_m_100$cpl_m) #Median is $240

## percentile cost per circuit for districts with BW in 100 - 199 Mbps range ##
summary(four$cpl_m)

##Rural districts pay almost 50% more for Lit Fiber
## percentile cost per circuit for RURAL districts with BW in 100-199 Mbps range ##
four_rural <- four %>% filter(applicant_locale == "Rural") 
nrow(four_rural) # There are 7 Rural Districts
round(quantile(four_rural$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) 
#10%  25%  50%  75%  90% 
#1131 1375 1864 2306 3028 



four_not_rural <- four %>% filter(applicant_locale != "Rural")
nrow(four_not_rural) #There are 11 Other districts
round(quantile(four_not_rural$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) 
#10%  25%  50%  75%  90% 
#875 1058 1272 2014 2510 


## percentile cost per line for RURAL districts with BW in 200-299 Mbps range ##
five_rural <- five %>% filter(applicant_locale == "Rural") 
nrow(five_rural) # There are 4 Rural Districts
round(quantile(five_rural$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) 
#10%  25%  50%  75%  90% 
#918 1356 1842 2155 2285

five_not_rural <- five %>% filter(applicant_locale != "Rural")
nrow(five_not_rural) #There are 9 Other districts
round(quantile(five_not_rural$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) 
#10%  25%  50%  75%  90% 
#1128 1250 1485 1500 1840 



two.four.five <- rbind(two,four,five)
# Density plots with semi-transparent fill
a <- ggplot(two.four.five, aes(x=cpl_m, fill=bw_range)) + geom_density(alpha=.3) + xlab("Monthly Cost Per Line")
a + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.text.y = element_blank(), 
          axis.title.y = element_blank(), axis.ticks.y = element_blank())

# Simply the density lines
b <- ggplot(two.four.five, aes(x=cpl_m, colour=bw_range)) + geom_density() + xlab("Monthly Cost Per Line") 
b + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.text.y = element_blank(), 
          axis.title.y = element_blank(), axis.ticks.y = element_blank())

#Distribution by locale (controlling for district_size== Small, bc this is the most prevalent district_size)
four.small <- four %>% filter(district_size == "Small")
nrow(four.small) #10 districts
e <- ggplot(four.small, aes(x=cpl_m, colour=locale)) + geom_density() + xlab("Monthly Cost per Circuit (n=10)")
f <- e + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
               panel.background = element_blank(), axis.text.y = element_blank(), 
               axis.title.y = element_blank(), axis.ticks.y = element_blank())
f


# Plotting price points according to BW Range
ggplot(two.four.five, aes(x=bw_range, colour = bw_range, y=cpl_m)) + geom_point(size=8, alpha=0.75) + xlab("BW Range") + ylab("Monthly Cost Per Circuit ($)") + theme_classic() + theme(legend.position="none")
bw_range2 <- two.four.five %>% filter(bw_range == "100-199 Mbps")
summary(bw_range2$cpl_m) #Min: $800, Median: 1821, Max: 4803

bw_range1 <- two.four.five %>% filter(bw_range == "0-99 Mbps")
summary(bw_range1$cpl_m) #Median: $721

bw_range3 <- two.four.five %>% filter(bw_range == "200-299 Mbps")
summary(bw_range3$cpl_m) #Median: $1500

bw_range_100_only <- bw_range2 %>% filter(bandwidth_in_mbps == 100)
summary(bw_range_100_only$cpl_m) #Median: 1272
nrow(bw_range_100_only) #n=11

View(bw_range_100_only)


### Price Dispersion for Cable / DSL @ 100 Mbps (Monthly Cost Per Line) ####
cdsl <- csc %>% filter(connect_category == "Cable / DSL")
nrow(cdsl) #cable/dsl n = 54
c.dsl100 <- csc %>% filter(connect_category == "Cable / DSL" & bandwidth_in_mbps==100)
nrow(c.dsl100) #n=17
quantile(c.dsl100$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Copper (n=4) ##
cop <- csc %>% filter(connect_category == "Copper") 
nrow(cop) #n=4
quantile(cop$cpl_m, c(.10, .25, .50, 0.75, 0.90))

cop1 <- cop %>% filter(bandwidth_in_mbps==1.5)
nrow(cop1) #n=4
quantile(cop1$cpl_m, c(.10, .25, .50, 0.75, 0.90))


## Fixed Wireless (n=1) ## Is this part of Fiber?
fw <- csc %>% filter(connect_category == "Fixed Wireless") 
nrow(fw) #n=1
fw$cpl_m #$1081.53


### boxplot ###
boxplot(cpl_m ~ connect_type, data = csc,  main="Monthly Cost Per Mbps By Connection Type", 
        xlab="Connection Type", ylab="Monthly Cost Per Mbps")


## Manually changed CONTOOCOOK VALLEY REG SCH DIST cell##
CR_LI_NH_all <- read.csv("~/Desktop/ESH/CR_NH/CR_LI_NH_all.csv")
contoocook_all <- CR_LI_NH_all %>% filter(applicant_name == "CONTOOCOOK VALLEY REG SCH DIST") 
contoocook_all$number_of_dirty_line_item_flags[contoocook_all$number_of_dirty_line_item_flags == 1] <- 0 #fix one LI to clean dirty line item
contoocook_all <- contoocook_all[1:56] #reduce to relevant columns
#View(contoocook_all)


#Lit fiber WAN cost 12x more in some areas (refer to row #s on button on slide)
### WAN ###
##First, WAN analysis including both ERATE and NON-ERATE districts##
## filter for wan_conditions_met == TRUE, reduces rows for n ##
wan <- LI_NH_clean %>% filter(wan_conditions_met == TRUE)
wan$bandwidth_in_mbps<- as.numeric(gsub(",","",wan$bandwidth_in_mbps))
wan$open_flags[] <- lapply(wan$open_flags, as.character)
wan2 <- wan %>% filter(!grepl("upstream_circuit", open_flags))
wan3 <- wan2 %>% filter(!grepl("exclude", open_flags))
nrow(wan) #30
nrow(wan2) #29
View(wan2)

## Convert num_lines column to numeric ##
wan.lines <- sum(as.numeric(as.character(wan$num_lines))) 
wan.lines #n = 196 wan lines

# Remove punctuation from bandwidth_mbps # 
wan$bandwidth_in_mbps<- as.numeric(gsub(",","",wan$bandwidth_in_mbps))
wan1g <- wan %>% filter(bandwidth_in_mbps >= 1000) 
wan1g.lines <- sum(as.numeric(as.character(wan1g$num_lines))) 
wan1g.lines #33 lines @ >= 1G
#View(wan1g) 
wan1g.lines / wan.lines #33/196 (~16.8%) circuit lines are supporting >= 1G; 

#100 - 16.8 # 83% are < 1G


### Now, excluding Manchester and Portsmouth (both Non-Erate Districts) ###
wan.erate.only <- LI_NH_clean %>% filter(wan_conditions_met == TRUE & applicant_name != "MANCHESTER SCHOOL DISTRICT" & applicant_name != "PORTSMOUTH SCHOOL DISTRICT") 
wan.erate.only$bandwidth_in_mbps<- as.numeric(gsub(",","",wan.erate.only$bandwidth_in_mbps))
wan.erate.only$open_flags[] <- lapply(wan.erate.only$open_flags, as.character)
wan.erate.only2 <-wan.erate.only %>% filter(!grepl("upstream_circuit", open_flags))
wan.erate.only3 <- wan.erate.only2 %>% filter(!grepl("exclude", open_flags))
nrow(wan.erate.only) #28
nrow(wan.erate.only2) #27
View(wan.erate.only2)

## Convert num_lines column to numeric ##
wan.erate.only.lines <- sum(as.numeric(as.character(wan.erate.only$num_lines))) 
wan.erate.only.lines #n = 167 wan lines

# Remove punctuation from bandwidth_mbps # 
#wan.erate.only$bandwidth_in_mbps<- gsub(",","",wan.erate.only$bandwidth_in_mbps)
wan1g_erate <- wan.erate.only %>% filter(bandwidth_in_mbps == 1000)
nrow(wan1g_erate) #2


wan1g_erate_lines <- sum(as.numeric(as.character(wan1g_erate$num_lines))) 
wan1g_erate_lines #4 lines @ == 1G
#View(wan1g) 
wan1g_erate_lines / wan.erate.only.lines #4/167 (~2.4%) circuit lines for ERATE DISTRICTS ONLY are supporting >= 1G; 

### MAP For > = 3 Campus Districts and Color Code for Wan VS. Not ###
#nh_base + geom_point(data = wan.erate.only, aes(x = longitude, y = latitude, shape = highest_connect_type, 
#        colour=condition, size=ia_bandwidth_per_student), alpha=0.7, position = "jitter") +
#        scale_size(range = c(5,15))

## Number of schools ##
schools <- sum(CR_MDT_NH$num_schools) #n=208
#sum(as.numeric(as.character(wan$num_schools)))
## Number of schools with >= 1G WAN ##
wan1g.sch <- sum(as.numeric(as.character(wan1g$num_schools))) #n=28

## Number of schools with < 1G WAN ##
schools - wan1g.sch #n=180


## % of schools with >= 1G WAN ##
wan1g.sch/schools #13%
100-13 #87%


## Number of campuses: gut check of how many WAN lines we would expect to find ##
## Theoretically, there needs to be WAN lines going between campuses ##
## Excluding districts with 1 schools ##
sum(CR_MDT_NH$num_campuses) #n=183
unique(CR_MDT_NH$name) # n = 67

#Gut check cont'd ##
camp2 <- CR_MDT_NH %>% filter(num_campuses > 2) 
nrow(camp2) #21 districts
unique(camp2$name) #21 unique districts, check
sum(camp2$num_campuses) #n=116 campuses; sounds about right compared num_lines (n=167), values are within the same ballpark
View(camp2)

## Closer look at SDs with more than 1 campus. Here we find the sum of WAN lines for campuses > 2 subset ##
sum(as.numeric(camp2$gt_1g_wan_lines), as.numeric(camp2$lt_1g_fiber_wan_lines), as.numeric(camp2$lt_1g_nonfiber_wan_lines))
#61 wan lines comprised within SDs with more than 1 campus (n=151)

## Districts Level ##
# XX% districts are meeting goals?
# of the 61 wan lines are for SDs with > 2 campuses?
# We think over half of your districts (maybe 35) need WAN?
# Some of these campuses (i.e. 20) have sufficient count of direct IA lines and don't need WAN
# And only a remaining 15 districts don't seem to have sufficient connection give our data. 

#Change data type of lines
camp2$gt_1g_wan_lines <- as.numeric(as.character(camp2$gt_1g_wan_lines))
camp2$lt_1g_fiber_wan_lines <- as.numeric(as.character(camp2$lt_1g_fiber_wan_lines))
camp2$lt_1g_nonfiber_wan_lines <- as.numeric(as.character(camp2$lt_1g_nonfiber_wan_lines))

#Sum of total WAN for districts with > 2 campuses
camp2$total_wan <- camp2$gt_1g_wan_lines + camp2$lt_1g_fiber_wan_lines + camp2$lt_1g_nonfiber_wan_lines

# Sum of total WAN for districts for entire data set (^ can remove alot of codes above with this...)
CR_MDT_NH$total_wan <- CR_MDT_NH$gt_1g_wan_lines + CR_MDT_NH$lt_1g_fiber_wan_lines + CR_MDT_NH$lt_1g_nonfiber_wan_lines

##  Make function that changes column into numeric from factor ##
camp2$fiber_internet_upstream_lines <- as.numeric(camp2$fiber_internet_upstream_lines)
camp2$fixed_wireless_internet_upstream_lines <- as.numeric(camp2$fixed_wireless_internet_upstream_lines)
camp2$cable_dsl_internet_upstream_lines <- as.numeric(camp2$cable_dsl_internet_upstream_lines)
camp2$copper_internet_upstream_lines <- as.numeric(camp2$copper_internet_upstream_lines)

#Sum of internet upstream lines for districts with > 2 campuses
camp2$total_internet_upstream <- camp2$fiber_internet_upstream_lines + camp2$fixed_wireless_internet_upstream_lines + camp2$cable_dsl_internet_upstream_lines + camp2$copper_internet_upstream_lines


#Sum of total WAN & total internet upstream lines for districts with > 2 campuses
camp2$total_connect <- camp2$total_wan + camp2$total_internet_upstream 
View(camp2)

#Now subset: district_name, num_campuses, total_wan, total_upstream
camp2.sub <- select(camp2, name, num_campuses, total_connect, total_wan, total_internet_upstream)
#View(camp2.sub)
nrow(camp2.sub) #n=21


#Subset of campuses with num_campuses > their total_internet_upstream
camp4 <- camp2.sub %>% filter(num_campuses > total_internet_upstream)
camp4 <- as.data.frame(camp4)
nrow(camp4) #16
View(camp4) 
##Exporting csv for BRAD
write.csv(camp4, "no_wan_districts.csv")


#percentage of districts with DIA 
nrow(camp4)/nrow(CR_MDT_NH) #24%

# Campus Demographics; ERATE Districts Only # 
nrow(CR_MDT_NH) #66
camp1 <- CR_MDT_NH %>% filter(num_campuses == 1)
c1 <- nrow(camp1) #32 districts
round((c1 / nrow(CR_MDT_NH)*100), digits=0) #48%

camp_two <- CR_MDT_NH %>% filter(num_campuses == 2)
c2 <- nrow(camp_two) #13 districts
round((c2 / nrow(CR_MDT_NH)*100), digits=0) #20%

camp_gt3 <- CR_MDT_NH %>% filter(num_campuses >= 3)
c3 <- nrow(camp_gt3) #21 districts
round((c3 / nrow(CR_MDT_NH)*100), digits=0) #32%


### Campus Demographics for NH Population ###
DT_population <- read.csv("~/Desktop/ESH/CR_NH/DT_population.csv", stringsAsFactors=FALSE)
nrow(DT_population) #165 total districts
pop_camp1 <- DT_population %>% filter(num_campuses == 1)
pop_c1 <- nrow(pop_camp1) #92 districts
round((pop_c1 / nrow(DT_population))*100, digits=0) #56%

pop_camp_two <- DT_population %>% filter(num_campuses == 2)
pop_c2 <- nrow(pop_camp_two) #26 districts
round((pop_c2 / nrow(DT_population))*100, digits=0) #16%

pop_camp_gt3 <- DT_population %>% filter(num_campuses >= 3)
pop_c3 <- nrow(pop_camp_gt3) #47 districts
round((pop_c3 / nrow(DT_population))*100, digits=0) #28%


###FIX THIS LATER ###
campuses <- function(data, column, min, max){
  args <- as.list(match.call())
  v <- c()
  for(i in min:max)
    if(max){
      data %>% filter(eval(args$column, data) >= max)
    }
  else(data %>% filter(eval(args$column, data) == max))
  return(nrow())
  
}


## Testing Out Map Outline of Districts ##
states <- map_data("state")
nh_df <- subset(states, region == "new hampshire")
counties <- map_data("county")
nh_county <- subset(counties, region == "new hampshire")



nh_base <- ggplot(nh_df, aes(x = long, y = lat)) +
  coord_fixed(1.3) +
  geom_polygon(color = "black", fill = "white") +
  theme_classic() +  
  theme(line = element_blank(), title = element_blank(), 
        axis.text.x = element_blank(), axis.text.y = element_blank(),
        legend.text = element_text(size=16), legend.position=c(1.6, 0.5)) +
  guides(shape=guide_legend(override.aes=list(size=7)))

### Map of Districts Based on Connection Type and Meeting Goals   
##Append column that bands num_students into groups:
school_size <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("< 100 Students", "100-999 Students", "1000+ Students"))
school_size[CR_MDT_NH$num_students < 100] <- "< 100 Students"
school_size[CR_MDT_NH$num_students >= 100 & CR_MDT_NH$num_students < 1000] <- "100-999 Students"
school_size[CR_MDT_NH$num_students >= 1000] <- "1000+ Students"
CR_MDT_NH$school_size <- school_size

### Append Condition Column For Meeting Goals ###
condition <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("Below 2014", "Meets 2014", "Meets 2018"))
condition[CR_MDT_NH$ia_bandwidth_per_student < 100] <- "Below 2014"
condition[CR_MDT_NH$ia_bandwidth_per_student >= 100] <- "Meets 2014"
condition[CR_MDT_NH$ia_bandwidth_per_student >= 1000] <- "Meets 2018"
CR_MDT_NH$condition <- condition
View(CR_MDT_NH)


## NEED TO FIX SIZE: 1, 2, 3
nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, shape = highest_connect_type, 
                                           colour=condition, size = factor(school_size)), alpha=0.7, position = position_jitter(w = 0.08, h = 0.08)) 
#Still need to fix the dot sizes school size!!


### Map of Districts: WAN vs. NON-WAN Districts Comparison ###
##Append column of WAN, No WAN, and Other in the CR_MDT_NH table \
testing <- CR_MDT_NH  %>% group_by(num_campuses)  %>% summarise(n = length(num_campuses))


band_campuses <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("One Campus", "Two Campuses", "Three or More Campuses"))
band_campuses[CR_MDT_NH$num_campuses == 1] <- "One Campus"
band_campuses[CR_MDT_NH$num_campuses == 2] <- "Two Campuses"
band_campuses[CR_MDT_NH$num_campuses >= 3] <- "Three or More Campuses"
CR_MDT_NH$band_campuses <- band_campuses
View(CR_MDT_NH)





wan_status <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("WAN", "No WAN", "Other"))
wan_status[CR_MDT_NH$total_wan != 0 & CR_MDT_NH$num_campuses >=3] <- "WAN"
wan_status[CR_MDT_NH$total_wan == 0 & CR_MDT_NH$num_campuses >=3] <- "No WAN"
wan_status[CR_MDT_NH$num_campuses < 3] <- "Other"
CR_MDT_NH$wan_status <- wan_status

## Map of WAN for all clean districts: ###
### Districts that have WAN, that need WAN but don't have it, and Other (doesn't apply since < 3 campuses)
nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, 
                                           colour= wan_status), alpha=0.7, size=10,  position = position_jitter(w = 0.08, h = 0.08)) +
  scale_color_manual(values=c("dodgerblue", "salmon1", "#CCCCCC")) 

#Need to fix this accordingly: ggsave("WAN_map.png", width = 5, height = 5)




## Map of Districts According to Meeting Goals ##
#mapNHbw <- get_map(location = c(lon = mean(df$lon), lat = mean(df$lat)+0.5), zoom = 8,
#                maptype = "roadmap", scale = 2, color = "bw")

#p <- ggmap(mapNHbw) +
#geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, shape = highest_connect_type, 
#               colour=condition, size=num_schools), alpha=0.7) 

###Seeing IA_BANDWIDTH_PER_STUDENT ###
#ggmap(mapNHbw) +
#  geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, colour=ia_bandwidth_per_student), size=12, alpha=0.7) 

### Last Mile Connection Type Analysis ###
## WAN by Mbps ##
View(wan2)

## Calculate monthly cost per line ##
wan2$total_cost <- as.numeric(gsub(",","",wan2$total_cost))
wan2$num_lines <- as.numeric(gsub(",","",wan2$num_lines))
wan2 <- transform(wan2, cpc_m = round((total_cost / num_lines)/12, digits=2)) #cost per line now in new column
View(wan2)


## Group WAN by BW and sum num_lines ##
wan.group <- wan2 %>% group_by(bandwidth_in_mbps) %>% summarise(Num_Lines = sum(as.numeric(as.character(num_lines))), n=n())
View(wan.group) #We find that n > 10 for 1.5, 50, 80, 100, 300, 1000; n = num_lines; n in new df is # of line items


### Group WANs together: 0-50, 51-99, 100, 101-500, 1000 ###
#We want to group BW values in ranges for each WAN Mbps since n's are overall very small.

bw_range_wan <- factor(rep(NA, dim(wan2)[1]), levels=c("0-99 Mbps", "100 Mbps", "101-300 Mbps", "1000 Mbps"))
wan2$bandwidth_in_mbps <- as.numeric(gsub(",","",wan2$bandwidth_in_mbps))
#wan2$bandwidth_in_mbps[is.na(wan2$bandwidth_in_mbps)] <- 1000

bw_range_wan[wan2$bandwidth_in_mbps > 0 & wan2$bandwidth_in_mbps <= 99] <- "0-99 Mbps"
bw_range_wan[wan2$bandwidth_in_mbps == 100] <- "100 Mbps"
bw_range_wan[wan2$bandwidth_in_mbps > 100 & wan2$bandwidth_in_mbps <= 300] <- "101-300 Mbps"
bw_range_wan[wan2$bandwidth_in_mbps >= 1000] <- "1000 Mbps"
wan2$bw_range_wan <- bw_range_wan
View(wan2)

#Recall, WAN Line Items (n=29)
wan_one <- wan2 %>% filter(bw_range_wan == "0-99 Mbps")
nrow(wan_one) #n=14

wan_one_copper <- wan_one %>% filter(connect_category=="Copper")
wan_one_fiber <- wan_one %>% filter(connect_category=="Fiber" & connect_type != "Dark Fiber Service")

nrow(wan_one_copper) #n=3
nrow(wan_one_fiber) #n=10
quantile(wan_one_copper$cpc_m, c(.10, .25, .50, 0.75, 0.90)) #0-99 Mbps for Copper
round(quantile(wan_one_fiber$cpc_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #0-99 Mbps for Fiber


wan_three <- wan2 %>% filter(bw_range_wan == "100 Mbps" & connect_type == "Lit Fiber Service")
nrow(wan_three) #n=5
summary(wan_three$connect_category) #n=5 is all fiber
round(quantile(wan_three$cpc_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #100 Mbps
View(wan_three)
write.csv(wan_three, "wan_three.csv")

wan_four <- wan2 %>% filter(bw_range_wan == "101-300 Mbps")
nrow(wan_four) #n=3

wan_five <- wan2 %>% filter(bw_range_wan == "1000 Mbps")
nrow(wan_five) #n=4, but two line items are district owned, so we don't know total_cost for them



### Quick Glance at Non-Erate Districts ###
NH_DNR_C1 <- read.csv("~/Desktop/ESH/CR_NH/NH_DNR_C1.csv")
colnames(NH_DNR_C1)[2] <- "applicant_name"
revised.df <- LI_NH_clean[ !(LI_NH_clean$applicant_name %in% NH_DNR_C1$applicant_name), ]
#there are no non-erate districts in LI_NH_clean df. 

#16% of districts did not take advantage of E-rate
nrow(NH_DNR_C1)/nrow(DT_population) #16%
sum(NH_DNR_C1$num_students) #15098



summary(NH_DNR_C1$Locale)
#Rural: 22      Small Town: 1     Suburban:4
summary(NH_DNR_C1$Size)
#Tiny: 21   Small: 5 Medium: 1  

### Demographics of Non-Erate Districts by Locale and Size ###
##NEED TO FIX THIS BELOW:
#non_erate_dem <- aggregate(applicant_name ~ Locale + Size, NH_DNR_C1, length)
#sum(non_erate_dem$name) #27


### Demographics of Erate Districts by Locale and Size ###
erate.df <- CR_MDT_NH[ !(CR_MDT_NH$name %in% NH_DNR_C1$applicant_name), ]
#there are no non-erate districts in CR_MDT_NH df.
erate_dem <- aggregate(name ~ locale + district_size, CR_MDT_NH, length)
sum(erate_dem$name) #66

erate_dem_viz <- as.data.frame(table(CR_MDT_NH$locale, CR_MDT_NH$district_size))
colnames(erate_dem_viz) <- c("Locale", "Size", "Freq")
ggplot(erate_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "steelblue") + 
  labs(title="Erate Districts Demographics") + theme_grey() + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(axis.ticks = element_blank()) 

non_erate_dem_viz <- as.data.frame(table(NH_DNR_C1$Locale, NH_DNR_C1$Size))
colnames(non_erate_dem_viz) <- c("Locale", "Size", "Freq")
ggplot(non_erate_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "gold1") + 
  labs(title="Non-Erate Districts Demographics") + theme_grey() + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(axis.ticks = element_blank())

#### ERATE: Districts on Fiber vs. Not on Fiber ####
length(unique(LI_NH_clean$applicant_name)) #76 unique applicants
on_fib <- LI_NH_clean %>% filter(connect_category == "Fiber")
not_on_fib <- LI_NH_clean %>% filter(connect_category != "Fiber")
revised_df <- not_on_fib[ !(not_on_fib$applicant_name %in% on_fib$applicant_name), ]
View(revised_df)
length(unique(revised_df$applicant_name)) #17 unique applicants
revised_df %>% group_by(applicant_type) %>% summarise(n = n())


### EDA @ STUDENT LEVEL ###
### Comparing Sample Distribution to Population Distribution ##
DT_population <- read.csv("~/Desktop/ESH/CR_NH/DT_population.csv")

sum(CR_MDT_NH$num_students) #93446

summary(DT_population$locale)
#Rural SDT_population Suburban      Urban 
#110        17         36          2 



summary(CR_MDT_NH$locale)
#Rural Small Town   Suburban      Urban 
#39          9         16          2 

round(summary(CR_MDT_NH$locale)/nrow(CR_MDT_NH), digits=2)
#Rural Small Town   Suburban      Urban 
#0.59       0.14       0.24       0.03 

round(summary(DT_population$locale)/nrow(DT_population), digits=2)
#Rural Small Town   Suburban      Urban 
#0.67       0.10       0.22       0.01

#Percentage breakdown within locale by district size 
DT_R <- table(DT_population$locale, DT_population$district_size)

(DT_R[1,] / sum(DT_R[1,]))*100
DT_R[2,] / sum(DT_R[2,])
DT_R[3,] / sum(DT_R[3,])
DT_R[4,] / sum(DT_R[4,])



## Also for District Size ##
summary(CR_MDT_NH$district_size)
# Large Medium  Small   Tiny 
#   2      4     35     25 

summary(DT_population$district_size)
# Large Medium  Small   Tiny 
#   2     16     65     82 


round(summary(CR_MDT_NH$district_size)/nrow(CR_MDT_NH), digits=2)
#Large Medium  Small   Tiny 
#0.03   0.06   0.53   0.38 
#We find that there is a greater represenetation of Small districts than Tiny districts
#which is different from the population distribution of district sizes

round(summary(DT_population$district_size)/nrow(DT_population), digits=2)
# Large Medium  Small   Tiny 
# 0.01   0.10   0.39   0.50 


#res <- aggregate(DT_population$locale ~ DT_population$district_size,
#                FUN=function(x) c(count=length(x)))
#(res/nrow(DT_population)) * 100


res2 <- aggregate(CR_MDT_NH$locale ~ CR_MDT_NH$district_size,
                  FUN=function(x) c(count=length(x)))

#res2/nrow(CR_MDT_NH)


#Number of Students in MDT: 93446
sum(CR_MDT_NH$num_students)

#Grouping by locale and getting student count:
a <- CR_MDT_NH %>% group_by(locale) %>% summarise(students = sum(num_students))
b <- sum(CR_MDT_NH$num_students)

student_dem <- function(max){
  values <- c()
  for(i in 1:max){
    per <- round((a$students[i] / b)*100, 0) 
    values <- c(values, per)
  }
  return(values)
}

student_dem(4)

##
rural <- CR_MDT_NH %>% filter(locale == "Rural")
round((summary(rural$district_size)/nrow(rural))*100, 0)


# Which locale is most likely to lack fiber connections?
CR_MDT_NH %>% group_by(locale) %>% filter(IA.is.Fiber.or.Equiv. !="Fiber IA") %>%  summarise(connection = length(hierarchy_connect_category))
CR_MDT_NH %>% group_by(locale) %>% filter(IA.is.Fiber.or.Equiv. == "Fiber IA") %>%  summarise(connection = length(hierarchy_connect_category))

#4 Districts Switched Over to NOT FIBER after switching filter category from ^ to hierarchy_connect_category
CR_MDT_NH %>% group_by(locale) %>% filter(hierarchy_connect_category !="Fiber") %>%  summarise(connection = length(hierarchy_connect_category))
CR_MDT_NH %>% group_by(locale) %>% filter(hierarchy_connect_category == "Fiber") %>%  summarise(connection = length(hierarchy_connect_category))


# Which locale is most likely to not meet 2014 goals?
CR_MDT_NH %>% group_by(locale) %>% filter(condition !="Below 2014") %>%  summarise(goal = length(condition))
CR_MDT_NH %>% group_by(locale) %>% filter(condition =="Below 2014") %>%  summarise(goal = length(condition))


# Which district_size is most likely to lack fiber connections?
CR_MDT_NH %>% group_by(district_size) %>% filter(highest_connect_type !="Fiber") %>%  summarise(connection = length(highest_connect_type))
CR_MDT_NH %>% group_by(district_size) %>% filter(highest_connect_type == "Fiber") %>%  summarise(connection = length(highest_connect_type))


# Which district_size is most likely to not meet 2014 goals?
CR_MDT_NH %>% group_by(district_size) %>% filter(condition !="Below 2014") %>%  summarise(goal = length(condition))
CR_MDT_NH %>% group_by(district_size) %>% filter(condition =="Below 2014") %>%  summarise(goal = length(condition))

CR_MDT_NH %>% group_by(district_size) %>% summarise(n = n())




### GOALS @ Student Level###

goals_student <- CR_MDT_NH %>% group_by(condition) %>% summarise(n_students = sum(num_students))
dim(goals_student)

#function to calcuate connectivity goals by student count ONLY
goals_student_pct <- function(dim1){
  keep <- c()
  for(i in 1:dim1){
    percent <- round((goals_student[i,2] / sum(goals_student$n_students))*100, digits = 2) #41%
    keep <- c(keep, percent)
  }
  return(keep)
}

#Student Goals %s: Below 2014, Meeting 2014, and Meeting 2018, respectively
goals_student_pct(3)
goals_student

sum(CR_MDT_NH$num_students)
## Not Meeting Goals ##
sum(bw_low$num_students) #n=38658
round(sum(bw_low$num_students)/sum(CR_MDT_NH$num_students), digits=3) #41.4%

## Meeting 2014 Goals ##
sum(mg_2014$num_students) #n=54643
round(sum(mg_2014$num_students)/sum(DT_NH_clean$num_students), digits=3) #58.5%

## Meeting 2018 Goals ##
sum(mg_2018$num_students) #n=145
round(sum(mg_2018$num_students)/sum(DT_NH_clean$num_students), digits=3) #0.2%


##Student Meeting goals (2014+2018)
sum(mg_2014$num_students)+sum(mg_2018$num_students) #n=54788 
round((sum(mg_2014$num_students)+sum(mg_2018$num_students))/sum(DT_NH_clean$num_students), digits=3) #58.6

## Meeting goals based on connection type at the student level##
##Student Count by Highest Connect Type for Not Meeting 2014 Goals##
summary(bw_low$highest_connect_type)
bw_low %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
# highest_connect_type  students
#      Cable / DSL        1740
#           Copper         180
#            Fiber       36738

##Student Count by Highest Connect Type for Meeting 2014 Goals##
summary(mg_2014$highest_connect_type)
mg_2014 %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
# highest_connect_type   students
#1        Cable / DSL       6249
#2              Fiber      48394

##Student Count by Highest Connect Type for Meeting 2018 Goals##
summary(mg_2018$highest_connect_type)
mg_2018 %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
#  highest_connect_type    students
#         Cable / DSL       145



### GOALS @ School Level ###
sum(mg_2014$num_schools)+sum(mg_2018$num_schools) #n=134
round((sum(mg_2014$num_schools)+sum(mg_2018$num_schools))/sum(DT_NH_clean$num_schools), digits=3) #64.4%

round(sum(mg_2018$num_schools)/sum(DT_NH_clean$num_schools), digits = 3)

## Geographic Demographics at Districts Level, Compare Sample with Population Heat Map ##
dist_dem_viz <- as.data.frame(table(CR_MDT_NH$locale, CR_MDT_NH$district_size))
colnames(dist_dem_viz) <- c("Locale", "Size", "Freq")

ggplot(dist_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "steelblue") + 
  labs(title="Sample Districts Demographics") + theme_grey(base_size = 18) + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(axis.ticks = element_blank()) 


pop_dem_viz <- as.data.frame(table(DT_population$locale, DT_population$district_size))
colnames(pop_dem_viz) <- c("Locale", "Size", "Freq")
ggplot(pop_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "darkgreen") + 
  labs(title="Population Districts Demographics") + theme_grey(base_size = 18) + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(axis.ticks = element_blank()) 



## Geographic demographics by Student Level ##
geo_dem_stu <- aggregate(num_students ~ locale + district_size, CR_MDT_NH, FUN = sum)
sum(geo_dem_stu$num_students)

geo_dem_stu2 <- geo_dem_stu %>% mutate(percentage = round(num_students/sum(num_students)*100, digits = 0))

par(mfrow=c(1,2))
ggplot(geo_dem_stu2, aes(locale, district_size)) +
  geom_tile(aes(fill = num_students), colour = "white") +
  scale_fill_gradient(low = "white", high = "steelblue") + 
  labs(title="Student Convenience Sample")

geo_dem_pop <- aggregate(num_students ~ locale + district_size, DT_population, FUN = sum)
sum(geo_dem_pop$num_students) #matches up
sum(DT_population$num_students) #matches up
geo_dem_pop2 <- geo_dem_pop %>% mutate(percentage = round(num_students/sum(num_students)*100, digits = 0))

p <- ggplot(geo_dem_pop2, aes(locale, district_size)) +
  geom_tile(aes(fill = num_students), colour = "white") +
  scale_fill_gradient(low = "white", high = "dark green") + 
  labs(title="Student Population")



base_size <- 9
p + theme_grey(base_size = base_size) + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(legend.position = "none", axis.ticks = element_blank(), 
                                             axis.text.x = element_text(size = base_size, angle = 330, hjust = 0, colour = "grey50"))


### Figuring Out Which Districts in Low BW group Are Paying Same Amount as Districts in Mid BW group ##
View(four)
min(four$cpl_m) #$800

op <- two %>% filter(cpl_m > 800)
nrow(two) #n=19
nrow(op) #n=9;
View(op)
#NOTE: half of the districts in the 11-50Mbps category are paying more than the minimum paying district with 100-199 Mbps
#They are all on fiber, all 20-50 Mbps, half of them are Rural, other half Small Town, one unknown, 
#district_sizes include: Tiny, Small, Medium
#Price ranges from: $865-1680 ~almost 2x price variability.
#TAKEAWAY: schools/districts of ^ characteristic are paying more than min. cost district in 100-199Mbps BW group.
#But then again, note that the min. cost line item in 100-199 Mbps BW group is listed as "CONSORTIA" 
#Second to min. cost line item in this BW group is listed as "District". 

### Price Comparison of Lit Fiber @ 100 Mbps Across Locale ###
#fib %>% group_by(locale) %>% summarise(average_monthly_cost = mean(cpl_m), n=n()) #
#fib100 %>% group_by(locale) %>% summarise(average_monthly_cost = mean(cpl_m), n=n()) #@100 Mbps

### FUNCTION: fixing the SP columns ###
fix_SP <- function(df){
  int_SP <- strsplit(as.character(df), '","', perl=T)
  unlisted_int_SP <- unlist(int_SP)
  unlisted_int_SP2 <- gsub( "[^[:alnum:],]", "", unlisted_int_SP)
  unlisted_int_SP2 <- gsub("NULL", "", unlisted_int_SP2)
  unique(unlisted_int_SP2) 
  unlisted_int_SP2 <- sub("^$", "SP Not Available", unlisted_int_SP2)
  unlisted_int_SP2
  
  t0 <- as.data.frame(unlisted_int_SP2)
  
  new_table <- as.data.frame(table(t0))
  colnames(new_table) <- c("sp", "freq")
  new_table2 <- mutate(new_table, percent=round((freq/sum(freq))*100, digits=0)) %>% arrange(desc(percent))
  print(new_table2)
  
}

### Internet Service Providers ###
max(CR_MDT_NH$internet_sp_count) #3 is the maximum number of SPs a given district in the df will have

### At the LINE ITEMS level ###
### Is there a relationship between connect type and SP? ###
ct_sp <- LI_NH_clean %>% filter(internet_conditions_met == TRUE | upstream_conditions_met == TRUE) 
nrow(ct_sp) #n=134 lines

## Not really one dominant service provider. However, Enhanced Comm. of Northern New England 
## Has highest marketshare for fiber connections
fib_ct_sp <- ct_sp %>% filter(connect_category == "Fiber")
sum(as.numeric(as.character(fib_ct_sp$num_lines))) #n= 89 fiber lines (sum of num_lines!!)
y <- fix_SP(fib_ct_sp$service_provider_name)
sum(y$freq) #n=68 checked; 

cdsl_ct_sp <- ct_sp %>% filter(connect_category == "Cable / DSL")
nrow(cdsl_ct_sp) #n=61
z <- fix_SP(cdsl_ct_sp$service_provider_name)
sum(z$freq) #61 checked.

fw_ct_sp <- ct_sp %>% filter(connect_category == "Fixed Wireless")
nrow(fw_ct_sp) #n=1
w <- fix_SP(fw_ct_sp$service_provider_name) #checked


### Let's Try to Group Service Providers Together ###
sp_category <- read.csv("~/Desktop/ESH/CR_NH/sp_category.csv")
ct_sp$category <- sp_category[match(ct_sp$service_provider_name, sp_category$name),"category"] 
ct_sp$reporting_name <- sp_category[match(ct_sp$service_provider_name, sp_category$name),"reporting_name"] 

summary(ct_sp$category)
summary(ct_sp$reporting_name) #Now we find that Comcast has the highest market share
market_players <- as.data.frame(table(ct_sp$reporting_name))
colnames(market_players) <- c("sp", "freq")
market_players <-  market_players %>% filter(freq >= 1)
View(market_players) #n=17

##### BY REPORTING NAME FOR EACH CONNECTION TYPE #####
#### TOTAL ###
sum(market_players$freq) #n=134 total
mp <- mutate(market_players, percent=round((freq/sum(freq))*100, digits=0)) %>% arrange(desc(percent))
View(mp)
sum(mp$freq) #n=134 checked.

### FIBER ### NEED TO FIX THIS
#fib_mp <- fix_SP(fib_ct_sp$reporting_name)
#View(fib_mp)

### CABLE / DSL ### NEED TO FIX THIS
#cdsl_mp <- fix_SP(cdsl_ct_sp$reporting_name)
#View(cdsl_mp)


### At the DISTRICT Level ###
### Internet Total SPs###
internet_sp <- fix_SP(CR_MDT_NH$internet_sp)

## Upstream Total SPs##
upstream_sp <- fix_SP(CR_MDT_NH$upstream_sp)

## WAN Total SPs ##
wan_sp <- fix_SP(CR_MDT_NH$wan_sp)

## ISP Total SPs##
isp_sp <- fix_SP(CR_MDT_NH$isp_sp)

## TOTAL Total SPs##  
##NEED TO FIX THIS, BC IF I REFRESH GLOBAL ENVIRONMENT, THESE FOUR VARS IN THE COMBINED_SP WILL NO LONGER EXIST.
#combined_SP <- c(unlisted_int_SP2, unlisted_up_SP2,unlisted_wan_SP2,unlisted_isp_SP2) 
#View(fix_SP(combined_SP))
internet_sp$sp <- gsub("[[:punct:]]", "", internet_sp$sp)
sp_category$name <- gsub("[[:punct:]]", "", sp_category$name)
sp_category$name <- gsub(" ", "", sp_category$name)
View(sp_category)
internet_sp$category <- sp_category[match(internet_sp$sp, sp_category$name),"category"] 
internet_sp$reporting_name <- sp_category[match(internet_sp$sp, sp_category$name),"reporting_name"] 


wan_sp$sp <- gsub("[[:punct:]]", "", wan_sp$sp)
wan_sp$category <- sp_category[match(wan_sp$sp, sp_category$name),"category"] 
wan_sp$reporting_name <- sp_category[match(wan_sp$sp, sp_category$name),"reporting_name"] 
View(wan_sp)

### NEED TO FIX THIS FUNCTION: Fixing/Matching Punctuation of within MDT and SP_Category datasets ###
fix_punct <- function(v,sp_category,x,y,z, name0, name, name2){
  
  x<- gsub("[[:punct:]]", "", x)
  y<- gsub("[[:punct:]]", "", y)
  y <- gsub(" ", "", y)
  z <- sp_category[match(x, y), name] 
  name0<- sp_category[match(x, y), name2] 
  return(v)
}

### SPs are now grouped by REPORTING NAME at the DISTRICT LEVEL
fix_int_sp <- fix_punct(internet_sp, sp_category, internet_sp$sp, sp_category$name, internet_sp$category, internet_sp$reporting_name, "category", "reporting_name")
int_sp_rep_names <- fix_int_sp %>% filter(reporting_name != "NA") %>% group_by(reporting_name) %>% summarise(frequency = sum(freq), percentage = sum(percent))
View(int_sp_rep_names)

#need to fix this# fix_wan_sp <- fix_punct(wan_sp, sp_category, wan_sp$sp, sp_category$name, wan_sp$category, wan_sp$reporting_name, "category", "reporting_name")
#wan_sp_rep_names <- wan_sp %>% filter(reporting_name != "NA") %>% group_by(reporting_name) %>% summarise(frequency = sum(freq), percentage = sum(percent))
#View(wan_sp_rep_names)




### NOW, WAN ### 
wan_ct_sp <-LI_NH_clean %>% filter(wan_conditions_met == TRUE)
nrow(wan_ct_sp) #n=30 lines

#wan_ct_sp$category <- sp_category[match(wan_ct_sp$service_provider_name, sp_category$name),"category"] sp_category$name <- gsub("[[:punct:]]", "", sp_category$name)
wan_ct_sp$service_provider_name  <- gsub("[[:punct:]]", "", wan_ct_sp$service_provider_name)
wan_ct_sp$service_provider_name  <- gsub(" ", "", wan_ct_sp$service_provider_name)

wan_ct_sp$reporting_name <- sp_category[match(wan_ct_sp$service_provider_name, sp_category$name),"reporting_name"] 
summary(wan_ct_sp$reporting_name)
wan_sp <- as.data.frame(table(wan_ct_sp$reporting_name))
colnames(wan_sp) <- c("name", "freq")
wan_sp <-  wan_sp %>% filter(freq >= 1) %>% arrange(desc(freq))
View(wan_sp)

## Comcast provides a majority of fiber and non-fiber connections
### SP @ Circuit Level ###
### TOTAL ###
n_lines_total <- as.numeric(as.character(ct_sp$num_lines))
circ_total <- rep(ct_sp$service_provider_name, n_lines_total)
length(circ_total) #196
circ_total_tab <- as.data.frame(table(circ_total))
View(circ_total_tab)

#Merging by reporting_name#
colnames(circ_total_tab) <- c("name", "freq")
circ_total_tab$name <- gsub("[[:punct:]]", "", circ_total_tab$name)
circ_total_tab$name <- gsub(" ", "", circ_total_tab$name)
#circ_total_tab$category <- sp_category[match(circ_total_tab$name, sp_category$name),"category"] 
circ_total_tab$reporting_name <- sp_category[match(circ_total_tab$name, sp_category$name),"reporting_name"] 

##BY Reporting Name
circ_total_tab_2 <- circ_total_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=0)) %>% 
  arrange(desc(freq))

sum(circ_total_tab_2$freq) #196
View(circ_total_tab_2)



### FIBER ###
fib_ct_sp <- ct_sp %>% filter(connect_category == "Fiber")
n_lines_fib <- as.numeric(as.character(fib_ct_sp$num_lines))
circ_fib <- rep(fib_ct_sp$service_provider_name, n_lines_fib)  
circ_fib_tab <- as.data.frame(table(circ_fib))
#View(circ_fib_tab)
length(circ_fib) #89 checked


# Merging by reporting_name #
colnames(circ_fib_tab) <- c("name", "freq")
circ_fib_tab$name <- gsub("[[:punct:]]", "", circ_fib_tab$name)
circ_fib_tab$name <- gsub(" ", "", circ_fib_tab$name)
#circ_fib_tab$category <- sp_category[match(circ_fib_tab$sp, sp_category$name),"category"] 
circ_fib_tab$reporting_name <- sp_category[match(circ_fib_tab$name, sp_category$name),"reporting_name"] 

circ_fib_tab_2 <- circ_fib_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=2)) %>% 
  arrange(desc(freq))

sum(circ_fib_tab_2$freq) #89 checked
View(circ_fib_tab_2)
sum(circ_fib_tab_2$percent)


fiber_sp <- sum(circ_fib_tab_2$percent[1:4])
fiber_sp #sum of fiber SP percentages: 57.31

other_fiber_sp <- sum(circ_fib_tab_2$percent[5:19])
other_fiber_sp #sum of non-fiber SP percents: 42.67




### CABLE/DSL ###
cdsl_ct_sp <- ct_sp %>% filter(connect_category == "Cable / DSL")
n_lines_cdsl <- as.numeric(as.character(cdsl_ct_sp$num_lines))
circ_cdsl <- rep(cdsl_ct_sp$service_provider_name, n_lines_cdsl)  
circ_cdsl_tab <- as.data.frame(table(circ_cdsl))
#View(circ_cdsl_tab)
#length(circ_cdsl) #95


# Merging by reporting_name #
colnames(circ_cdsl_tab) <- c("sp", "freq")
circ_cdsl_tab$sp <- gsub("[[:punct:]]", "", circ_cdsl_tab$sp)
circ_cdsl_tab$sp <- gsub(" ", "", circ_cdsl_tab$sp)
circ_cdsl_tab$category <- sp_category[match(circ_cdsl_tab$sp, sp_category$name),"category"] 
circ_cdsl_tab$reporting_name <- sp_category[match(circ_cdsl_tab$sp, sp_category$name),"reporting_name"] 

circ_cdsl_tab_2 <- circ_cdsl_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=0)) %>% 
  arrange(desc(freq))

sum(circ_cdsl_tab_2$freq) #95
#View(circ_cdsl_tab_2)

#JUST TO MAKE SURE SUM ADDS UP: The rest #should be 12 lines
sum(as.numeric(as.character(ct_sp$num_lines)))
rest_ct_sp <- ct_sp %>% filter(connect_category != "Fiber" & connect_category != "Cable / DSL")
n_lines_rest <- as.numeric(as.character(rest_ct_sp$num_lines))
circ_rest <- rep(rest_ct_sp$service_provider_name, n_lines_rest)
#length(circ_rest) #12 checked.


# Creating the "Non-Fiber" Category for Fiber/Non-Fiber Comparison by SP #
### CABLE/DSL ###
nonfib_ct_sp <- ct_sp %>% filter(connect_category != "Fiber")
n_lines_nonfib <- as.numeric(as.character(nonfib_ct_sp$num_lines))
circ_nonfib <- rep(nonfib_ct_sp$service_provider_name, n_lines_nonfib)  
circ_nonfib_tab <- as.data.frame(table(circ_nonfib))
#View(circ_nonfib_tab)
sum(length(circ_rest),length(circ_cdsl)) #107 checked
sum(circ_nonfib_tab$Freq) #107 checked




# Merging by reporting_name #
colnames(circ_nonfib_tab) <- c("name", "freq")
circ_nonfib_tab$name <- gsub("[[:punct:]]", "", circ_nonfib_tab$name)
circ_nonfib_tab$name  <- gsub(" ", "", circ_nonfib_tab$name)
#circ_nonfib_tab$category <- sp_category[match(circ_nonfib_tab$name, sp_category$name),"category"] 
circ_nonfib_tab$reporting_name <- sp_category[match(circ_nonfib_tab$name, sp_category$name),"reporting_name"] 

circ_nonfib_tab_2 <- circ_nonfib_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=2)) %>% 
  arrange(desc(freq))

sum(circ_nonfib_tab_2$freq) #107
View(circ_nonfib_tab_2)
sum(circ_nonfib_tab_2$percent)

nonfiber_sp <- sum(circ_nonfib_tab_2$percent[1:4])
nonfiber_sp #sum of non-fiber SP percentages: 86.93

other_nonfiber_sp <- sum(circ_nonfib_tab_2$percent[5:19])
other_nonfiber_sp #sum of non-fiber SP percents: 13.08


### Distribution of SPs by location ###
##append lon. and lat. columns to ct_sp
ct_sp$longitude <- DT_population[match(ct_sp$applicant_name, DT_population$name),"longitude"] 
ct_sp$latitude <- DT_population[match(ct_sp$applicant_name, DT_population$name),"latitude"] 
#View(ct_sp)

loc_ct_sp <- ct_sp %>% filter(longitude != "NA")
#View(loc_ct_sp) #checked

#Map with Google Image
#ggmap(mapNH) +
# geom_point(data = loc_ct_sp, aes(x = longitude, y = latitude, 
#                                   colour=reporting_name), size = , alpha=0.7) 

#Color coded based on Reporting Name
nh_base + geom_point(data = loc_ct_sp, aes(x = longitude, y = latitude,
                                           colour=reporting_name), size = 11, alpha=0.7, position = position_jitter(w = 0.08, h = 0.08))

#We want to look at just COMCAST and color code by fiber v. not fiber
comcast <- ct_sp %>% filter(reporting_name == "Comcast")
View(comcast)
unique(comcast$applicant_name) #24 unique applicants

#In terms of fiber, there's only lit fiber (checked before making this condition)
comcast$condition <- ifelse(comcast$connect_type == "Lit Fiber Service", "Fiber", "Non-Fiber")

nh_base + geom_point(data = comcast, aes(x = longitude, y = latitude,
                                         colour=condition), size = 11, alpha=0.7, position = position_jitter(w = 0.08, h = 0.08)) +
  scale_color_manual(values=c("#FFCC33", "#339999")) 





#Color coded based on SP Category
nh_base + geom_point(data = loc_ct_sp, aes(x = longitude, y = latitude,
                                           colour=category), size = 11, alpha=0.7,  position = position_jitter(w = 0.08, h = 0.08)) 
#        + scale_color_manual(labels=c("Other", "Big Cable", "Enterprise", "Mid Telco"))



### compare to cost & locale e.g. districts that are 100Mbps, Lit Fiber, Suburban ###
#Harder to do bc there's many rows using more than one service providers #


## For Exectutive Summary Affordability Bullet ##
#Average cost for internet per Mbps: 
internet <- LI_NH_clean %>% filter(internet_conditions_met == TRUE)

#append column in LI talbe for cost per Mbps. will use this to find the average cost for internet per Mbps
internet$total_cost <- gsub(",", "", internet$total_cost)
internet$bandwidth_in_mbps <- gsub(",", "", internet$bandwidth_in_mbps)
internet <- internet %>% mutate(cost_per_mbps = round(as.numeric(as.character(total_cost)) / as.numeric(as.character(bandwidth_in_mbps)), digits = 0))
#View(internet)

## ACCOUNT FOR NUM_LINES
#head(internet$total_cost / (internet$bandwidth_in_mbps*as.numeric(as.character(internet$num_lines))))

mean(internet$cost_per_mbps) #Mean cost/Mbps: $268.91
median(internet$cost_per_mbps) #Median cost/Mbps: $94
summary(internet$cost_per_mbps)

### Disaggregate districts that are Cable and those that are DSL ###
### Among the Districts that are categorized as Cable / DSL, which are Cable and which are DSL? ###
cdsl <- CR_MDT_NH %>% filter(all_ia_connectcat == '{"Cable / DSL"}')
nrow(cdsl) #18
#View(cdsl)

cdsl <- CR_MDT_NH %>% filter(all_ia_connectcat == '{"Cable / DSL"}')  %>% select(name, all_ia_connectcat, all_ia_connecttype, internet_sp)
#3 districts are DSL
#15 are Cable Modem

### Schools on Fiber ###
num_schools_on_fib <- CR_MDT_NH %>% filter(highest_connect_type == "Fiber") %>% summarise(schools = sum(num_schools))
num_schools_on_fib #176
total_num_schools <- sum(CR_MDT_NH$num_schools) #208
total_num_schools
round((num_schools_on_fib / total_num_schools)*100, digits=0) # 85%


##### Looking Into Services Received #####
SR_NH <- read.csv("~/Desktop/ESH/CR_NH/SR_NH.csv")

##From Line Items Table
##Max value for WAN: 1G
##Min value for WAN: 1.5 Mbps

SR.wan <- SR_NH %>% filter(SR_NH$wan_conditions_met == TRUE & SR_NH$exclude_from_analysis == FALSE)
#View(SR.wan)

SR.wan <- SR_NH %>% filter(SR_NH$wan_conditions_met == TRUE & SR_NH$exclude_from_analysis == FALSE)
unique(SR.wan$name) #to find distinct SDs that meet above conditions
sum(as.numeric(as.character(SR.wan$quantity_of_lines_received_by_district))) #n=48 matches with MDT table

#Dealing with Open_Flags = upstream_circuit
#Upstream and WAN are labelled as same technology
summary(csc$connect_category) #4 categories

##30% of districts access Internet through an SAU*
### SAU Procurement Slide ###
# append SAU vs. non-SAU slide #
#if applicant_name contains "school administration unit", classify as SAU

#We only want clean districts so exclude == FALSE
#Filter for wan_conditions_met == FALSE so that we can capture both upstream and internet lines 
SR_NH <- SR_NH %>% filter(exclude == FALSE & name != "CONTOOCOOK VALLEY SCHOOL DISTRICT" & wan_conditions_met == FALSE)
nrow(SR_NH) #n=123 (originally 284 including both clean and dirty)
##now filter for just districts in our MDT:
colnames(SR_NH)[1] <- "esh_id"
SR_NH_revised <- semi_join(SR_NH, CR_MDT_NH, by="esh_id")


sau <- factor(rep(NA, dim(SR_NH_revised)[1]), levels=c("SAU", "Non-SAU", "One-District SAU"))

sau[grepl("SCHOOL ADMINISTRATIVE UNIT|SAU|SCHOOL ADMINISTRATION UNIT", as.character(SR_NH_revised$applicant_name))] <- "SAU"
sau[!grepl("SCHOOL ADMINISTRATIVE UNIT|SAU|SCHOOL ADMINISTRATION UNIT", as.character(SR_NH_revised$applicant_name))] <- "Non-SAU"

SR_NH_revised$sau <- sau

## There is probably a much more elegant way to do this; I went for the more brute-force moment atm ##
SR_NH_revised$sau[grepl("LITTLETON UNION SCHOOL DISTRICT SAU 84", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU"
SR_NH_revised$sau[grepl("SAU 47 DISTRICT OFFICE", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU"   
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 05", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU"   
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 06", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 07", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 23", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 64", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("SCHOOL ADMINISTRATIVE UNIT 74", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("FREMONT SCHOOL DISTRICT-SAU8", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 
SR_NH_revised$sau[grepl("ELLIS SCHOOL-FREMONT", as.character(SR_NH_revised$applicant_name))] <- "One-District SAU" 


#View(SR_NH)  
#View(select(SR_NH, applicant_name, sau)) #to check

#Check which ways Districts procure 
sau2 <- SR_NH_revised %>% group_by(name) %>% summarise(procurement_method = length(unique(sau)), procurement_type1 = unique(sau)[1], procurement_type2 = unique(sau)[2])
View(sau2)
nrow(sau2) #66

#Calculating percentages of procurement methods:
sau2$procurement_type1 <- as.character(sau2$procurement_type1)
sau2$procurement_type2 <- as.character(sau2$procurement_type2)
thru_SAU <- sau2 %>% filter(procurement_method == 1 & procurement_type1 == "SAU" & is.na(procurement_type2) )
thru_non_SAU <- sau2 %>% filter(procurement_method == 1 & procurement_type1 == "Non-SAU" | procurement_type1 == "One-District SAU" & is.na(procurement_type2))
thru_both <- sau2 %>% filter(procurement_method == 2)
View(thru_non_SAU)
View(thru_SAU)
View(thru_both) #none

#Procurement Percentages
nrow(thru_non_SAU) #n=46
round((nrow(thru_non_SAU) / nrow(sau2))*100, digits = 0) #Non-SAU aka Districts: 70%
summary(as.factor(thru_non_SAU$procurement_type1)) #Non-SAU: 34 One-District SAU: 12 

nrow(thru_SAU) #n=20
round((nrow(thru_SAU) / nrow(sau2))*100, digits = 0) #SAU: 30%



## Digging Deeper Into the Districts that both self-procure and utilize SAU
## Chesterfield, Colebook, and Fremont

procure_both <- SR_NH %>% filter(grepl("CHESTERFIELD|COLEBROOK|FREMONT SCHOOL DISTRICT", name))
#View(procure_both)

#Show Lacy that Chesterfield and Fremont are difficult to understand in applicant_name column. 
#View(select(procure_both, name, applicant_name, exclude, purpose, wan, bandwidth_in_mbps, line_item_total_num_lines,line_item_total_cost))

#Most districts not meeting affordability goal do not meet bandwidth goal
#NH can support district upgrades
### Monthly Cost per Mpbs Calculation for Executive Summary
#We want to work in the SR_NH not LI_NH_clean data set bc we want to analyze at district level. LI shows SAU shows only applicant_name.
#First, filter for internet_conditions_met == TRUE, then meeting 2014 goals, and then look at data in ascending order (to find cutoff for meeting affordability target)
int_lines <- LI_NH_clean %>% filter(internet_conditions_met == TRUE) 
nrow(int_lines) #n=124 
int_lines$total_cost <- gsub(",", "", int_lines$total_cost)
int_lines$bandwidth_in_mbps <- gsub(",", "", int_lines$bandwidth_in_mbps)
#appending new columns for monthly cost per mbps: cpm 
LL <- int_lines %>% mutate(cpm = ((as.numeric(as.character(total_cost)) / (as.numeric(as.character(bandwidth_in_mbps))*as.numeric(as.character(num_lines))))/12)) %>% arrange(cpm)
View(LL)
sum(as.numeric(as.character(LL$num_lines)))
#Percentile values for Monthly Cost/Mbps
summary((LL$cpm))
#Mean and Median by Connect Type
LL %>% group_by(connect_type) %>% summarise(n = n(), mean = mean(cpm), median = median(cpm), num_lines = sum(as.numeric(as.character(num_lines))))

### Price Dispersion for IA Lines, Rural vs. Non-Rural @ cost per Mbps. 
rural <- LL %>% filter(applicant_locale == "Rural" & connect_type == "Lit Fiber Service")
View(rural)
summary(rural$cpm)
nrow(rural) #n = 20

non_rural <- LL %>% filter(applicant_locale != "Rural" & connect_type == "Lit Fiber Service")
summary(non_rural$cpm)
nrow(non_rural) #n = 27

#Initial but not used: ### Leaders ###
#m2014 <- CR_MDT_NH %>% filter(ia_bandwidth_per_student >= 100)
#m2014_fiber <- m2014 %>% filter(all_ia_connectcat == "{Fiber}")
#nrow(m2014_fiber) #18
#gc_m2014_fiber <- m2014_fiber %>% mutate(goal_comparison = round(total_monthly_cost/total_bw_mbps, digits=2))
#View(gc_m2014_fiber) #checked with Lacy
#now create percentiles for these values; note the median
#Compare schools with national median
#small_schools <- CR_MDT_NH %>% filter(num_students < 150)
#View(small_schools)

#Initial but not used: ### Laggards ###
#b2014 <- CR_MDT_NH %>% filter(condition == "Below 2014")
#summary(b2014$all_ia_connectcat)

## Leaders / Laggards analysis ##
##We want to sum the total of internet lines and append new column: num_int_lines
CR_MDT_NH$num_int_lines <- CR_MDT_NH$fiber_internet_upstream_lines + CR_MDT_NH$fixed_wireless_internet_upstream_lines + CR_MDT_NH$cable_dsl_internet_upstream_lines + CR_MDT_NH$copper_internet_upstream_lines
#View(CR_MDT_NH)

#USING THE CR_MDT_NH TABLE: appending new columns for monthly cost per circuit: cpc and monthly cost per mbps: cpm 
CR_MDT_NH <- CR_MDT_NH %>% mutate(cpc = round(total_monthly_cost / num_int_lines, digits=2), 
                                  cpm = round(total_monthly_cost / total_bw_mbps, digits=2)) %>% arrange(cpm)
View(CR_MDT_NH)

##SELECT SPECIFIC COLUMNS TO LOOK AT FOR LEADERS/LAGGARDS
View(select(CR_MDT_NH, name, ULOCAL, num_students, internet_sp, all_ia_connectcat, total_bw_mbps, num_int_lines, ia_bandwidth_per_student, condition, cpc, cpm))

#What proportion of districts are meeting $3/Mbps goal? (recall, for all_ia_connect_cat)
nrow(CR_MDT_NH[CR_MDT_NH$cpm <= 3,]) / nrow(CR_MDT_NH) #18% About 1 out of every 5 districts in our sample meets the $3/Mbps goal.

laggards <- CR_MDT_NH[53:66,] #bottom 20%
min(laggards$cpm) #$18.65
View(laggards)
View(laggards  %>% filter(totally_verified==TRUE)) # Barrington SD is the only totally verified SD in CR_MDT_NH
write.csv(laggards, "laggards_districts.csv")

#What is the national median cost per Mbps? DOUBLE CHECK THE VALUES BELOW
#(In 2013: $22, In 2014: $11 Median monthly cost per Mbps)
#Source: 2015 SotS Report p. 18

#So now, we compare cpm at the 2014 Median monthly cost per Mbps
nrow(CR_MDT_NH[CR_MDT_NH$cpm <= 11,]) / nrow(CR_MDT_NH) #56% More than half of NH districts in our sample are doing better than the 2014 National Median


#Get list of ULOCAL with the following filter condition: Lit Fiber
CR_MDT_NH %>% group_by(ULOCAL) %>% filter(all_ia_connecttype == '{"Lit Fiber Service"}') %>% summarise(ulocal = n())
CR_MDT_NH %>% group_by(ULOCAL) %>% filter(all_ia_connecttype == '{"Cable Modem"}') %>% summarise(ulocal = n())
#Look into these for comparison examples:
#Some things to look out for: Same internet access type
View(CR_MDT_NH %>% filter(ULOCAL == 21)) #Sanborn Regional vs. Raymond SD
View(CR_MDT_NH %>% filter(ULOCAL == 23))
View(CR_MDT_NH %>% filter(ULOCAL == 41))
View(CR_MDT_NH %>% filter(ULOCAL == 42))
View(CR_MDT_NH %>% filter(ULOCAL == 43))

### District comparison based on totally_verified ###
tv_dists <- CR_MDT_NH  %>% filter(totally_verified == "TRUE")
nrow(tv_dists)
list(tv_dists$ULOCAL)

##Adding condition for Leaders and Laggards and mapping 
#Leaders pay less than $10/month. Laggards pay more than 

LL_condition <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("Leader (< $3/Mbps)", "Laggard (>= $19/Mpbs)", "Other"))
LL_condition[CR_MDT_NH$cpm < 3] <- "Leader (< $3/Mbps)"
LL_condition[CR_MDT_NH$cpm >= 3 & CR_MDT_NH$cpm < 18.65] <- "Other"
LL_condition[CR_MDT_NH$cpm >= 18.65] <- "Laggard (>= $19/Mpbs)"
CR_MDT_NH$LL_condition <- LL_condition
#View(CR_MDT_NH)

##12/08: Change connectivity goal condition to Meeting 2014 Goals, Not Meeting 2014 Goals
condition2 <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("Below 2014", "Meets 2014"))
condition2[CR_MDT_NH$ia_bandwidth_per_student < 100] <- "Below 2014"
condition2[CR_MDT_NH$ia_bandwidth_per_student >= 100] <- "Meets 2014"
CR_MDT_NH$condition2 <- condition2
View(CR_MDT_NH)

#View(CR_MDT_NH)
#Map of Leaders/Laggards and Meeting Goals
#We're generally interested in the Laggards
#But we should also be interested in the Laggards who are not meeting 2014 goals

#Most leaders are meeting 2014 goals 
nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude,
                                           colour=LL_condition, shape = condition2), size = 11, alpha=0.7, position = position_jitter(w = 0.078, h = 0.078)) + 
  scale_color_manual(values=c("dodgerblue", "salmon1", "#CCCCCC")) 

#Based on checking lat/long map on google, south NH is approx. <= 43N Lat.
south_NH <- CR_MDT_NH %>% filter(latitude < 44)
#View(south_NH)
south_NH_laggards <- CR_MDT_NH %>% filter(latitude < 44 & LL_condition == "Laggard", condition == "Below 2014")
#View(south_NH_laggards)


#I want to know the min and max cpm values in each ULOCAL as I try to find comparisons
CR_MDT_NH %>% group_by(ULOCAL) %>% summarise(min = min(cpm), max = max(cpm), n = n()) %>% filter(n > 1)
##NEED TO CONTINUE HERE.


###12/15: updated Leaders/Laggards Analysis
#ULOCAL: 23 
#Newmarket SD & Winnacunnet Coop SD
LL23 <- CR_MDT_NH %>% filter(name == "NEWMARKET SCHOOL DISTRICT" | name == "WINNACUNNET COOP SCHOOL DISTRICT")
View(LL23)

### Ideally, we want to get the map down to the SE region and zoom in there
nh_base + geom_point(data = LL23, aes(x = longitude, y = latitude,
                                      colour=name), size = 11, alpha=0.7)



LL41 <- CR_MDT_NH %>% filter(name == "EXETER REGION COOP SCHOOL DISTRICT" | name == "MASON SCHOOL DISTRICT")
View(LL41)



### 12/08: REVISION SECTION: Based on Dan's Feedback

## We want to map all non-erate districts. 
## We do this by subsetting all districts in the DT_population data set that's in the NH_NDR_C1 data set.
#match up column name of NH_DNR_C1 with DT_population's 
colnames(NH_DNR_C1)[2] <- "name"
#View(NH_DNR_C1) #checked
non_erate_districts <- semi_join(DT_population, NH_DNR_C1, by = c("name"))
View(non_erate_districts)

##Map all non-erate districts 
nh_base + geom_point(data = non_erate_districts, aes(x = longitude, y = latitude), colour = "steelblue", size = 11, alpha=0.7, position = position_jitter(w = 0.095, h = 0.095))


##Append new column categorizing Fiber, Non-Fiber, then map of Fiber / Non-Fiber
CR_MDT_NH$connect_cat2 <- ifelse(CR_MDT_NH$hierarchy_connect_category == "Fiber", "Fiber", "Non-Fiber")

nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude,
                                           colour=connect_cat2), size = 11, alpha=0.7, position = position_jitter(w = 0.09, h = 0.09))

## Make new map just mapping connectivity goals
nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude,
                                           colour=condition), size = 11, alpha=0.65, position = position_jitter(w = 0.085, h = 0.09))


## Finding new district call outs ##
dist_by_ulocal <- CR_MDT_NH  %>% select(ULOCAL, name, locale, num_students, district_size, ia_bandwidth_per_student, totally_verified, hierarchy_connect_category:connect_cat2) %>% arrange(ULOCAL)
View(dist_by_ulocal)
ulocal23 <- CR_MDT_NH %>% filter(ULOCAL == 23)
write.csv(ulocal23, "ulocal23_districts.csv") #Exporting csv for brad
ulocal41_fib <- CR_MDT_NH %>% filter(ULOCAL == 41 & hierarchy_connect_category=="Fiber")
View(ulocal41_fib)
write.csv(ulocal41_fib, "ulocal41_fib_districts.csv")
View(dist_by_ulocal %>% filter(ULOCAL == 43))


###Additional Maps
nh_base + geom_point(data = loc_ct_sp, aes(x = longitude, y = latitude,
                                           colour=reporting_name), size = 11, alpha=0.7, position = position_jitter(w = 0.08, h = 0.08))

nh_base + geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude,
                                           colour=condition2), size = 11, alpha=0.65, position = position_jitter(w = 0.085, h = 0.09)) + 
  scale_color_manual(values=c("#FF3300", "#CCCCCC")) 


## CONTINUE HERE 12/14 Afternoon: MAPPING COUNTIES OF NH
states <- map_data("state")
nh_df <- subset(states, region == "new hampshire")
counties <- map_data("county")
nh_county <- subset(counties, region == "new hampshire")

nh_base_county <- ggplot(nh_df, nh_county) +
  geom_polygon(color = "black", fill = "white")

nh_base_county

##Average Internet cost is more expensive than other states (include ME, MA, and avg cost from A-B from above slide, $3 dotted line target)
## Neighboring States Analysis ##
#Massachusetts clean line items
LI_MA_clean <- read.csv("~/Desktop/ESH/CR_NH/LI_MA_clean.csv")
nrow(LI_MA_clean) #541 lines items
MA_int_lines <- LI_MA_clean %>% filter(internet_conditions_met == TRUE)
nrow(MA_int_lines) #436 IA line items
sum(MA_int_lines$num_lines) #477 IA circuits

MA_int_lines$total_cost <- as.numeric(gsub(",","",MA_int_lines$total_cost))
MA_int_lines$num_lines <- as.numeric(gsub(",","",MA_int_lines$num_lines))
MA_int_lines<- transform(MA_int_lines, cpl_m = round((total_cost / num_lines)/12, digits=0)) #cost per line now in new column
#View(MA_int_lines)
MA_lit_fiber <- MA_int_lines %>% filter(connect_type == "Lit Fiber Service")
nrow(MA_lit_fiber) #250
sum(MA_lit_fiber$num_lines)#280 total lit fiber IA circuits
MA_lit_fiber100 <- MA_int_lines %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps >= 100 & bandwidth_in_mbps <= 199)
nrow(MA_lit_fiber100) #75 line items for lit fiber IA circuits within 100-199 Mbps range
sum(MA_lit_fiber100$num_lines) #80 lit fiber IA circuits within 100-199 Mbps range
#MASSACHUSETTS: The average cost per lit fiber circuit at 100-199 Mbps range
mean(MA_lit_fiber100$cpl_m) #1467.84
median(MA_lit_fiber100$cpl_m)#1500

#MASSACHUSETTS: COST PER MBPS
MA_int_lines$total_cost <- gsub(",", "", MA_int_lines$total_cost)
MA_int_lines$bandwidth_in_mbps <- gsub(",", "", MA_int_lines$bandwidth_in_mbps)
#appending new columns for monthly cost per mbps: cpm 
MA_LL <- MA_int_lines %>% mutate(cpm = ((as.numeric(as.character(total_cost)) / (as.numeric(as.character(bandwidth_in_mbps))*as.numeric(as.character(num_lines))))/12)) %>% arrange(cpm)
#View(MA_LL)
#Overall Mean and Median (not conditioning for connect type)
MA_LL %>% summarise(n = n(), mean = mean(cpm), median = median(cpm)) #Mean: 17.49452 Median: 6.666667
#MASSACHUSETTS: Mean and Median Cost per Mbps by Connect Type
MA_LL %>% group_by(connect_type) %>% summarise(n = n(), mean = mean(cpm), median = median(cpm), num_lines = sum(num_lines))


## Appending monthly cost per circuit to both ME and VT ##
#MAINE: Monthly cost per circuit by connection type 
LI_ME_VT_clean2 <- read.csv("~/Desktop/ESH/CR_NH/LI_ME_VT_clean2.csv") #THIS DATA SET IS JUST FOR ME CALCULATIONS WHILE IT STILL CONTAINS VT LIs. 
#Used a different data pull for ME because original LI query would filter appropriately for VT but not for ME, which is a special case
#Maine clean line items
LI_ME_clean <- LI_ME_VT_clean2 %>% filter(postal_cd == "ME")
#View(LI_ME_clean)
nrow(LI_ME_clean) #n = 99

#Maine: Filtering for IA lines only
ME_int_lines <- LI_ME_clean %>% filter(internet_conditions_met==TRUE) 
nrow(ME_int_lines) #n = 18
#View(ME_int_lines)
sum(ME_int_lines$num_lines) #ME Internet circuits = 19

ME_int_lines$total_cost <- as.numeric(gsub(",","",ME_int_lines$total_cost))
ME_int_lines$num_lines <- as.numeric(gsub(",","",ME_int_lines$num_lines))
ME_int_lines<- transform(ME_int_lines, cpl_m = round((total_cost / num_lines)/12, digits=0)) #cost per line now in new column
#View(ME_int_lines)
ME_lit_fiber <- ME_int_lines %>% filter(connect_type == "Lit Fiber Service")
nrow(ME_lit_fiber) #8
sum(ME_lit_fiber$num_lines)#8 total lit fiber IA circuits
ME_lit_fiber100 <- ME_int_lines %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 100)
nrow(ME_lit_fiber100) #4
sum(ME_lit_fiber100$num_lines) #4
#MAINE: The average cost per lit fiber circuit at 100-199 Mbps range
mean(ME_lit_fiber100$cpl_m) #1194
median(ME_lit_fiber100$cpl_m)#1363

#MAINE: Monthly Cost Per Mbps 
ME_int_lines$total_cost <- gsub(",", "", ME_int_lines$total_cost)
ME_int_lines$bandwidth_in_mbps <- gsub(",", "", ME_int_lines$bandwidth_in_mbps)
#appending new columns for monthly cost per mbps: cpm 
ME_LL <- ME_int_lines %>% mutate(cpm = ((as.numeric(as.character(total_cost)) / (as.numeric(as.character(bandwidth_in_mbps))*as.numeric(as.character(num_lines))))/12)) %>% arrange(cpm)
#View(ME_LL)
#Overall Mean and Median (not conditioning for connect type)
ME_LL %>% summarise(mean = mean(cpm), median = median(cpm)) #Mean: 27.64651 Median: 11.53712
summary(ME_LL$cpm) #top 25th: $7.22/Mbps
#MAINE: Mean and Median by Connect Type
ME_LL %>% group_by(connect_type) %>% summarise(n = n(), mean = mean(cpm), median = median(cpm), num_lines = sum(num_lines))


## WAN ANALYSIS FOR MAINE ##
ME_wan <- LI_ME_clean %>% filter(wan_conditions_met == TRUE)
ME_wan$open_flags[] <- lapply(ME_wan$open_flags, as.character)
ME_wan2 <- ME_wan %>% filter(!grepl("upstream_circuit", open_flags))
ME_wan3 <- ME_wan2 %>% filter(!grepl("exclude", open_flags))
nrow(ME_wan) #n=52
nrow(ME_wan2) #n=49
View(ME_wan2)


#MAINE: Monthly Cost Per Circuit
ME_wan2 <- transform(ME_wan2, cpl_m = round((as.numeric(as.character(total_cost)) / as.numeric(as.character(num_lines)))/12, digits=0)) #cost per line now in new column
ME_wan2_lit_fiber100 <- ME_wan2 %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 100)
nrow(ME_wan2_lit_fiber100) #n = 7
sum(ME_wan2_lit_fiber100$num_lines) #n = 392
View(ME_wan2_lit_fiber100)
mean(ME_wan2_lit_fiber100$cpl_m) #mean = 715.43
median(ME_wan2_lit_fiber100$cpl_m) #median = $823



#MAINE: Monthly Cost Per Mbps 
ME_wan2$total_cost <- gsub(",", "", ME_wan2$total_cost)
ME_wan2$bandwidth_in_mbps <- gsub(",", "", ME_wan2$bandwidth_in_mbps)
#appending new columns for monthly cost per mbps: cpm 
ME_wan_LL <- ME_wan2 %>% mutate(cpm = ((as.numeric(as.character(total_cost)) / (as.numeric(as.character(bandwidth_in_mbps))*as.numeric(as.character(num_lines))))/12)) %>% arrange(cpm)
View(ME_wan_LL)
ME_wan_LL$cpm <- round(ME_wan_LL$cpm, digits = 2)
median(ME_wan_LL$cpm) #About 11 line items have total_cost $0.00 which pulls down the median
#ME Monthly Cost Per Mbps Median: $2.36, but how do we handle the fact that about 1/5 LI have total_cost $0.00?


## WAN ANALYSIS FOR MASSACHUSETTS ##
#Massachusetts clean line items
LI_MA_clean <- read.csv("~/Desktop/ESH/CR_NH/LI_MA_clean.csv")
#MA: Monthly Cost Per Circuit
MA_wan <- LI_MA_clean %>% filter(wan_conditions_met == TRUE)
MA_wan$open_flags[] <- lapply(MA_wan$open_flags, as.character)
MA_wan2 <- MA_wan %>% filter(!grepl("upstream_circuit", open_flags))
MA_wan3 <- MA_wan2 %>% filter(!grepl("exclude", open_flags))
nrow(MA_wan) #n=105
nrow(MA_wan2) #n=105, also n = 105 for MA_wan3, since n doesn't change, we'll just use MA_wan
View(MA_wan)


#MA: Monthly Cost Per Mbps 
MA_wan <- transform(MA_wan, cpl_m = round((as.numeric(as.character(total_cost)) / as.numeric(as.character(num_lines)))/12, digits=0)) #cost per line now in new column
MA_wan_lit_fiber100 <- MA_wan %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 100)
nrow(MA_wan_lit_fiber100) #n = 25
sum(MA_wan_lit_fiber100$num_lines) #n = 172
View(MA_wan_lit_fiber100)
mean(MA_wan_lit_fiber100$cpl_m) #mean = $1443.72
median(MA_wan_lit_fiber100$cpl_m) #median = $1517














##EXTRA STATE COMPARISON (NOT USED IN DECK)
#Vermont clean line items
LI_ME_VT_clean <- read.csv("~/Desktop/ESH/CR_NH/LI_ME_VT_clean.csv")
LI_VT_clean <- LI_ME_VT_clean %>% filter(postal_cd == "VT")
View(LI_VT_clean)
nrow(LI_VT_clean) #n=237

VT_int_lines <- LI_VT_clean %>% filter(internet_conditions_met == TRUE)
nrow(VT_int_lines) #146

#VERMONT: 
VT_int_lines$total_cost <- as.numeric(gsub(",","",VT_int_lines$total_cost))
VT_int_lines$num_lines <- as.numeric(gsub(",","",VT_int_lines$num_lines))
VT_int_lines<- transform(VT_int_lines, cpl_m = round((total_cost / num_lines)/12, digits=0)) #cost per line now in new column
#View(VT_int_lines)
nrow(VT_int_lines) #146
sum(VT_int_lines$num_lines) #VT Internet circuits = 154
VT_lit_fiber <- VT_int_lines %>% filter(connect_type == "Lit Fiber Service")
View(VT_lit_fiber)
sum(VT_lit_fiber$num_lines) #56
VT_lit_fiber100 <- VT_int_lines %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 100 | bandwidth_in_mbps == 150)
nrow(VT_lit_fiber100)#12
#VERMONT: The average cost per lit fiber circuit at 100-199 Mbps range
mean(VT_lit_fiber100$cpl_m) #1768.5
median(VT_lit_fiber100$cpl_m) #1948



## Comparing Averages of SAU vs. Non-SAU Procurement Costs ##
sau_comparison <- SR_NH_revised %>% 
  filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps >= 100 & bandwidth_in_mbps <= 199) %>% 
  mutate(cpl_m = round((line_item_total_cost / line_item_total_num_lines)/12, digits=0))

nrow(sau_comparison) #17
summary(sau_comparison$sau)

sau_stats <- sau_comparison %>% filter(sau == "SAU" | sau == "One-District SAU") %>% summarise(mean = mean(cpl_m), median = median(cpl_m))
sau_stats #mean Lit Fiber circuit cost @ 100-199 bw procured by SAU
#     mean   median
# 1380.333   1439.5

non_sau_stats <- sau_comparison %>% filter(sau == "Non-SAU") %>% summarise(mean = mean(cpl_m), median = median(cpl_m))
non_sau_stats
#     mean   median
# 2207.455   2027


##12/14: CONTINUE TO FIX THIS ON TUESDAY: Percentage breakdown for group C in the foot note: what % is a district, what % is a single-district SAU
procure_district <- SR_NH_revised %>% filter(sau == "SAU")
procure_single_dist_SAU <- SR_NH_revised %>% filter(sau == "One-District SAU")

# District Directly
nrow(procure_district) #27 services received
unique(procure_district$name) #20 unique names of recipients
length(as.vector(unique(procure_district$name)))

#One - District SAUs
nrow(procure_single_dist_SAU) #17 services received
unique(procure_single_dist_SAU$name) #12 unique names of recipients
length(as.vector(unique(procure_single_dist_SAU$name)))

#20 + 12 = 32 total unique recipients (districts) that are either procuring directly or as single-district SAUs
# but recall there are 66 total unique districts
20/66
12/66

### Slide: XX% of districts/campuses not meeting the goal are lacking fiber
##Basic Connection Type Analysis##
con_table <- table(CR_MDT_NH$condition2, CR_MDT_NH$hierarchy_connect_category)
#             Cable  Copper  DSL  Fiber
#Below 2014     2       2     2    16
#Meets 2014    14       0     1    29
dim(con_table)

###12/14: FUNCTION TO FIND PERCENTAGE VALUES OF CONNECTION TYPES MEETING GOALS
con_type_mg <- function(data, row, col){
  keep <- list()
  for(i in 1:col){
    iter <- c()
    for(j in 1:row){
      val <- data[j,i] / sum(data[1:max(row),i]) 
      iter <- c(iter, val)   
    }
    keep <- list(keep, iter)
  }  
  print(keep)
}

con_type_mg(con_table, 2, 4)

############### Replicating the same ^ manually (to cross-check)
## Calculating percentages within connection type: 
## RECALL:
## Row 1: Below 2014
## Row 2: Meets 2014

##Fiber
sum(con_table[1,4])/sum(con_table[1:2,4]) #36%
sum(con_table[2,4])/sum(con_table[1:2,4]) #64%

##Cable
sum(con_table[1,1])/sum(con_table[1:2,1]) #12%
sum(con_table[2,1])/sum(con_table[1:2,1]) #88%

##Other = DSL + Copper
sum(con_table[1,2:3])/sum(con_table[1:2,2:3]) #80%
sum(con_table[2,2:3])/sum(con_table[1:2,2:3]) #20%

### Slide: 27% of districts/campuses not meeting the goal are lacking fiber
### Calculating percentages ACROSS meeting goals
across_mg <- function(data, row, col){
  
  keep2 <- list()
  
  for(j in 1:row){
    keep <- c()
    
    for(i in 1:col){
      val <- data[j,i] / sum(data[j,1:col]) 
      keep <- c(keep, val)
    }
    keep2 <- list(keep2, keep)
  }
  print(keep2)
}


across_mg(con_table, 2, 4)
#                     Cable   Copper         DSL     Fiber
#[1: Below 2014] 0.09090909 0.09090909 0.09090909 0.72727273
#[2: Meets 2014] 0.31818182 0.00000000 0.02272727 0.65909091
#NOTE: GROUP COPPER AND DSL TO GET "OTHER" CATEGORY


summary(CR_MDT_NH$hierarchy_connect_category)
#By count:
# Cable Copper    DSL  Fiber 
#   16      2      3     45 

round(((summary(CR_MDT_NH$hierarchy_connect_category)/nrow(CR_MDT_NH))*100), digits = 0)
#In percentages:
#Cable Copper    DSL  Fiber 
#  24      3      5     68 


### SLIDE: 67% of school districts are in rural areas
nrow(DT_population)
summary(DT_population$locale) 
t2 <- table(DT_population$locale, DT_population$district_size)
nrow(DT_population  %>% filter(locale=="Rural")) / nrow(DT_population) #67% of districts are in rural areas

#number of districts per locale
t3 <- rowSums(t2)
#distribution of districts in percentage
round((t3/nrow(DT_population))*100, 0) 


### Non-Scalable Breakdown:








### 01/05: Analysis cont'd based on Evan's Feedback.
### 1.Exploration of why districts are NOT meeting goals
b_goals <- CR_MDT_NH %>% filter(condition == "Below 2014")
nrow(b_goals) # n = 22
View(b_goals)

#Map to see if there are any geographic trends...but didn't find anything compelling.
nh_base + geom_point(data = b_goals, aes(x = longitude, y = latitude), size = 11, alpha=0.7, position = position_jitter(w = 0.08, h = 0.08))

#Summary stats of this subset:
summary(b_goals$num_students) #wide variability of num_students; not compelling
summary(b_goals$school_size)

summary(b_goals$locale) #not compelling
summary(b_goals$hierarchy_connect_category) #overwhelming number of fiber districts are not meeting goals; subset by num_students. 
summary(b_goals$num_campuses) #not compelling
summary(b_goals$frl_percent) #I don't think FRL plays a significant role in NH.
#Min.     Median     Mean       Max. 
#0.04715  0.18090   0.24640   0.60760 

summary(CR_MDT_NH$hierarchy_connect_category) #use this to compare proportionally with subset below goals.

##For Fiber
View(b_goals  %>% filter(hierarchy_connect_category == "Fiber"))
b_goals_fiber <- b_goals  %>% filter(hierarchy_connect_category == "Fiber")
summary(b_goals_fiber$num_students)

m_goals <- CR_MDT_NH %>% filter(condition == "Meets 2014" | condition == "Meets 2018")
m_goals_fiber <- m_goals %>% filter(hierarchy_connect_category == "Fiber")
nrow(b_goals_fiber) #n=16
nrow(m_goals_fiber) #n=29

##For Cable
b_goals_cable <- b_goals  %>% filter(hierarchy_connect_category == "Cable")
m_goals_cable <- m_goals %>% filter(hierarchy_connect_category == "Cable")
nrow(b_goals_cable) #n=2
nrow(m_goals_cable) #n=12
mean(b_goals_cable$cpm)
mean(m_goals_cable$cpm)




##comparing districts meeting goals vs. below goals for cost per Mbps
summary(b_goals_fiber$cpm) 
summary(m_goals_fiber$cpm) 
round(quantile(b_goals_fiber$cpm, c(.10, .25, .50, 0.75, 0.90)), digits = 2)
round(quantile(m_goals_fiber$cpm, c(.10, .25, .50, 0.75, 0.90)), digits = 2)
#below goals and meeting goals districts are paying about the same median cost for fiber at cost/Mbps. 
#this means that below goals districts are paying more at the cost/Mbps level than meeting goals districts.


##comparing districts meeting goals vs. below goals for cost per circuit
summary(m_goals_fiber$cpc)
summary(b_goals_fiber$cpc) 

#One possible barrier: schools are too big, without sufficient bandwidth
#b_goals2 df is a subset of b_goals, looking at districts with >= 3 campuses and on fiber.
b_goals2 <- as.data.frame(b_goals %>% filter(hierarchy_connect_category == "Fiber" & band_campuses == "Three or More Campuses") )
View(b_goals2)
#Subsetted b_goals2 vertically, to look at only a select # of columns. 
View(select(b_goals2, esh_id, name, locale, num_students, num_schools, num_campuses, district_size, wan_status, num_int_lines) %>% arrange(desc(num_int_lines)))

##large fiber districts that are on fiber (with insufficient WAN and/or Int lines)
nh_base + geom_point(data = b_goals2, aes(x = longitude, y = latitude), size = 11, alpha=0.7, position = position_jitter(w = 0.08, h = 0.08))


# For Num Campuses vs. Num Students Stats Slide:
sum(CR_MDT_NH$num_campuses)
sum(CR_MDT_NH$num_schools)

one_c <- CR_MDT_NH %>% group_by(band_campuses) %>% summarise(n_school = sum(num_schools), n_student = sum(num_students), n_district = n())
round((one_c$n_school/sum(CR_MDT_NH$num_schools))*100, digits = 0)
#One    Two   Three+
#21%    17%    62%


##I think it's important to know the breakdown of connection types
summary(CR_MDT_NH$hierarchy_connect_category)
round((summary(CR_MDT_NH$hierarchy_connect_category) / nrow(CR_MDT_NH))*100, digits = 0)
#Cable   Copper    DSL   Fiber 
#24%      3%       5%     68% 

testing <- table(CR_MDT_NH$hierarchy_connect_category, CR_MDT_NH$condition2)



##Additional SP analysis
#csc is a subset that I created awhile back that contains clean line items and only internet_conditions_met == TRUE lines
#sp_category is the data set that contains all of the category and reporting_name info which corresponds to service_provider_name in the csc dataset
csc$category <- sp_category[match(csc$service_provider_name, sp_category$name),"category"] 
csc$reporting_name <- sp_category[match(csc$service_provider_name, sp_category$name),"reporting_name"] 
View(csc)

csc %>% group_by(bandwidth_in_mbps) %>% filter(connect_type == "Lit Fiber Service") %>% summarise(n = n()) %>% filter(n >5)
#we have 10 line items that have lit fiber service at 100 mbps 

lfs_100 <- csc %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 100) %>% arrange(cpl_m)
View(lfs_100)
summary(lfs_100$cpl_m)



lfs_150 <- csc %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 150) %>% arrange(cpl_m)
View(lfs_150)
summary(lfs_150$cpl_m)


lfs_200 <- csc %>% filter(connect_type == "Lit Fiber Service" & bandwidth_in_mbps == 200) %>% arrange(cpl_m)
View(lfs_200)
summary(lfs_150$cpl_m)


##Check SP $ share for IA and WAN using both clean and dirty line items for comprehensive $ market share. At the circuit level
CR_LI_NH_all <- read.csv("~/Desktop/ESH/CR_NH/CR_LI_NH_all.csv")
View(CR_LI_NH_all)

LI_NH_all <- CR_LI_NH_all[,1:56] #only want to keep columns with info
LI_NH_all$total_cost <- as.numeric(as.character(gsub(",","", LI_NH_all$total_cost)))


View(LI_NH_all)
LI_NH_all$category <- sp_category[match(LI_NH_all$service_provider_name, sp_category$name),"category"] 
LI_NH_all$reporting_name <- sp_category[match(LI_NH_all$service_provider_name, sp_category$name),"reporting_name"] 
View(LI_NH_all)

sp_marketshare <- LI_NH_all %>% group_by(reporting_name) %>% summarise(total = sum(total_cost)) %>% arrange(desc(total)) %>% mutate(percentage_share = round((total / sum(total))*100, digits = 2))
View(sp_marketshare)



### Using Services Received Table to find % of Districts SPs are providing services for
SR_NH <- read.csv("~/Desktop/ESH/CR_NH/SR_NH.csv")
SR_NH_SP <- SR_NH %>% filter(exclude == FALSE & name != "CONTOOCOOK VALLEY SCHOOL DISTRICT")
View(SR_NH_SP)





### For Campus and School Count Comparisons
table(CR_MDT_NH$num_schools)
table(CR_MDT_NH$num_campuses)

table(CR_MDT_NH$num_schools, CR_MDT_NH$num_campuses)

#Table of breakdown based on num_campuses
CR_MDT_NH %>% group_by(num_campuses) %>% summarise(n = n(), schools = sum(num_schools)) %>% mutate(ave_num_schools = round(schools/n, digits = 2))

#Table of breakdown based on num_school
CR_MDT_NH %>% group_by(num_schools) %>% summarise(n = n(), campuses = sum(num_campuses)) %>% mutate(ave_num_campus = round(campuses/n, digits = 2))




#### FIBER TO CAMPUS ANALYSIS:
fiber2campus <- read.csv("~/Desktop/ESH/CR_NH/fiber2campus.csv")
fiber2campus <- fiber2campus %>% filter(district_name != "CONTOOCOOK VALLEY SCHOOL DISTRICT")
nrow(fiber2campus) #173
sum(CR_MDT_NH$num_campuses) #174 
###fiber2campus data and CR_MDT_NH data is off by 1 campus
summary(fiber2campus$known_fiber_or_fiber_equivalent)
#No Unknown     Yes 
#38      67      68 

##Fiber, non-Fiber percentage breakdown
round((summary(fiber2campus$known_fiber_or_fiber_equivalent)/nrow(fiber2campus))*100, digits = 0)



### Leaders and Laggards Analysis Updated: We are looking for verfied from the clean_categorization column ##
summary(CR_MDT_NH$clean_categorization)
#assumed    inferred interpreted    verified 
#14          30           2          20 

summary(CR_MDT_NH$totally_verified)
#Mode        FALSE    TRUE    NA's 
#logical      59       7       0 

#Subset of Verified Districts
ver_dists<- CR_MDT_NH %>% filter(clean_categorization == "verified")
View(ver_dists)

#Subset of Verified Districts: Fiber
fib_ver_dists <- ver_dists %>% filter(hierarchy_connect_category == "Fiber")
nrow(fib_ver_dists) #13
View(fib_ver_dists)

#Export csv for more convenient view/manipulation
write.csv(fib_ver_dists, "fib_ver_dists.csv")

#Subset of Verified Districts: Cable
cab_ver_dists <- ver_dists %>% filter(hierarchy_connect_category == "Cable")
nrow(cab_ver_dists) #7
