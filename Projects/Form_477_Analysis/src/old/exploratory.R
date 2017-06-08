## ====================================================================================================
##
## EXPLORATORY: Explore the data, generate basic stats and figures addressing the topics below
## 
## GOAL: Link Form 477 data (at provider--census block level) to districts/schools in our universe
## so we can understand the overlap between the service providers and districts. Possible applications:
##
## 1) Provide a more comprehensive list of service provider options for districts on CCK12 
## 2)                                   "                           for district consulting work
## 3) Correlate our data about fiber and bandwidth targets and E-rate bids with the Form 477 data to develop a 
## marketplace indicator that evaluates the need and opportunity for deploying broadband to unserved or 
## underserved communities
##
## Questions we are starting to investigate:
##
## 1) Basic stats - # census blocks represented among districts in our universe, avg. # districts to a
## block, avg # service providers in a block 
## 2) Distribution of # service providers in a block by our fiber target status - in theory, most of the 
## fiber targets are in locations where there is only one or none service providers with speeds sufficient enough for 1 Mbps/student
##      -at the national level
##      -explore some interesting states - those with largest absolute % difference (between Fiber Targets/
##      Not Targets) in mean # providers in districts' blocks
## 3) At the national level, is the mean # service providers in a block significantly different for Fiber 
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
dd_blocks_sp <- read.csv("../data/interim/dd_blocks_sp.csv", as.is=T, header=T, stringsAsFactors=F,colClasses=c("blockcode"="character"))
str(dd_blocks_sp)
form_477s_final <- read.csv("../data/interim/form_477s_final.csv", as.is=T, header=T, stringsAsFactors=F,colClasses=c("blockcode"="character"))

##**************************************************************************************************************************************************
## basic stats

## number of unique blocks represented in our dataset
length(unique(dd_blocks_sp$blockcode)) #13,284
## distribution of # districts to a block
by_block=dd_blocks_sp %>% group_by(blockcode) %>% summarize(count=n()) %>% as.data.frame()
summary(by_block$count) #average # districts to a block = 1.024
## avg # service providers in a block 
summary(form_477s_final$nproviders) #6.938
## avg # service providers per district block
mean(dd_blocks_sp$nproviders) #6.943
##**************************************************************************************************************************************************
## distribution of service providers by fiber target status (national level)

library(ggplot2)
library(plyr)
library(scales)

dd_blocks_2tgts = dd_blocks_sp %>% filter(fiber_target_status %in% c("Target","Not Target")) 
#get means by Fiber Target/Not Fiber Target
sdat <- ddply(dd_blocks_2tgts, "fiber_target_status", summarise, nprov.mean=mean(nproviders))
#get means by all Fiber Target Status
sdat_all <- ddply(dd_blocks_sp, "fiber_target_status", summarise, nprov.mean=mean(nproviders))

