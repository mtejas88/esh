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
#    67         219      95783

summary(DT_NH_clean$consortium_member) #41 districts are not, 26 districts are (consortium at district level)


##### GOALS & FIBER SECTIONS #####

### Function: Calculating Percentages ###
calc_percent <- function(sub, total, digs){
  frac <- round((nrow(sub)/nrow(total))*100, digits=digs)
  print(frac)
}

### Highest Connection Type (n=67) ###
summary(DT_NH_clean$highest_connect_type)
#Fiber: 46    Cable/DSL: 19    Copper: 2
round((46/nrow(DT_NH_clean$districts))*100, digits=0) #Fiber: 69%         #need to make code more generalizable!
round((19/67)*100, digits=0) #Cable/DSL: 28%

## ^ Translate this to dplyr or purely function format ##
#x <- DT_NH_clean %>% group_by(highest_connect_type) %>% 
#            summarise(count = sum(as.numeric(as.character(num_schools)))) %>%
#            mutate(percentage = highest_connect_type/nrow(highest_connect_type)) ##FIGURE THIS PART OUT; CREATING NEW COLUMN OF PERCENTAGES BY CONNECT TYPE


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
not_mg <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 0, 100)
View(not_mg)

## Districts Meeting 2014 Goals ##
mg_2014 <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 100, 1000)
View(mg_2014)

## Districts Meeting 2018 Goals ##
mg_2018 <- meeting_goals(DT_NH_clean, ia_bandwidth_per_student, 1000, 2000)
View(mg_2018)

## Percentage of Not Meeting Goals ##
calc_percent(not_mg, DT_NH_clean, 2)

## Percentage of Meeting 2014 Goals ##
calc_percent(mg_2014, DT_NH_clean, 2)

## Percentage of Meeting 2018 Goals ##
calc_percent(mg_2018, DT_NH_clean, 2)

### Among Districts Below 2014 Goals, Which Are < 50 Kbps ? ###
bw.low.50 <- DT_NH_clean %>% filter(ia_bandwidth_per_student < 50) 
nrow(bw.low.50) #13 districts
round((13/23)*100, digits=0) #About 57% range between 0-49 kbps 
summary(bw.low.almost$highest_connect_type) #seven of these are on fiber; 3 are on Cable/DSL


### Meeting 2014 Goals Based on Connection Type ###
# Not meeting 2014 Goals (n=23) #
summary(bw.low$highest_connect_type)
#Fiber: 17    Cable/DSL: 4    Copper: 2
bw.low.f <- bw.low %>% filter(highest_connect_type=="Fiber")
bbw.low.cd <- bw.low %>% filter(highest_connect_type=="Cable/DSL")
bw.low.c <- bw.low %>% filter(highest_connect_type=="Copper")

# Meeting 2014 Goals (n=41) #
summary(bw2014$highest_connect_type)
#Fiber: 29    Cable/DSL: 12    Copper: 0
bw2014.f <- bw2014 %>% filter(highest_connect_type=="Fiber")
bw2014.cd <- bw2014 %>% filter(highest_connect_type=="Cable/DSL")
bw2014.c <- bw2014 %>% filter(highest_connect_type=="Copper")


# Meeting 2018 Goals (n=3) #
summary(bw2018$highest_connect_type)
#Fiber: 0    Cable/DSL: 3    Copper: 0
#Found that these are all tiny, rural districts (<100 students)


### How Districts Meet Goals based on FRL ### NOTE: SWITCHED DATA SETS HERE TO EXPANDED VERSION
CR_MDT_NH <- read.csv("~/Desktop/ESH/CR_NH/CR_Master_Districts_Table_NH.csv") #need to use Master DT. 
CR_MDT_NH <- CR_MDT_NH[-16,] #Removed Contoocook


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

### Average Bandwidth of Districts That Meet 2014 Goals ###
summary(bw2014$ia_bandwidth_per_student) #Mean: 288.3


### Deeper Look at Districts Not Meeting 2014 Goals ###
summary(bw.low$locale) #Most are in Rural and Suburban; one in Urban. 
#Large Urban School with 41% FRL, not the highest FRL in this group but higher than average.
summary(bw.low$district_size) #Most are in Small size.

## Summary Breakdown of Highest Connection Type in the Not Meeting 2014 Goals Category ##
summary(bw.low$highest_connect_type)


## Number of districs >= 100 students and < 100 students ##
###NOTE: removed Contoocook (num_students > 100)
gt.100.num.stu <- CR_MDT_NH %>% filter(num_students >= 100) 
nrow(gt.100.num.stu) #58 schools
round((58/66)*100, digits=0) #88%

