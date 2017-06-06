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
## create final table grouped by district
dd_blocks_sp = districts_schools_blocks_final %>% group_by(district_esh_id) %>% summarise (nproviders = sum(nproviders))
## avg # fiber service providers in a block 
summary(dd_blocks_sp$nproviders) # 3.74
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
ggplot(dd_blocks_2tgts, aes(x=nproviders, fill=..count..)) + geom_histogram(aes(y=..density..*.86,fill=..density..), binwidth=1, colour="black") +
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
dd_blocks_2tgts %>% mutate(l1_providers=(nproviders==0)) %>% 
  group_by(fiber_target_status,l1_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target     TRUE  4646 0.4913283
# Target         TRUE   924 0.6715116
dd_blocks_2tgts %>% mutate(l1_providers=(nproviders==1)) %>% 
  group_by(fiber_target_status,l1_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target     TRUE   686 0.07254653
# Target         TRUE    80 0.05813953
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
## research question follow ups 6/5 - note many of these were adhoc checked using Mode

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
##**************************************************************************************************************************************************
## research question follow ups 6/6 

## 1
#Get target districts with 0 service providers
tgt_0sp=dd_blocks_sp %>% filter(fiber_target_status %in% c("Target"), nproviders==0)
#Join to revices_received service providers, export to csv
dta.sr_sp <- read.csv("../data/raw/services_received_2016.csv", as.is=T, header=T, stringsAsFactors=F)
tgt_0sp_allsp <- merge(tgt_0sp,dta.sr_sp, by.x="district_esh_id", by.y="recipient_id")
tgt_0sp_allsp <- tgt_0sp_allsp %>% group_by(service_provider_name) %>% summarise (ndistricts = n_distinct(district_esh_id)) %>% arrange(desc(ndistricts))

write.csv(tgt_0sp_allsp, "../data/export/service_providers_targets_0on477.csv", row.names=F)

## 2
#run analysis at block group and tract level -- only necessary to share target/not target % with 0 SPs, % with 1 SPs

#read in dataset
districts_schools_blocks_final_bg_ct <- read.csv("../data/interim/districts_schools_blocks_final_bg_ct.csv", 
                                                 as.is=T, header=T, stringsAsFactors=F,
                                                 colClasses=c("blockgroup"="character","blockcode"="character","censustract"="character"))
str(districts_schools_blocks_final_bg_ct)
#summarize by district
dd_blocks_sp_bg_ct = districts_schools_blocks_final_bg_ct %>% group_by(district_esh_id) %>% 
  summarise (nproviders_bc =sum(nproviders), nproviders_bg = sum(nproviders_bg),nproviders_ct = sum(nproviders_ct))
#merge districts deluxe to get fiber_target_status
dd_blocks_sp_bg_ct = merge(dd_blocks_sp_bg_ct,dd.2016[,c("esh_id","fiber_target_status")], by.x="district_esh_id", by.y="esh_id")
#filter just to Target vs. Not Target
dd_allblocks_2tgts = dd_blocks_sp_bg_ct %>% filter(fiber_target_status %in% c("Target","Not Target"))

## get the % districts with 0, 1 fiber service providers for 'target' vs. 'not target'

#get the total by fiber target status
dd_allblocks_2tgts_sum = dd_allblocks_2tgts %>% 
  group_by(fiber_target_status) %>% summarise (total = n()) 
#totals for blockcode 0,1 providers
dd_allblocks_2tgts_dsum0 = dd_allblocks_2tgts %>% 
  mutate(zeroproviders=(nproviders_bc==0),oneprovider=(nproviders_bc==1)) %>% 
  group_by(fiber_target_status,zeroproviders,oneprovider) %>%
  summarise (n = n()) 
dd_allblocks_2tgts_dsum0$dlevel='census block'
#totals for blockgroup 0,1 providers
dd_allblocks_2tgts_dsum1 = dd_allblocks_2tgts %>% 
  mutate(zeroproviders=(nproviders_bg==0),oneprovider=(nproviders_bg==1)) %>% 
  group_by(fiber_target_status,zeroproviders,oneprovider) %>%
  summarise (n = n()) 
dd_allblocks_2tgts_dsum1$dlevel='blockgroup'
#totals for censustract 0,1 providers
dd_allblocks_2tgts_dsum2 = dd_allblocks_2tgts %>% 
  mutate(zeroproviders=(nproviders_ct==0),oneprovider=(nproviders_ct==1)) %>% 
  group_by(fiber_target_status,zeroproviders,oneprovider) %>%
  summarise (n = n()) 
dd_allblocks_2tgts_dsum2$dlevel='census tract'
#combine
dd_allblocks_2tgts_dsum=rbind(dd_allblocks_2tgts_dsum0,dd_allblocks_2tgts_dsum1,dd_allblocks_2tgts_dsum2)
#filter for relevant info to plot
dd_allblocks_2tgts_dsum=merge(dd_allblocks_2tgts_dsum,dd_allblocks_2tgts_sum,by="fiber_target_status",all.x=T)
dd_allblocks_2tgts_dsum$pct=dd_allblocks_2tgts_dsum$n / dd_allblocks_2tgts_dsum$total
dd_allblocks_2tgts_dsum=dd_allblocks_2tgts_dsum %>% filter(zeroproviders==TRUE | oneprovider==TRUE) %>% select(-c(oneprovider,n,total))
dd_allblocks_2tgts_dsum$zeroproviders=ifelse(dd_allblocks_2tgts_dsum$zeroproviders==TRUE,0,1)

library(ggplot2)
library(plyr)
library(scales)

##chart theme
theme_esh <- function(){
  theme(
    text = element_text(color="#666666", size=13),
    panel.grid.major = element_line(color = "light grey"),
    panel.grid.major.x = element_blank(),
    panel.background = element_rect(fill = "white")
  )
}

png("../figures/hist-2target-fiber-dlevels.png",width=650, height=450)
ggplot(dd_allblocks_2tgts_dsum, aes(x = factor(dlevel,levels=c("census block","blockgroup","census tract")), 
                                    y = pct, fill = factor(zeroproviders), label =paste(round(pct*100),"%"))) +
  geom_bar(stat="identity")  + facet_grid(fiber_target_status ~ .) + 
  scale_y_continuous(labels=percent) + 
  geom_text(size = 3.7, position = position_stack(vjust = 0.5)) +
  labs(x="Analysis Level", y="% Districts") + guides(fill=guide_legend(title="# Fiber Service Providers")) +
  scale_fill_manual(values=c('#f09222' ,'#f5bc74', '#f8ddbb'))+
  theme_esh()
dev.off()