## generate figure for 'target' vs. 'not target'
png("../figures/hist-2target.png",width=580, height=410)
ggplot(dd_blocks_2tgts, aes(x=nproviders, fill=..count..)) + geom_histogram(aes(y=..density..,fill=..density..), binwidth=1, colour="black") +
  facet_grid(fiber_target_status ~ .) + labs(title="Distribution of # Form 477 Service Providers in Census Block, by Fiber Target Status", x="Number of Providers in Census Block", y="% Districts") + 
  theme(legend.position="none", plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(limits=c(0,10), breaks = seq(0, 10, by = 1)) + scale_y_continuous(labels=percent, breaks = seq(0, 0.3, by = 0.05)) +
  geom_vline(data=sdat, aes(xintercept=nprov.mean),
             linetype="dashed", size=1, colour="red")
dev.off()

## generate figure for all fiber target statuses for appendix
png("../figures/hist-alltarget.png",width=580, height=425)
ggplot(dd_blocks_sp, aes(x=nproviders, fill=..count..)) + geom_histogram(aes(y=..density..,fill=..density..), binwidth=0.9, colour="black") +
  facet_grid(fiber_target_status ~ .) + labs(title="Distribution of # Form 477 Service Providers in Census Block, by Fiber Target Status", x="Number of Providers in Census Block", y="% Districts") + 
  theme(legend.position="none", plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(limits=c(2,13), breaks = seq(2, 13, by = 1)) + scale_y_continuous(labels=percent, breaks = seq(0, 0.4, by = 0.1)) +
  geom_vline(data=sdat_all, aes(xintercept=nprov.mean),
             linetype="dashed", size=1, colour="red")
dev.off()

detach("package:ggplot2", unload=TRUE) 
detach("package:scales", unload=TRUE) 
detach("package:plyr", unload=TRUE) 

## get the % districts with 4 or less service providers for 'target' vs. 'not target'. To get 5 or less, switch to a 5
dd_blocks_2tgts %>% mutate(l4_providers=(nproviders<=4)) %>% 
  group_by(fiber_target_status,l4_providers) %>%
  summarise (n = n()) %>%
  mutate(pct = n / sum(n))
# Not_Target         TRUE   217 0.02294839
# Target         TRUE    71 0.05159884

## explore interesting states - those with largest absolute % difference in mean # providers in districts' blocks, adjusted for % fiber target districts in the state

#replace the space in fiber_target_status with '_'
dd_blocks_sp$fiber_target_status <- gsub(" ", "_", dd_blocks_sp$fiber_target_status)
dd_blocks_2tgts$fiber_target_status <- gsub(" ", "_", dd_blocks_2tgts$fiber_target_status)
#compute the % districts in each state that are of each fiber target status
by_state_pcts=dd_blocks_sp %>% 
  group_by(postal_cd, fiber_target_status) %>%
  summarise (n = n()) %>%
  mutate(pct_target = n / sum(n))
#compute the mean # providers in each state by Target/Not Target and the total and % difference
by_state_means = dd_blocks_2tgts %>% 
  group_by(postal_cd, fiber_target_status)%>% summarize(meansp = mean(nproviders, na.rm = T)) %>% 
  spread(fiber_target_status,meansp) %>% mutate(diff = Target - Not_Target, percent_diff = abs((diff / Not_Target)))
#Join to by_state_pcts in order to 'normalize' by %Target
by_state_means=merge(by_state_means, by_state_pcts[by_state_pcts$fiber_target_status=='Target',c('postal_cd', 'pct_target')], by='postal_cd', all.x=T)
by_state_means=by_state_means %>% mutate(percent_diff_norm = percent_diff* pct_target) %>%
  arrange(desc(percent_diff_norm))
states =  by_state_means$postal_cd[1:5]

#plot
library(ggplot2)
library(plyr)
library(scales)

sdat_pc=ddply(dd_blocks_2tgts[dd_blocks_2tgts$postal_cd %in% states,], c("postal_cd","fiber_target_status"), summarise, nprov.mean=mean(nproviders))

dd_blocks_2tgts_pc=dd_blocks_2tgts[dd_blocks_2tgts$postal_cd %in% states,]
dd_blocks_2tgts_pc$postal_cd_f=factor(dd_blocks_2tgts_pc$postal_cd, levels=c("AK", "OR", "CA", "AZ", "WY"))
png("../figures/hist-2target-states.png",width=620, height=450)
ggplot(dd_blocks_2tgts_pc, aes(x=nproviders)) + geom_histogram(aes(y=..density..,fill=..density..), binwidth=0.9, colour="black") +
  facet_grid(fiber_target_status ~ postal_cd_f, scales="free") + labs(x="Number of Providers in Census Block", y="% Districts") + 
  theme(legend.position="none", plot.title = element_text(hjust = 0.5)) + 
  scale_fill_gradient("Density", low = "mediumpurple4", high = "mediumorchid1") +
  scale_y_continuous(labels=percent)
dev.off()
##**************************************************************************************************************************************************
## t-tests for number of service providers

## 'target' vs. 'not target'
x = dd_blocks_sp %>% filter(fiber_target_status %in% c("Target"))  %>% select(nproviders)
y = dd_blocks_sp %>% filter(fiber_target_status %in% c("Not_Target"))  %>% select(nproviders)
t.test(x,y, var.equal = FALSE, alternative = c("less")) #p-value = 3.22e-06,
#mean of x mean of y 
#6.749273  6.950296 
## 'potential target' vs. 'not target'
x = dd_blocks_sp %>% filter(fiber_target_status %in% c("Potential_Target"))  %>% select(nproviders)
t.test(x,y, var.equal = FALSE) #p-value = 0.05516, 
#mean of x mean of y 
#7.020910  6.950296 
##**************************************************************************************************************************************************
## blocks with few service providers (4-..) - what are the most common