lt.100.num.stu <- CR_MDT_NH %>% filter(num_students < 100) 
nrow(lt.100.num.stu) #8 schools
round((8/66)*100, digits=0) #12%


##### AFFORDABILITY SECTION #####
#Use the LI_NH_clean dataset
LI_NH_clean <- read.csv("~/Desktop/ESH/CR_NH/LI_NH_clean.csv")

### Clean imported csv file ###
LI_NH_clean <- LI_NH_clean[,-1]
LI_NH_clean <- sapply(LI_NH_clean, as.character)
colnames(LI_NH_clean) <- LI_NH_clean[1, ]
LI_NH_clean <- as.data.frame(LI_NH_clean[-1,])
LI_NH_clean <- LI_NH_clean[,1:56] #only want to keep columns with info
View(LI_NH_clean)

### Circuit Size Cost ###
csc <- LI_NH_clean %>% filter(internet_conditions_met == TRUE) 
nrow(csc) #Filtered out for internet_conditions_met. This reduces dataset to n=124.
summary(csc$connect_type) #8 categories

rural3 <- csc %>% filter(applicant_locale == "Rural")
nrow(rural3) #58

## Local == RURAL and Percentile values for CONNECT_TYPE == Lit Fiber Service @ 100 Mbps ##
rural2 <- rural3 %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service") 
rural100 <- rural2 %>% filter(bandwidth_in_mbps==100)
nrow(rural100) #n=3
quantile(rural100$cpl_m, c(.10, .25, .50, 0.75, 0.90)) #percentile values for Lit Fiber Service at 100 MBPS
#View(lfs100)

rural.cdsl <- rural3 %>% filter(connect_category == "Cable / DSL")
nrow(rural.cdsl) #n=32
rural3$bandwidth_in_mpbs <- as.numeric(gsub(",","",rural3$bandwidth_in_mbps))
x <- density(as.numeric(rural3$bandwidth_in_mbps))
plot(x)

## Monthly cost per mbps per circuit by connection type ##
csc$total_cost <- as.numeric(gsub(",","",csc$total_cost))
csc$num_lines <- as.numeric(gsub(",","",csc$num_lines))
csc <- transform(csc, cpl_m = round((total_cost / num_lines)/12, digits=2)) #cost per line now in new column
#View(csc)

## Percentile values for CONNECT_TYPE == Cable Modem @ 100 Mbps ##
cm <- csc %>% filter(connect_type == "Cable Modem") 
cm100 <- cm %>% filter(bandwidth_in_mbps==100)
quantile(cm100$cpl_m, c(.10, .25, .50, 0.75, 0.90)) #percentile values for Monthly Cable Modem at 100 MBPS
View(cm$cpl_m)
nrow(cm100) #n=19

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
nrow(dsl30) #n=3
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
View(csc)

#Recall, fiber (n=58)
two <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "1-99 Mbps")
nrow(two) #should be n=20

four <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "100-199 Mbps")
nrow(four) #n=18

five <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "200-299 Mbps")
nrow(five) #n=13

six <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "300-399 Mbps")
nrow(six) #n=5

seven <- csc %>% filter(connect_category == "Fiber" & connect_type != "Dark Fiber Service" & bw_range == "1000+ Mbps")
nrow(seven) #n=2


