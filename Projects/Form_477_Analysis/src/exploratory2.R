## ====================================================================================================
##
## EXPLORATORY: Explore the data, generate basic stats and figures addressing the topics below
## 
##
## Follow-ups to address after Evan meeting:
##
## Filtering for ONLY fiber service providers (TechCode='50'), and extend census blocks across all schools
##
## 1) Basic stats - # census blocks represented among districts AND schools in our universe, avg. # districts 
## AND schools to a block, avg # fiber service providers in a block 
## 2) Distribution of # fiber service providers in a block by our fiber target status - in theory, most of the 
## fiber targets are in locations where there is only one or none fiber service providers 
## 3) At the national level, is the mean # fiber service providers in a block significantly different for Fiber 
## Target vs. Not Fiber Target districts? Potential Fiber Target vs. Not Fiber Target districts? (t-test)
## ====================================================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("dplyr","tidyr","ggplot2", "plyr", "scales")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(tidyr)

## read in data
dd.2016 <- read.csv("../data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)
districts_schools_blocks_final <- read.csv("../data/interim/districts_schools_blocks_final.csv", as.is=T, header=T, stringsAsFactors=F,colClasses=c("blockcode"="character"))

##**************************************************************************************************************************************************
## basic stats

## # census blocks represented among districts AND schools in our universe
length(unique(districts_schools_blocks_final$blockcode)) #79,910
## distribution of # districts and/or schools to a block
by_block=districts_schools_blocks_final %>% group_by(blockcode) %>% summarise(count=n()) %>% as.data.frame()
summary(by_block$count) #1.27
## avg # fiber service providers in a block 
summary(districts_schools_blocks_final$nproviders) # 0.5007
## create final table grouped by district
dd_blocks_sp = districts_schools_blocks_final %>% group_by(district_esh_id) %>% summarise (nproviders = sum(nproviders))
##**************************************************************************************************************************************************
## distribution of service providers by fiber target status (national level)

library(ggplot2)
library(plyr)
library(scales)

#merge districts deluxe to get fiber_target_status
dd_blocks_sp = merge(dd_blocks_sp,dd.2016[,c("esh_id","fiber_target_status")], by.x="district_esh_id", by.y="esh_id")
dd_blocks_2tgts = dd_blocks_sp %>% filter(fiber_target_status %in% c("Target","Not Target"))
#get means by Fiber Target/Not Fiber Target
sdat <- ddply(dd_blocks_2tgts, "fiber_target_status", summarise, nprov.mean=mean(nproviders))
#get means by all Fiber Target Status
sdat_all <- ddply(dd_blocks_sp, "fiber_target_status", summarise, nprov.mean=mean(nproviders))

## generate figure for 'target' vs. 'not target'
png("../figures/hist-2target-fiber-schools.png",width=580, height=410)
ggplot(dd_blocks_2tgts, aes(x=nproviders, fill=..count..)) + geom_histogram(aes(y=..density..,fill=..density..), binwidth=1, colour="black") +
  facet_grid(fiber_target_status ~ .) + labs(title="# Form 477 Fiber Service Providers in Census Block, by Fiber Target Status", x="Number of Fiber Providers in Census Block", y="% Districts") + 
  theme(legend.position="none", plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(limits=c(-0.5,6), breaks = seq(0, 6, by = 1)) + scale_y_continuous(labels=percent, breaks = seq(0, 0.7, by = 0.1)) +
  geom_vline(data=sdat, aes(xintercept=nprov.mean),
             linetype="dashed", size=1, colour="red")
dev.off()

detach("package:ggplot2", unload=TRUE) 
detach("package:scales", unload=TRUE) 
detach("package:plyr", unload=TRUE) 

## get the % districts with 1 or less service providers for 'target' vs. 'not target'
dd_blocks_2tgts %>% mutate(l1_providers=(nproviders<=1)) %>% 
  group_by(fiber_target_status,l1_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target         TRUE   5332 0.5638748
# Target         TRUE    1004 0.7296512

##**************************************************************************************************************************************************
## t-tests for number of service providers

## 'target' vs. 'not target'
x = dd_blocks_sp %>% filter(fiber_target_status %in% c("Target"))  %>% select(nproviders)
y = dd_blocks_sp %>% filter(fiber_target_status %in% c("Not Target"))  %>% select(nproviders)
t.test(x,y, var.equal = FALSE, alternative = c("less")) #p-value < 2.2e-16,
#mean of x mean of y 
#1.683866  4.034898 
## 'potential target' vs. 'not target' -- see the same trend as when looking at all providers - 'potential targets' have more for some reason
x = dd_blocks_sp %>% filter(fiber_target_status %in% c("Potential Target"))  %>% select(nproviders)
t.test(x,y, var.equal = FALSE) #p-value = 0.3539, 
#mean of x mean of y 
#4.848406  4.034898  
##**************************************************************************************************************************************************
## research question follow ups - note many of these were adhoc checked using Mode

# gsub("\\{|\\}", "", n)
# quote=FALSE

# Let's review one example of a Not Target district with 0 service providers:
# * determine what service provider that district uses
# * determine if that service provider is close to the district / within the same census block grouping
# * determine if that service provider serves within the school polygons

#summarize by state, order by proportion of districts with 0 total service providers
not_tgt_0sp=dd_blocks_sp %>% filter(fiber_target_status %in% c("Not Target"))
not_tgt_0sp=merge(not_tgt_0sp,dd.2016[,c("esh_id","postal_cd")], by.x="district_esh_id", by.y="esh_id")
not_tgt_0sp_bystate=not_tgt_0sp %>% 
  mutate(zero_providers=(nproviders==0)) %>%
  group_by(postal_cd,zero_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n)) %>% 
  filter(zero_providers==TRUE) %>% arrange(desc(pct))
#ordered by just number of districts, not proportion with 0 providers
View(not_tgt_0sp %>%
  filter(nproviders==0) %>%
  group_by(postal_cd) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n)) %>% arrange(desc(pct)))

# Let's review one example of a Not Target district with 1 service providers:
# * determine what service provider that district uses
# * determine if that service provider is the one that that district is using
not_tgt_1sp=dd_blocks_sp %>% filter(fiber_target_status %in% c("Not Target")) %>% filter(nproviders==1) 

districts_schools_blocks_final %>% filter(district_esh_id==881447)