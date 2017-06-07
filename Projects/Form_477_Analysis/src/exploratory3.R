## ====================================================================================================
##
## EXPLORATORY: Explore the data, generate basic stats and figures addressing the topics below
## 
##
## Follow-ups to address after Evan meeting:
##
## Filtering for ONLY fiber service providers (TechCode='50') for the histograms, repeating at the 
## blockgroup and census tract level, extend across all schools
## Need to aggregate properly to count disinct providers within districts after extending to all schools
##
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
#read in dataset
districts_schools_blocks_final_bg_ct <- read.csv("../data/interim/districts_schools_blocks_final_bg_ct3.csv", 
                                                 as.is=T, header=T, stringsAsFactors=F)
str(districts_schools_blocks_final_bg_ct)

## avg # fiber service providers in a block - stat that needs to change with new aggregation 
summary(districts_schools_blocks_final_bg_ct$nproviders_bc) # 0.815
##**************************************************************************************************************************************************
## distribution of service providers by fiber target status (national level)

library(ggplot2)
library(plyr)
library(scales)

dd_blocks_2tgts = districts_schools_blocks_final_bg_ct %>% filter(fiber_target_status %in% c("Target","Not Target"))
#get means by Fiber Target/Not Fiber Target
sdat <- ddply(dd_blocks_2tgts, "fiber_target_status", summarise, nprov.mean=mean(nproviders_bc))
#get means by all Fiber Target Status
sdat_all <- ddply(districts_schools_blocks_final_bg_ct, "fiber_target_status", summarise, nprov.mean=mean(nproviders_bc))

## generate figure for 'target' vs. 'not target'
png("../figures/hist-2target-fiber-schools.png",width=580, height=410)
ggplot(dd_blocks_2tgts, aes(x=nproviders_bc, fill=..count..)) + geom_histogram(aes(y=..density..*.98,fill=..density..), binwidth=1, colour="black") +
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
dd_blocks_2tgts %>% mutate(l1_providers=(nproviders_bc==0)) %>% 
  group_by(fiber_target_status,l1_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target     TRUE  4653 0.4913930
# Target         TRUE   927 0.6717391
dd_blocks_2tgts %>% mutate(l1_providers=(nproviders_bc==1)) %>% 
  group_by(fiber_target_status,l1_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target     TRUE   2957 0.3122822
# Target         TRUE   294 0.2130435
##**************************************************************************************************************************************************
## t-tests for number of service providers

## 'target' vs. 'not target'
x = districts_schools_blocks_final_bg_ct %>% filter(fiber_target_status %in% c("Target"))  %>% select(nproviders_bc)
y = districts_schools_blocks_final_bg_ct %>% filter(fiber_target_status %in% c("Not Target"))  %>% select(nproviders_bc)
t.test(x,y, var.equal = FALSE, alternative = c("less")) #p-value < 2.2e-16,
#mean of x mean of y 
#0.5014493 0.8534164 
## 'potential target' vs. 'not target' -- see the same trend as when looking at all providers - 'potential targets' have more for some reason
x = districts_schools_blocks_final_bg_ct %>% filter(fiber_target_status %in% c("Potential Target"))  %>% select(nproviders_bc)
t.test(x,y, var.equal = FALSE) #p-value = 0.0002213, 
#mean of x mean of y 
#0.9630607 0.8534164  

##**************************************************************************************************************************************************
## research question follow ups 6/6 

## 2
#run analysis at block group and tract level -- only necessary to share target/not target % with 0 SPs, % with 1 SPs

#filter just to Target vs. Not Target
dd_allblocks_2tgts = districts_schools_blocks_final_bg_ct %>% filter(fiber_target_status %in% c("Target","Not Target"))

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