round(quantile(two$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #1-99 Mbps
round(quantile(four$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #100-199 Mbps
round(quantile(five$cpl_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #200-299 Mbps

## median cost per line for rural districts with BW in 100-199 Mbps range ##
four %>% filter(applicant_locale == "Rural") %>% summarise(Median = median(cpl_m))


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
e <- ggplot(four.small, aes(x=cpl_m, colour=locale)) + geom_density() + xlab("Monthly Cost per Circuit (n=10)")
f <- e + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.text.y = element_blank(), 
          axis.title.y = element_blank(), axis.ticks.y = element_blank())
f


# Plotting price points according to BW Range
ggplot(two.four.five, aes(x=bw_range, colour = bw_range, y=cpl_m)) + geom_point(size=8, alpha=0.75) + xlab("BW Range") + ylab("Monthly Cost Per Line ($)")

#### MAY NOT THESE ANYMORE; REVISED TO ABOVE ^ ####
## Fiber @ 100 Mbps ##
fib100 <- fib %>% filter(bandwidth_in_mbps==100)
nrow(fib100) #n=11
quantile(fib100$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Fiber @ 200 Mbps ##
fib200 <- fib %>% filter(bandwidth_in_mbps==200)
nrow(fib200) #n=12
quantile(fib200$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Fiber @ 500 Mbps ##
fib500 <- fib %>% filter(bandwidth_in_mbps==500)
nrow(fib500) #n=0

## Fiber @ 1000 Mbps/1G ##
fib$bandwidth_in_mbps <- as.numeric(gsub(",","",fib$bandwidth_in_mbps))
fib1000 <- fib %>% filter(bandwidth_in_mbps==1000)
nrow(fib1000) #n=2
quantile(fib100$cpl_m, c(.10, .25, .50, 0.75, 0.90))

## Cable / DSL (n=61)##
c.dsl <- csc %>% filter(connect_category == "Cable / DSL") 
nrow(c.dsl) #n=61
quantile(c.dsl$cpl_m, c(.10, .25, .50, 0.75, 0.90))

c.dsl30 <- c.dsl %>% filter(bandwidth_in_mbps==30)
nrow(c.dsl30) #n=0

c.dsl50 <- c.dsl %>% filter(bandwidth_in_mbps==50)
nrow(c.dsl50) #n=9
quantile(c.dsl50$cpl_m, c(.10, .25, .50, 0.75, 0.90))

####


### Price Dispersion for Cable / DSL @ 100 Mbps (Monthly Cost Per Line) ####
c.dsl100 <- c.dsl %>% filter(bandwidth_in_mbps==100)
nrow(c.dsl100) #n=19
quantile(c.dsl100$cpl_m, c(.10, .25, .50, 0.75, 0.90))

c.dsl$bandwidth_in_mbps <- as.numeric(gsub(",","",c.dsl$bandwidth_in_mbps))
c.dsl1K <- c.dsl %>% filter(bandwidth_in_mbps==1000)
nrow(c.dsl1K) #n=0
quantile(c.dsl1K$cpl_m, c(.10, .25, .50, 0.75, 0.90))


## Copper (n=4) ##
cop <- csc %>% filter(connect_category == "Copper") 
nrow(cop) #n=4
quantile(c.dsl$cpl_m, c(.10, .25, .50, 0.75, 0.90))

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


### Distribution of Costs ###
d.costs <- density(as.numeric(as.character(csc$cpl_m)), na.rm=TRUE) #FIX!!
c.dsl <- density((c.dsl$cpl_m), na.rm=TRUE) #FIX!!!
plot(d.costs, d.costs, main = "Monthly Cost per Mbps Distribution")

## Manually changed CONTOOCOOK VALLEY REG SCH DIST cell##
CR_LI_NH_all <- read.csv("~/Desktop/ESH/CR_NH/CR_LI_NH_all.csv")
contoocook_all <- CR_LI_NH_all %>% filter(applicant_name == "CONTOOCOOK VALLEY REG SCH DIST") 
contoocook_all$number_of_dirty_line_item_flags[contoocook_all$number_of_dirty_line_item_flags == 1] <- 0 #fix one LI to clean dirty line item
contoocook_all <- contoocook_all[1:56] #reduce to relevant columns
#View(contoocook_all)



### WAN ###
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

# Remove punctuation from band_width_mbps # 
wan$bandwidth_in_mbps<- as.numeric(gsub(",","",wan$bandwidth_in_mbps))
wan1g <- wan %>% filter(bandwidth_in_mbps >= 1000) 
wan1g.lines <- sum(as.numeric(as.character(wan1g$num_lines))) 
wan1g.lines #33 lines @ >= 1G
#View(wan1g) 
wan1g.lines / wan.lines #33/196 (~16.8%) circuit lines are supporting >= 1G; 

#100 - 16.8 # 83% are < 1G


## Number of schools ##
schools <- sum(CR_MDT_NH$num_schools) #n=219
sum(as.numeric(as.character(wan$num_schools)))
## Number of schools with >= 1G WAN ##
wan1g.sch <- sum(as.numeric(as.character(wan1g$num_schools))) #n=28

## Number of schools with < 1G WAN ##
schools - wan1g.sch #n=191


## % of schools with >= 1G WAN ##
wan1g.sch/schools #12.8%
100-12.8 #87.2%


## Number of campuses: gut check of how many WAN lines we would expect to find ##
## Theoretically, there needs to be WAN lines going between campuses ##
## Excluding districts with 1 schools ##
sum(CR_MDT_NH$num_campuses) #n=183
unique(CR_MDT_NH$name) # n = 67

#Gut check cont'd ##
camp2 <- CR_MDT_NH %>% filter(num_campuses >= 2) 
nrow(camp2) #35 districts
unique(camp2$name) #35 unique districts, check
sum(camp2$num_campuses) #n=151 campuses; sounds about right compared num_lines (n=167), values are within the same ballpark
View(camp2)

## Closer look at SDs with more than 1 campus. Here we find the sum of WAN lines for campuses >= 2 subset ##
sum(as.numeric(camp2$gt_1g_wan_lines), as.numeric(CR_MDT_NH$lt_1g_fiber_wan_lines), as.numeric(CR_MDT_NH$lt_1g_nonfiber_wan_lines))
#77 wan lines comprised within SDs with more than 1 campus (n=151)

## Districts Level ##
# 42% districts are meeting goals?
# of the 77 wan lines are for SDs with >= 2 campuses?
# We think over half of your districts (maybe 35) need WAN?
# Some of these campuses (i.e. 20) have sufficient count of direct IA lines and don't need WAN
# And only a remaining 15 districts don't seem to have sufficient connection give our data. 

SR_NH <- read.csv("~/Desktop/ESH/CR_NH/SR_NH.csv")

##From Line Items Table
##Max value for WAN: 1G
##Min value for WAN: 1.5 Mbps

SR.wan <- SR_NH %>% filter(SR_NH$wan_conditions_met == TRUE & SR_NH$exclude_from_analysis == FALSE)
View(SR.wan)

SR.wan <- SR_NH %>% filter(SR_NH$wan_conditions_met == TRUE & SR_NH$exclude_from_analysis == FALSE)
unique(SR.wan$name) #to find distinct SDs that meet above conditions
sum(as.numeric(as.character(SR.wan$quantity_of_lines_received_by_district))) #n=48 matches with MDT table

#Dealing with Open_Flags = upstream_circuit
#Upstream and WAN are labelled as same technology
summary(csc$connect_category) #8 categories


###
testing <- CR_LI_NH_all %>% filter(applicant_type == "School" | applicant_type == "District")
unique(testing$applicant_name)

camp2$gt_1g_wan_lines <- as.numeric(camp2$gt_1g_wan_lines)
camp2$lt_1g_fiber_wan_lines <- as.numeric(camp2$lt_1g_fiber_wan_lines)
camp2$lt_1g_nonfiber_wan_lines <- as.numeric(camp2$lt_1g_nonfiber_wan_lines)
camp2$total_wan <- camp2$gt_1g_wan_lines + camp2$lt_1g_fiber_wan_lines + camp2$lt_1g_nonfiber_wan_lines

camp2$fiber_internet_upstream_lines <- as.numeric(camp2$fiber_internet_upstream_lines)
camp2$fixed_wireless_internet_upstream_lines <- as.numeric(camp2$fixed_wireless_internet_upstream_lines)
camp2$cable_dsl_internet_upstream_lines <- as.numeric(camp2$cable_dsl_internet_upstream_lines)
camp2$copper_internet_upstream_lines <- as.numeric(camp2$copper_internet_upstream_lines)
camp2$total_internet_upstream <- camp2$fiber_internet_upstream_lines + camp2$fixed_wireless_internet_upstream_lines + camp2$cable_dsl_internet_upstream_lines + camp2$copper_internet_upstream_lines

camp2$total_connect <- camp2$total_wan + camp2$total_internet_upstream 
View(camp2)

#Now subset: district_name, num_campuses, total_wan, total_upstream
camp2.sub <- select(camp2, name, num_schools, num_campuses, total_connect, total_wan, total_internet_upstream)
View(camp2.sub)
nrow(camp2.sub)

#Subset of which campuses and total_connect match up
camp3 <- camp2.sub %>% filter(num_campuses == total_connect | num_campuses == total_connect-1 | num_campuses == total_connect+1)
View(camp3)
nrow(camp3) #19


#FIX THIS: Subset of the rest in which campuses and total_connect do not match up
camp4 <- camp2.sub %>% filter(num_campuses != total_connect)
camp4.cont <- camp4 %>% filter(num_campuses != total_connect-1)  
camp4.cont2 <- camp4.cont %>% filter(num_campuses != total_connect+1 )
nrow(camp4.cont2) #16
View(camp4.cont2)

## Map of Districts ##
df <- as.data.frame(cbind(lon=CR_MDT_NH$longitude,lat=CR_MDT_NH$latitude))

mapNH<- get_map(location = c(lon = mean(df$lon), lat = mean(df$lat)), zoom = 7,
                      maptype = "roadmap", scale = 2)
ggmap(mapNH) +
  geom_point(data = df, aes(x = lon, y = lat, fill = "blue", alpha = 0.8), size = 5, shape = 21) +
  guides(fill=FALSE, alpha=FALSE, size=FALSE)

states <- map_data("state")
nh_df <- subset(states, region == "new hampshire")
counties <- map_data("county")
nh_county <- subset(counties, region == "new hampshire")

nh_base <- ggplot(nh_df, aes(x = long, y = lat, group = group)) +
            coord_fixed(1.3) +
            geom_polygon(color = "black", fill = "gray")

map('county', 'new hampshire') + geom_point(data = nh_county, aes(x = long, y = lat, fill = "blue", alpha = 0.8), size = 5, shape = 21) 


## Map of Districts According to Meeting Goals ##
condition <- factor(rep(NA, dim(CR_MDT_NH)[1]), levels=c("Below 2014", "Meets 2014", "Meets 2018"))
condition[CR_MDT_NH$ia_bandwidth_per_student < 100] <- "Below 2014"
condition[CR_MDT_NH$ia_bandwidth_per_student >= 100] <- "Meets 2014"
condition[CR_MDT_NH$ia_bandwidth_per_student >= 1000] <- "Meets 2018"
CR_MDT_NH$condition <- condition
View(CR_MDT_NH)


mapNHbw <- get_map(location = c(lon = mean(df$lon), lat = mean(df$lat)+0.5), zoom = 8,
                maptype = "roadmap", scale = 2, color = "bw")

p <- ggmap(mapNHbw) +
geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, shape = highest_connect_type, 
                colour=condition, size=num_schools), alpha=0.7) 

###Seeing IA_BANDWIDTH_PER_STUDENT ###
ggmap(mapNHbw) +
  geom_point(data = CR_MDT_NH, aes(x = longitude, y = latitude, colour=ia_bandwidth_per_student), size=12, alpha=0.7) 

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


wan_three <- wan2 %>% filter(bw_range_wan == "100 Mbps")
nrow(wan_three) #n=8
summary(wan_three$connect_category) #n=8 is all fiber
round(quantile(wan_three$cpc_m, c(.10, .25, .50, 0.75, 0.90)), digits=0) #100 Mbps
View(wan_three)

wan_four <- wan2 %>% filter(bw_range_wan == "101-300 Mbps")
nrow(wan_four) #n=3

wan_five <- wan2 %>% filter(bw_range_wan == "1000 Mbps")
nrow(wan_five) #n=4, but two line items are district owned, so we don't know total_cost for them



### Quick Glance at Non-Erate Districts ###
NH_DNR_C1 <- read.csv("~/Desktop/ESH/CR_NH/Not_Rcvng_C1.csv")
colnames(NH_DNR_C1)[2] <- "applicant_name"
revised.df <- LI_NH_clean[ !(LI_NH_clean$applicant_name %in% NH_DNR_C1$applicant_name), ]
#there are no non-erate districts in LI_NH_clean df. 

summary(NH_DNR_C1$Locale)
#Rural: 22      Small Town: 1     Suburban:4
summary(NH_DNR_C1$Size)
#Tiny: 21   Small: 5 Medium: 1  

### Demographics of Non-Erate Districts by Locale and Size ###
non_erate_dem <- aggregate(applicant_name ~ Locale + Size, NH_DNR_C1, length)
sum(non_erate_dem$name) #27


### Demographics of Erate Districts by Locale and Size ###
erate.df <- CR_MDT_NH[ !(CR_MDT_NH$name %in% NH_DNR_C1$applicant_name), ]
#there are no non-erate districts in CR_MDT_NH df.
erate_dem <- aggregate(name ~ locale + district_size, CR_MDT_NH, length)
sum(erate_dem$name) #67

erate_dem_viz <- as.data.frame(table(CR_MDT_NH$locale, CR_MDT_NH$district_size))
colnames(erate_dem_viz) <- c("Locale", "Size", "Freq")
ggplot(erate_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "steelblue") + 
  labs(title="Erate Districts Demographics") + theme_grey(base_size = base_size) + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + theme(axis.ticks = element_blank()) 

non_erate_dem_viz <- as.data.frame(table(NH_DNR_C1$Locale, NH_DNR_C1$Size))
colnames(non_erate_dem_viz) <- c("Locale", "Size", "Freq")
ggplot(non_erate_dem_viz, aes(Locale, Size)) +
  geom_tile(aes(fill = Freq), colour = "black") +
  scale_fill_gradient(low = "white", high = "gold1") + 
  labs(title="Non-Erate Districts Demographics") + theme_grey(base_size = base_size) + labs(x = "", y = "") + scale_x_discrete(expand = c(0, 0)) +
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
summary(CR_MDT_NH$locale)
#Rural Small Town   Suburban      Urban 
#40          9         16          2 

summary(CR_MDT_NH$locale)
#Rural Small Town   Suburban      Urban 
#40          9         16          2 

round(summary(CR_MDT_NH$locale)/nrow(CR_MDT_NH), digits=2)
#Rural Small Town   Suburban      Urban 
#0.60       0.13       0.24       0.03 

round(summary(DT_population$locale)/nrow(DT_population), digits=2)
#Rural Small Town   Suburban      Urban 
#0.67       0.10       0.22       0.01

## Also for District Size ##
summary(CR_MDT_NH$district_size)
# Large Medium  Small   Tiny 
#   2      5     35     25 

summary(DT_population$district_size)
# Large Medium  Small   Tiny 
#   2     16     65     82 


round(summary(CR_MDT_NH$district_size)/nrow(CR_MDT_NH), digits=2)
#Large Medium  Small   Tiny 
#0.03   0.07   0.52   0.37 
#We find that there is a greater represenetation of Small districts than Tiny districts
#which is different from the population distribution of district sizes

round(summary(DT_population$district_size)/nrow(DT_population), digits=2)
# Large Medium  Small   Tiny 
# 0.01   0.10   0.39   0.50 


res <- aggregate(DT_population$locale ~ DT_population$district_size,
                FUN=function(x) c(count=length(x)))
res/165


res2 <- aggregate(CR_MDT_NH$locale ~ DT_population$district_size,
                 FUN=function(x) c(count=length(x)))
res/165


#Number of Students in MDT: 95783
CR_MDT_NH %>% group_by(locale) %>% summarise(students = sum(num_students))


# Which locale is most likely to lack fiber connections?
CR_MDT_NH %>% group_by(locale) %>% filter(highest_connect_type !="Fiber") %>%  summarise(connection = length(highest_connect_type))
CR_MDT_NH %>% group_by(locale) %>% filter(highest_connect_type == "Fiber") %>%  summarise(connection = length(highest_connect_type))


goal <- CR_MDT_NH %>% group_by(locale) %>% filter(condition !="Below 2014") %>%  summarise(goal = length(condition))
goal2 <- CR_MDT_NH %>% group_by(locale) %>% filter(condition =="Below 2014") %>%  summarise(goal = length(condition))

sum(goal$goal)
sum(goal2$goal)
#adds to 66

goal
goal2

### GOALS ###
## Not Meeting Goals ##
sum(bw.low$num_students) #n=40995
round(sum(bw.low$num_students)/sum(DT_NH_clean$num_students), digits=3) #42.8%

## Meeting 2014 Goals ##
sum(bw2014$num_students) #n=54643
round(sum(bw2014$num_students)/sum(DT_NH_clean$num_students), digits=3) #57.0%

## Meeting 2018 Goals ##
sum(bw2018$num_students) #n=145
round(sum(bw2018$num_students)/sum(DT_NH_clean$num_students), digits=3) #0.2%



## Meeting goals based on connection type at the student level##
##Student Count by Highest Connect Type for Not Meeting 2014 Goals##
summary(bw.low$highest_connect_type)
bw.low %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
# highest_connect_type  students
#      Cable / DSL        1740
#           Copper         180
#            Fiber       39075

##Student Count by Highest Connect Type for Meeting 2014 Goals##
summary(bw2014$highest_connect_type)
bw2014 %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
# highest_connect_type   students
#1        Cable / DSL       6249
#2              Fiber      48394

##Student Count by Highest Connect Type for Meeting 2018 Goals##
summary(bw2018$highest_connect_type)
bw2018 %>% group_by(highest_connect_type) %>% summarise(students = sum(num_students))
#  highest_connect_type    students
#         Cable / DSL       145



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
nrow(two) #n=14
nrow(op) #n=7;
View(op)
#NOTE: half of the districts in the 11-50Mbps category are paying more than the minimum paying district with 100-199 Mbps
#They are all on fiber, all 20-50 Mbps, half of them are Rural, other half Small Town, one unknown, 
#district_sizes include: Tiny, Small, Medium
#Price ranges from: $865-1680 ~almost 2x price variability.
#TAKEAWAY: schools/districts of ^ characteristic are paying more than min. cost district in 100-199Mbps BW group.
#But then again, note that the min. cost line item in 100-199 Mbps BW group is listed as "CONSORTIA" 
#Second to min. cost line item in this BW group is listed as "District". 

### Price Comparison of Lit Fiber @ 100 Mbps Across Locale ###
fib %>% group_by(locale) %>% summarise(average_monthly_cost = mean(cpl_m), n=n()) #
fib100 %>% group_by(locale) %>% summarise(average_monthly_cost = mean(cpl_m), n=n()) #@100 Mbps

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

### FIBER ###
fib_mp <- fix_SP(fib_ct_sp$reporting_name)
View(fib_mp)

### CABLE / DSL ###
cdsl_mp <- fix_SP(cdsl_ct_sp$reporting_name)
View(cdsl_mp)







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
combined_SP <- c(unlisted_int_SP2, unlisted_up_SP2,unlisted_wan_SP2,unlisted_isp_SP2) 
View(fix_SP(combined_SP))


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
wan_sp_rep_names <- wan_sp %>% filter(reporting_name != "NA") %>% group_by(reporting_name) %>% summarise(frequency = sum(freq), percentage = sum(percent))
View(wan_sp_rep_names)




### NOW, WAN ### 
wan_ct_sp <-LI_NH_clean %>% filter(wan_conditions_met == TRUE)
nrow(wan_ct_sp) #n=30 lines

wan_ct_sp$category <- sp_category[match(wan_ct_sp$service_provider_name, sp_category$name),"category"] 
wan_ct_sp$reporting_name <- sp_category[match(wan_ct_sp$service_provider_name, sp_category$name),"reporting_name"] 
summary(wan_ct_sp$reporting_name)
wan_sp <- as.data.frame(table(wan_ct_sp$reporting_name))
colnames(wan_sp) <- c("sp", "freq")
wan_sp <-  wan_sp %>% filter(freq >= 1)
View(wan_sp)


wan_sp$category <- sp_category[match(wan_sp$sp, sp_category$name),"category"] 
wan_sp$reporting_name <- sp_category[match(wan_sp$sp, sp_category$name),"reporting_name"] 
View(wan_sp)


### SP @ Circuit Level ###
### TOTAL ###
n_lines_total <- as.numeric(as.character(ct_sp$num_lines))
circ_total <- rep(ct_sp$service_provider_name, n_lines_total)
length(circ_total) #196
circ_total_tab <- as.data.frame(table(circ_total))
View(circ_total_tab)

#Merging by reporting_name#
colnames(circ_total_tab) <- c("sp", "freq")
circ_total_tab$sp <- gsub("[[:punct:]]", "", circ_total_tab$sp)
circ_total_tab$sp <- gsub(" ", "", circ_total_tab$sp)
circ_total_tab$category <- sp_category[match(circ_total_tab$sp, sp_category$name),"category"] 
circ_total_tab$reporting_name <- sp_category[match(circ_total_tab$sp, sp_category$name),"reporting_name"] 


circ_total_tab_2 <- circ_total_tab %>% group_by(reporting_name) %>% 
                    summarise(freq = sum(freq)) %>% 
                    mutate(percent=round((freq/sum(freq))*100, digits=0)) %>% 
                    arrange(desc(freq))

sum(circ_total_tab_2$freq)
View(circ_total_tab_2)

### FIBER ###
fib_ct_sp <- ct_sp %>% filter(connect_category == "Fiber")
n_lines_fib <- as.numeric(as.character(fib_ct_sp$num_lines))
circ_fib <- rep(fib_ct_sp$service_provider_name, n_lines_fib)  
circ_fib_tab <- as.data.frame(table(circ_fib))
View(circ_fib_tab)
#length(circ_fib) #89 checked


# Merging by reporting_name #
colnames(circ_fib_tab) <- c("sp", "freq")
circ_fib_tab$sp <- gsub("[[:punct:]]", "", circ_fib_tab$sp)
circ_fib_tab$sp <- gsub(" ", "", circ_fib_tab$sp)
circ_fib_tab$category <- sp_category[match(circ_fib_tab$sp, sp_category$name),"category"] 
circ_fib_tab$reporting_name <- sp_category[match(circ_fib_tab$sp, sp_category$name),"reporting_name"] 

circ_fib_tab_2 <- circ_fib_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=0)) %>% 
  arrange(desc(freq))

sum(circ_fib_tab_2$freq)
View(circ_fib_tab_2)


### CABLE/DSL ###
cdsl_ct_sp <- ct_sp %>% filter(connect_category == "Cable / DSL")
n_lines_cdsl <- as.numeric(as.character(cdsl_ct_sp$num_lines))
circ_cdsl <- rep(cdsl_ct_sp$service_provider_name, n_lines_cdsl)  
circ_cdsl_tab <- as.data.frame(table(circ_cdsl))
View(circ_cdsl_tab)
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

sum(circ_cdsl_tab_2$freq)
View(circ_cdsl_tab_2)




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
View(circ_nonfib_tab)
#length(circ_cdsl) #95


# Merging by reporting_name #
colnames(circ_nonfib_tab) <- c("sp", "freq")
circ_nonfib_tab$sp <- gsub("[[:punct:]]", "", circ_nonfib_tab$sp)
circ_nonfib_tab$sp <- gsub(" ", "", circ_nonfib_tab$sp)
circ_nonfib_tab$category <- sp_category[match(circ_nonfib_tab$sp, sp_category$name),"category"] 
circ_nonfib_tab$reporting_name <- sp_category[match(circ_nonfib_tab$sp, sp_category$name),"reporting_name"] 

circ_nonfib_tab_2 <- circ_nonfib_tab %>% group_by(reporting_name) %>% 
  summarise(freq = sum(freq)) %>% 
  mutate(percent=round((freq/sum(freq))*100, digits=0)) %>% 
  arrange(desc(freq))

sum(circ_nonfib_tab_2$freq)
View(circ_nonfib_tab_2)



### Distribution of SPs by location ###
##append lon. and lat. columns to ct_sp
ct_sp$longitude <- CR_MDT_NH[match(ct_sp$applicant_name, CR_MDT_NH$name),"longitude"] 
ct_sp$latitude <- CR_MDT_NH[match(ct_sp$applicant_name, CR_MDT_NH$name),"latitude"] 
View(ct_sp)

loc_ct_sp <- ct_sp %>% filter(longitude != "NA")
View(loc_ct_sp) #checked

ggmap(mapNH) +
  geom_point(data = loc_ct_sp, aes(x = longitude, y = latitude, 
                                   colour=reporting_name), size = 11, alpha=0.7) 


### compare to cost & locale e.g. districts that are 100Mbps, Lit Fiber, Suburban ###
#Harder to do bc there's many rows using more than one service providers #

#### LEADERS & LAGGARDS ####

### Leaders ###
m2014 <- CR_MDT_NH %>% filter(ia_bandwidth_per_student >= 100)
m2014_fiber <- m2014 %>% filter(all_ia_connectcat == "{Fiber}")
nrow(m2014_fiber)
gc_m2014_fiber <- m2014_fiber %>% mutate(goal_comparison = round(total_monthly_cost/total_bw_mbps, digits=2))
View(gc_m2014_fiber) #checked with Lacy
#now create percentiles for these values; note the median
#Compare schools with national median: 




small_schools <- CR_MDT_NH %>% filter(num_students < 150)
View(small_schools)


### Laggards ###
b2014 <- CR_MDT_NH %>% filter(condition == "Below 2014")
summary(b2014$all_ia_connectcat)



### Disaggregate districts that are Cable and those that are DSL ###
### Among the Districts that are categorized as Cable / DSL, which are Cable and which are DSL? ###
cdsl <- CR_MDT_NH %>% filter(all_ia_connectcat == '{"Cable / DSL"}')
nrow(cdsl) #18
View(cdsl)

cdsl <- CR_MDT_NH %>% filter(all_ia_connectcat == '{"Cable / DSL"}')  %>% select(name, all_ia_connectcat, all_ia_connecttype, internet_sp)
#3 districts are DSL
#15 are Cable Modem

### Schools on Fiber ###
num_schools_on_fib <- CR_MDT_NH %>% filter(highest_connect_type == "Fiber") %>% summarise(schools = sum(num_schools))
num_schools_on_fib #187
total_num_schools <- sum(CR_MDT_NH$num_schools) #219
total_num_schools
num_schools_on_fib / total_num_schools #0.8538813 -> 85%




### LOOKING INTO SERVICES RECEIVED ###
SR_NH <- read.csv("~/Desktop/ESH/CR_NH/SR_NH.csv")
View(SR_NH)
names(SR_NH)
dim(SR_NH)


class(SR_NH$num_students)
summary(SR_NH$num_students)
summary(SR_NH$district_size)
View(table(SR_NH$name))


SR_NH$ia_bandwidth_per_student <- as.numeric(as.character(SR_NH$ia_bandwidth_per_student))
condition <- factor(rep(NA, dim(SR_NH)[1]), levels=c("Below 2014", "Meets 2014", "Meets 2018"))
condition[SR_NH$ia_bandwidth_per_student < 100] <- "Below 2014"
condition[SR_NH$ia_bandwidth_per_student >= 100] <- "Meets 2014"
condition[SR_NH$ia_bandwidth_per_student >= 1000] <- "Meets 2018"
SR_NH$condition <- condition
View(SR_NH)

