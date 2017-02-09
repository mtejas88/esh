## ==============================================================================================================================
##
## UPGRADE ANALYSIS
##
## 1) STATE ANALYSIS
## 2) COST ANALYSIS
## 3) NOT MEETING GOALS
## 4) HOW MANY MORE DISTRICTS WOULD BE MEETING GOALS IF APPLY THE MEDIAN BW CHANGE?
## 5) MEGAS AND LARGES
## 6) COST CORRELATIONS
## 7) MID-CONTRACT EXPIRATION QA
##
## ==============================================================================================================================

## Clearing memory
rm(list=ls())

setwd("~/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Org-wide Projects/Progress Tracking/MASTER_MASTER/code/")

##**************************************************************************************************************************************************
## READ IN FILES

## Deluxe Districts files
dd.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/raw/deluxe_districts/"
dd.files <- list.files(dd.directory)
dd.2015.files <- dd.files[grepl("2015-districts-deluxe", dd.files)]
dd.2016.files <- dd.files[grepl("2016-districts-deluxe", dd.files)]
## read in deluxe districts
dd.2015 <- read.csv(paste(dd.directory, dd.2015.files[length(dd.2015.files)], sep=''), as.is=T, header=T, stringsAsFactors=F)
dd.2016 <- read.csv(paste(dd.directory, dd.2016.files[length(dd.2016.files)], sep=''), as.is=T, header=T, stringsAsFactors=F)

## Upgrades
up.directory <- "../../Snapshots/sm_dashboard_master/metrics_frozen/data/processed/upgrades/"
up.files <- list.files(up.directory)
up.files <- up.files[grepl("districts_upgraded_as_of_", up.files)]
upgrades.pop <- read.csv(paste(up.directory, up.files[length(up.files)], sep=''), as.is=T, header=T, stringsAsFactors=F)

## read in state governor info
gov.info <- read.csv("../data/snapshots_12_12_2016_with_state_info.csv", as.is=T, header=T, stringsAsFactors=F)
names(gov.info) <- gov.info[1,]
gov.info <- gov.info[-1,]

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## make sure to subset to include_in_universe_of_districts first for 2016
dd.2016 <- dd.2016[dd.2016$include_in_universe_of_districts == TRUE,]
dd.2016 <- dd.2016[!dd.2016$district_type %in% c("BIE", "Charter"),]
dd.2016 <- dd.2016[!duplicated(dd.2016$esh_id),]
## take out DC in both years
#dd.2016 <- dd.2016[dd.2016$postal_cd != 'DC',]
#dd.2015 <- dd.2015[dd.2015$postal_cd != 'DC',]
## change to numeric
dd.2015$monthly_ia_cost_per_mbps <- suppressWarnings(as.numeric(dd.2015$monthly_ia_cost_per_mbps))

## merge cost information from dd.2015 and dd.2016
upgrades.pop <- merge(upgrades.pop, dd.2015[,c('esh_id', 'ia_monthly_cost_total', 'monthly_ia_cost_per_mbps')], by='esh_id', all.x=T)
names(upgrades.pop)[names(upgrades.pop) %in% c('ia_monthly_cost_total', 'monthly_ia_cost_per_mbps')] <- c('ia_monthly_cost_total_2015', 'ia_monthly_cost_per_mbps_2015')
upgrades.pop <- merge(upgrades.pop, dd.2016[,c('esh_id', 'ia_monthly_cost_total', 'ia_monthly_cost_per_mbps', 'exclude_from_ia_cost_analysis')],
                      by='esh_id', all.x=T)
names(upgrades.pop)[names(upgrades.pop) %in% c('ia_monthly_cost_total', 'ia_monthly_cost_per_mbps')] <- c('ia_monthly_cost_total_2016', 'ia_monthly_cost_per_mbps_2016')
## create a subset of cost for population (where cost per mbps is not infinite or NA)
upgrades.pop.cost <- upgrades.pop[which(!is.na(upgrades.pop$ia_monthly_cost_per_mbps_2015) & !is.infinite(upgrades.pop$ia_monthly_cost_per_mbps_2015) &
                                          upgrades.pop$postal_cd != 'AK' & upgrades.pop$exclude_from_ia_cost_analysis == FALSE),]

## create upgrades subset
upgrades <- upgrades.pop[which(upgrades.pop$upgrade == TRUE),]
upgrades$perc.cost.change <- round((upgrades$ia_monthly_cost_total_2016 - upgrades$ia_monthly_cost_total_2015) / upgrades$ia_monthly_cost_total_2015, 2)
## create cushion for 1% cost change
upgrades$cost.change <- ifelse((upgrades$ia_monthly_cost_total_2016 - upgrades$ia_monthly_cost_total_2015) / upgrades$ia_monthly_cost_total_2015 > 0.01
                               | (upgrades$ia_monthly_cost_total_2016 - upgrades$ia_monthly_cost_total_2015) / upgrades$ia_monthly_cost_total_2015 < -0.01, 1, 0)
## create a subset of cost for upgrades (where cost per mbps is not infinite or NA)
upgrades.cost <- upgrades[which(!is.na(upgrades$ia_monthly_cost_per_mbps_2015) & !is.infinite(upgrades$ia_monthly_cost_per_mbps_2015) &
                                  upgrades$postal_cd != 'AK' & upgrades$exclude_from_ia_cost_analysis == FALSE),]

##===================================================================================================================================
## 1) STATE ANALYSIS

## the overall population who upgraded:
table(upgrades.pop$upgrade)
round(nrow(upgrades) / nrow(upgrades.pop), 2)
## Where did it happen most? Calculate percentage of switches for each state
upgrades.pop$counter <- ifelse(upgrades.pop$upgrade == TRUE, 1, 0)
tab.upgrade <- aggregate(upgrades.pop$counter, by=list(upgrades.pop$postal_cd), FUN=mean, na.rm=T)
names(tab.upgrade) <- c('postal_cd', 'percent_upgraded')
tab.upgrade$percent_upgraded <- round(tab.upgrade$percent_upgraded*100, 0)
tab.upgrade <- tab.upgrade[order(tab.upgrade$percent_upgraded, decreasing=T),]

## quartiles
## seems clustered in the middle
quantile(tab.upgrade$percent_upgraded, na.rm=T)
tab.upgrade$x <- 1:nrow(tab.upgrade)
plot(tab.upgrade$x, tab.upgrade$percent_upgraded)
table(tab.upgrade$percent_upgraded > 29 & tab.upgrade$percent_upgraded < 52.5)
tab.upgrade$x <- NULL

## deciles
## the majority of states upgraded between 24 and 56% of their districts
quantile(tab.upgrade$percent_upgraded, na.rm=T, seq(0,1,by=0.1))

## few state outliers:
## high: NC (100%), TN (84%)
## low: WY (0%), UT (5%), CT (9%)

## merge in gov info
gov.info <- gov.info[,c('postal_code', '2015 Category', '2016 Category', 'ESH engagement', 'State Matching Funds')]
tab.upgrade <- merge(tab.upgrade, gov.info, by.x='postal_cd', by.y='postal_code', all.x=T)
tab.upgrade <- tab.upgrade[order(tab.upgrade$percent_upgraded, decreasing=T),]
write.csv(tab.upgrade, "../data/states_upgraded.csv", row.names=F)

##===================================================================================================================================
## 2) COST ANLAYSIS

## TOTAL MONTHLY COST

## look at the subset of upgrades that have cost information
nrow(upgrades.cost)
nrow(upgrades)
round(nrow(upgrades.cost) / nrow(upgrades), 2)

## how many districts saw cost increase?
upgrades.cost.increase <- upgrades.cost[which(upgrades.cost$cost.change == 1 & upgrades.cost$ia_monthly_cost_total_2016 > upgrades.cost$ia_monthly_cost_total_2015),]
nrow(upgrades.cost.increase)
nrow(upgrades.cost)
round(nrow(upgrades.cost.increase) / nrow(upgrades.cost), 2)
## average BW change
mean(upgrades.cost.increase$diff.bw, na.rm=T)
median(upgrades.cost.increase$diff.bw, na.rm=T)
mean(upgrades.cost.increase$perc.bw, na.rm=T)
median(upgrades.cost.increase$perc.bw, na.rm=T)

## how many districts saw cost decrease?
upgrades.cost.decrease <- upgrades.cost[which(upgrades.cost$cost.change == 1 & upgrades.cost$ia_monthly_cost_total_2016 < upgrades.cost$ia_monthly_cost_total_2015),]
nrow(upgrades.cost.decrease)
nrow(upgrades.cost)
round(nrow(upgrades.cost.decrease) / nrow(upgrades.cost), 2)

## how many districts saw no cost change?
upgrades.cost.no.change <- upgrades.cost[which(upgrades.cost$cost.change == 0),]
nrow(upgrades.cost.no.change)
nrow(upgrades.cost)
round(nrow(upgrades.cost.no.change) / nrow(upgrades.cost), 2)

## define no cost change as cost decrease or no change
upgrades.cost.no.change <- rbind(upgrades.cost.no.change, upgrades.cost.decrease)
nrow(upgrades.cost.no.change)
nrow(upgrades.cost)
round(nrow(upgrades.cost.no.change) / nrow(upgrades.cost), 2)
## average BW change
mean(upgrades.cost.no.change$diff.bw, na.rm=T)
median(upgrades.cost.no.change$diff.bw, na.rm=T)
mean(upgrades.cost.no.change$perc.bw, na.rm=T)
median(upgrades.cost.no.change$perc.bw, na.rm=T)


## COST PER MBPS
## create cushion for 1% cost change -- 3,585 changed
upgrades.cost$cost.per.mbps.change <- ifelse(abs((upgrades.cost$ia_monthly_cost_per_mbps_2016 - upgrades.cost$ia_monthly_cost_per_mbps_2015) / upgrades.cost$ia_monthly_cost_per_mbps_2015) > 0.01, 1, 0)


##===================================================================================================================================
## 3) NOT MEETING GOALS

## how many districts were not meeting goals in 2015
not.meeting.2015 <- upgrades.pop[which(upgrades.pop$meeting_goals_2015 == FALSE),]
nrow(not.meeting.2015)
nrow(upgrades.pop)
round(nrow(not.meeting.2015) / nrow(upgrades.pop), 2)
## how many of those districts upgraded?
nrow(not.meeting.2015[which(not.meeting.2015$upgrade == TRUE),])
round(nrow(not.meeting.2015[which(not.meeting.2015$upgrade == TRUE),]) / nrow(not.meeting.2015), 2)

## how many districts were not meeting goals before they upgraded?
upgrades.not.meeting.2015 <- upgrades[which(upgrades$meeting_goals_2015 == FALSE),]
nrow(upgrades.not.meeting.2015)
## what percentage of the upgrades
round(nrow(upgrades.not.meeting.2015) / nrow(upgrades), 2)
## what percentage of the population
round(nrow(upgrades.not.meeting.2015) / nrow(upgrades.pop), 2)

## how many of those districts are meeting goals?
table(upgrades.not.meeting.2015$meeting_goals_2016)
## what percentage is that of the districts that were not meeting goals?
round(nrow(upgrades.not.meeting.2015[upgrades.not.meeting.2015$meeting_goals_2016 == TRUE,]) / nrow(upgrades.not.meeting.2015), 2)
## what percentage is that of the total upgrades?
## in Ultimate Master: 33%
round(nrow(upgrades.not.meeting.2015[upgrades.not.meeting.2015$meeting_goals_2016 == TRUE,]) / nrow(upgrades), 2)

## how many of those districts are still not meeting goals?
table(upgrades.not.meeting.2015$meeting_goals_2016)
round(nrow(upgrades.not.meeting.2015[which(upgrades.not.meeting.2015$meeting_goals_2016 == FALSE),]) / nrow(upgrades.not.meeting.2015), 2)
## subset to these districts
sub.not.meeting.2016 <- upgrades.not.meeting.2015[upgrades.not.meeting.2015$meeting_goals_2016 == FALSE,]
## is there a pattern with locale?
table(sub.not.meeting.2016$locale)
## percentage based on all population?
upgrades.pop$not.meeting.all.goals <- ifelse(upgrades.pop$esh_id %in% sub.not.meeting.2016$esh_id, 1, 0)
locale.agg <- aggregate(upgrades.pop$not.meeting.all.goals, by=list(upgrades.pop$locale), FUN=mean, na.rm=T)
## is there a pattern with district size?
table(sub.not.meeting.2016$district_size)
## percentage based on all population?
ds.agg <- aggregate(upgrades.pop$not.meeting.all.goals, by=list(upgrades.pop$district_size), FUN=mean, na.rm=T)
## look at the distribution of BW per student
pdf("../figures/bw_per_student_upgrades_not_meeting_connectivity_goals_2015_and_2016.pdf", height=6, width=8)
hist(sub.not.meeting.2016$ia_bandwidth_per_student_kbps_2016, xlab="Bandwidth per Student",
     main="Upgrades Not Meeting Goals\nin 2015 & 2016", col=rgb(0,0,0,0.6), border=F)
dev.off()

## collect the actual data in the histogram
hist1 <- hist(sub.not.meeting.2016$ia_bandwidth_per_student_kbps_2016)
dta.hist <- data.frame(breaks=hist1$breaks[2:length(hist1$breaks)], counts=hist1$counts, density=hist1$density)
write.csv(dta.hist, "../data/bw_per_student_upgrades_not_meeting_connectivity_goals_2015_and_2016.csv", row.names=F)
## write out the full data
write.csv(sub.not.meeting.2016, "../data/upgrades_not_meeting_connectivity_goals_2015_and_2016.csv", row.names=F)


##===================================================================================================================================
## 4) HOW MANY MORE DISTRICTS WOULD BE MEETING GOALS IF APPLYING THE MEDIAN/MEAN PERCENT BW CHANGE

## which districts upgraded and went from not meeting goals to meeting them with no cost change (including a cost decrease)?
sub.ideals <- upgrades[which(upgrades$meeting_goals_2015 == FALSE & upgrades$meeting_goals_2016 == TRUE),]
sub.ideals <- sub.ideals[which(sub.ideals$cost.change == 0 | sub.ideals$ia_monthly_cost_total_2015 > sub.ideals$ia_monthly_cost_total_2016),]
nrow(sub.ideals)
## assign percent bw increase as mean (instead of median)
quantile(sub.ideals$perc.bw)
quantile(sub.ideals$perc.bw, seq(0,1,by=0.01))
median(sub.ideals$perc.bw)
## calculate the mean by taking out the top 5% outliers
mean(sub.ideals$perc.bw)
mean(sub.ideals$perc.bw[sub.ideals$perc.bw <= 2000])
perc.increase <- mean(sub.ideals$perc.bw[sub.ideals$perc.bw <= 2000])


## how many districts are not meeting goals in 2016
sub <- upgrades.pop[upgrades.pop$meeting_goals_2016 == FALSE,]
nrow(sub)
sub.not.meeting.2016 <- upgrades.pop[which(upgrades.pop$upgrade == FALSE & upgrades.pop$meeting_goals_2016 == FALSE),]
nrow(sub.not.meeting.2016)
sub.not.meeting.2016$hypothetical_total_bw <- sub.not.meeting.2016$total_ia_bw_2016 + perc.increase*sub.not.meeting.2016$total_ia_bw_2015
## create indicator for meeting goals
sub.not.meeting.2016$hypothetical_meeting_goal <- ifelse((sub.not.meeting.2016$hypothetical_total_bw*1000) / sub.not.meeting.2016$num_students_2016 >= 100, 1, 0)
table(sub.not.meeting.2016$hypothetical_meeting_goal)
nrow(sub.not.meeting.2016)
round(nrow(sub.not.meeting.2016[sub.not.meeting.2016$hypothetical_meeting_goal == 1,]) / nrow(sub.not.meeting.2016), 2)

## DATA REQUEST: For Governor Analysis
## initial subset: clean in both years and not meeting goals in 2015
sub <- upgrades.pop[upgrades.pop$meeting_goals_2015 == FALSE & upgrades.pop$upgrade == TRUE,]
sub$counter <- 1
sub$counter.not.meeting.2016 <- ifelse(sub$meeting_goals_2016 == FALSE, 1, 0)
sub$counter.meeting.2016 <- ifelse(sub$meeting_goals_2016 == TRUE, 1, 0)
## aggregated by state: sum districts, schools
agg.state.districts <- aggregate(sub$counter, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.state.districts) <- c('postal_cd', 'num_districts_in_sample')
agg.state.students <- aggregate(sub$num_students_2016, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.state.students) <- c('postal_cd', 'num_students_in_sample')
agg.districts.not.meeting.2016 <- aggregate(sub$counter.not.meeting.2016, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.districts.not.meeting.2016) <- c('postal_cd', 'num_districts_not_meeting_2016')
agg.students.not.meeting.2016 <- aggregate(sub$counter.not.meeting.2016*sub$num_students_2016, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.students.not.meeting.2016) <- c('postal_cd', 'num_students_not_meeting_2016')
agg.districts.meeting.2016 <- aggregate(sub$counter.meeting.2016, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.districts.meeting.2016) <- c('postal_cd', 'num_districts_meeting_2016')
agg.students.meeting.2016 <- aggregate(sub$counter.meeting.2016*sub$num_students_2016, by=list(sub$postal_cd), FUN=sum, na.rm=T)
names(agg.students.meeting.2016) <- c('postal_cd', 'num_students_meeting_2016')

## merge
dta.sub <- merge(agg.state.districts, agg.state.students, by='postal_cd', all=T)
dta.sub <- merge(dta.sub, agg.districts.not.meeting.2016, by='postal_cd', all=T)
dta.sub <- merge(dta.sub, agg.students.not.meeting.2016, by='postal_cd', all=T)
dta.sub <- merge(dta.sub, agg.districts.meeting.2016, by='postal_cd', all=T)
dta.sub <- merge(dta.sub, agg.students.meeting.2016, by='postal_cd', all=T)
## create a national row
dta.sub[nrow(dta.sub)+1,] <- c('ALL', colSums(dta.sub[,c(2:ncol(dta.sub))]))
write.csv(dta.sub, "../data/governor_analysis_districts_students_meeting_goals_after_upgrade.csv", row.names=F)

##===================================================================================================================================
## 5) MEGA AND LARGE DISTRICTS

## subset to mega and larges in the population
mega.large <- upgrades.pop[which(upgrades.pop$district_size %in% c('Mega', 'Large')),]
nrow(mega.large)
nrow(upgrades.pop)
round(nrow(mega.large) / nrow(upgrades.pop), 2)
## how many upgraded
table(mega.large$upgrade)
mega.large.upgrades <- mega.large[which(mega.large$upgrade == TRUE),]
## what percentage of the megas/larges upgraded
round(nrow(mega.large.upgrades) / nrow(mega.large), 2)
nrow(mega.large)
## what percentage of the population that upgraded
round(nrow(mega.large.upgrades) / nrow(upgrades), 2)
nrow(mega.large.upgrades)
nrow(upgrades)

## COST
## how many upgraded with no cost change?
mega.large.upgrades.cost <- upgrades.cost[upgrades.cost$district_size %in% c('Mega', 'Large'),]
table(mega.large.upgrades.cost$cost.change)
nrow(mega.large.upgrades.cost[which(mega.large.upgrades.cost$cost.change == 0),])
round(nrow(mega.large.upgrades.cost[which(mega.large.upgrades.cost$cost.change == 0),]) / nrow(mega.large.upgrades.cost), 2)
## how many upgraded with a cost decrease?
nrow(mega.large.upgrades.cost[which(mega.large.upgrades.cost$cost.change == 1 & mega.large.upgrades.cost$ia_monthly_cost_total_2015 > mega.large.upgrades.cost$ia_monthly_cost_total_2016),])
round(nrow(mega.large.upgrades.cost[which(mega.large.upgrades.cost$cost.change == 1 & mega.large.upgrades.cost$ia_monthly_cost_total_2015 > mega.large.upgrades.cost$ia_monthly_cost_total_2016),]) /
        nrow(mega.large.upgrades.cost), 2)


## MEGAS
mega <- upgrades.pop[which(upgrades.pop$district_size == 'Mega'),]
## how many upgraded
table(mega$upgrade)
mega.upgrades <- mega[which(mega$upgrade == TRUE),]
nrow(mega.upgrades)
## what percentage of megas upgraded
round(nrow(mega.upgrades) / nrow(mega), 2)
nrow(mega)
## what percentage are megas of the general population
round(nrow(mega) / nrow(upgrades.pop), 2)
## what percent are megas of the upgrades
round(nrow(mega.upgrades) / nrow(upgrades), 2)
## mean difference in bw/student
mean(mega.upgrades$diff.bw.per.student, na.rm=T)
mean(mega.upgrades$ia_bandwidth_per_student_kbps_2015, na.rm=T)


## LARGE
large <- upgrades.pop[which(upgrades.pop$district_size == 'Large'),]
## how many upgraded
table(large$upgrade)
large.upgrades <- large[which(large$upgrade == TRUE),]
nrow(large.upgrades)
nrow(large)
## what percentage of larges upgraded
round(nrow(large.upgrades) / nrow(large), 2)
## what percentage are larges of the general population
round(nrow(large) / nrow(upgrades.pop), 2)
## what percent are larges of the upgrades
round(nrow(large.upgrades) / nrow(upgrades), 2)
## mean difference in bw/student
mean(large.upgrades$diff.bw.per.student, na.rm=T)
mean(large.upgrades$ia_bandwidth_per_student_kbps_2015, na.rm=T)


## request to break down upgrades by the rest of the district sizes:
unique(upgrades$district_size)

## MEDIUM
medium <- upgrades.pop[which(upgrades.pop$district_size == 'Medium'),]
## how many upgraded
table(medium$upgrade)
medium.upgrades <- medium[which(medium$upgrade == TRUE),]
nrow(medium.upgrades)
nrow(medium)
## what percentage of mediums upgraded
round(nrow(medium.upgrades) / nrow(medium), 2)
## what percentage are mediums of the general population
round(nrow(medium) / nrow(upgrades.pop), 2)
## what percent are mediums of the upgrades
round(nrow(medium.upgrades) / nrow(upgrades), 2)
## mean difference in bw/student
mean(medium.upgrades$diff.bw.per.student, na.rm=T)
mean(medium.upgrades$ia_bandwidth_per_student_kbps_2015, na.rm=T)

## SMALL
small <- upgrades.pop[which(upgrades.pop$district_size == 'Small'),]
## how many upgraded
table(small$upgrade)
small.upgrades <- small[which(small$upgrade == TRUE),]
nrow(small.upgrades)
nrow(small)
## what percentage of smalls upgraded
round(nrow(small.upgrades) / nrow(small), 2)
## what percentage are smalls of the general population
round(nrow(small) / nrow(upgrades.pop), 2)
## what percent are smalls of the upgrades
round(nrow(small.upgrades) / nrow(upgrades), 2)
## mean difference in bw/student
mean(small.upgrades$diff.bw.per.student, na.rm=T)
mean(small.upgrades$ia_bandwidth_per_student_kbps_2015, na.rm=T)
mean(small.upgrades$ia_bandwidth_per_student_kbps_2016, na.rm=T)

## TINY
tiny <- upgrades.pop[which(upgrades.pop$district_size == 'Tiny'),]
## how many upgraded
table(tiny$upgrade)
tiny.upgrades <- tiny[which(tiny$upgrade == TRUE),]
nrow(tiny.upgrades)
nrow(tiny)
## what percentage of tinys upgraded
round(nrow(tiny.upgrades) / nrow(tiny), 2)
## what percentage are tinys of the general population
round(nrow(tiny) / nrow(upgrades.pop), 2)
## what percent are tinys of the upgrades
round(nrow(tiny.upgrades) / nrow(upgrades), 2)
## mean difference in bw/student
mean(tiny.upgrades$diff.bw.per.student, na.rm=T)
mean(tiny.upgrades$ia_bandwidth_per_student_kbps_2015, na.rm=T)
mean(tiny.upgrades$ia_bandwidth_per_student_kbps_2016, na.rm=T)


##===================================================================================================================================
## 6) COST CORRELATIONS
## was an upgrade likely to happen at a certain starting cost?

## TOTAL MONTHLY COST
## are there outliers?
quantile(upgrades.cost$ia_monthly_cost_total_2015, na.rm=T)
quantile(upgrades.cost$ia_monthly_cost_total_2015, na.rm=T, seq(0,1,by=0.1))

## create dataset to collect the reported numbers below:
dta.tab.monthly.cost <- data.frame(matrix(NA, nrow=3, ncol=5))
dta.tab.monthly.cost[,1] <- c('Upgraders', 'Non-Upgraders', 'All')
names(dta.tab.monthly.cost) <- c('', 'Mean Total Monthly Cost 2015', 'Mean Total Monthly Cost 2016',
                                'Median Total Monthly Cost 2015', 'Median Total Monthly Cost 2016')

## average starting total cost of upgraders
## 2015
## in Ultimate Master: $4,527
dta.tab.monthly.cost$`Mean Total Monthly Cost 2015`[1] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2015`[1] <- median(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## 2016
## in Ultimate Master: $4,862
dta.tab.monthly.cost$`Mean Total Monthly Cost 2016`[1] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2016`[1] <- median(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)

## average starting total cost of non-upgraders
## 2015
## in Ultimate Master: $4,157
dta.tab.monthly.cost$`Mean Total Monthly Cost 2015`[2] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2015`[2] <- median(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## 2016
## in Ultimate Master: $3,345
dta.tab.monthly.cost$`Mean Total Monthly Cost 2016`[2] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2016`[2] <- median(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)

## average starting total cost of total population
## 2015
dta.tab.monthly.cost$`Mean Total Monthly Cost 2015`[3] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2015, na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2015`[3] <- median(upgrades.pop.cost$ia_monthly_cost_total_2015, na.rm=T)
## 2016
dta.tab.monthly.cost$`Mean Total Monthly Cost 2016`[3] <- mean(upgrades.pop.cost$ia_monthly_cost_total_2016, na.rm=T)
dta.tab.monthly.cost$`Median Total Monthly Cost 2016`[3] <- median(upgrades.pop.cost$ia_monthly_cost_total_2016, na.rm=T)

## round
dta.tab.monthly.cost[,c(2:5)] <- round(dta.tab.monthly.cost[,c(2:5)], 2)
write.csv(dta.tab.monthly.cost, "../data/table_total_monthly_cost_upgrade_vs_no_upgrade.csv", row.names=F)

## no statistically significant difference
t.test(upgrades.pop.cost$ia_monthly_cost_total_2015, upgrades.cost$ia_monthly_cost_total_2015)
upgrades.pop.cost$upgrade.bin <- as.numeric(upgrades.pop.cost$upgrade)
## run a logit regression -- not significant
mylogit <- glm(upgrade.bin ~ ia_monthly_cost_total_2015, data = upgrades.pop.cost, family = "binomial")
summary(mylogit)


## PLOT the distribution of starting total monthly cost
## collect just upgrades
up_total_monthly_cost_2015 <- upgrades.pop.cost$ia_monthly_cost_total_2015
## take out NA values
up_total_monthly_cost_2015 <- up_total_monthly_cost_2015[!is.na(up_total_monthly_cost_2015)]
## cap at the 90th percentile (take out outliers)
quantile(upgrades.cost$ia_monthly_cost_total_2015, na.rm=T, seq(0,1,by=0.1))
up_total_monthly_cost_2015 <- up_total_monthly_cost_2015[which(up_total_monthly_cost_2015 <= 10000)]

## collect for all population
total_monthly_cost_2015 <- upgrades.pop.cost$ia_monthly_cost_total_2015
## take out NA values
total_monthly_cost_2015 <- total_monthly_cost_2015[!is.na(total_monthly_cost_2015)]
## cap at the 90th percentile (take out outliers)
quantile(upgrades.pop.cost$ia_monthly_cost_total_2015, na.rm=T, seq(0,1,by=0.1))
total_monthly_cost_2015 <- total_monthly_cost_2015[which(total_monthly_cost_2015 <= 10000)]

pdf("../figures/distribution_of_upgraders_starting_monthly_cost.pdf", height=5, width=10)
## set histogram breaks
breaks <- seq(0, 10000, by = 500)
layout(matrix(c(1,2), nrow=1, ncol=2, byrow = TRUE))
par(mar=c(3,3,2,1), mgp=c(1.5,0.5,0))
## plot just upgrades
hist(up_total_monthly_cost_2015, breaks=breaks, include.lowest=TRUE, main="Upgrades", xlab="Total Monthly Cost 2015", 
     col=rgb(0,0,0,0.6), border=F)
## plot for all districts
hist(total_monthly_cost_2015, breaks=breaks, include.lowest=TRUE, main="All", xlab="", ylab="",
     col=rgb(0,0,0,0.6), border=F)
dev.off()


## density plot
pdf("../figures/density_of_upgraders_starting_monthly_cost.pdf", height=5, width=10)
## set histogram breaks
breaks <- seq(0, 70, by = 5)
layout(matrix(c(1,2), nrow=1, ncol=2, byrow = TRUE))
par(mar=c(3,3,2,1), mgp=c(1.5,0.5,0))
d1 <- density(up_total_monthly_cost_2015)
plot(d1, type="n", main="Upgrades", xlab="Cost per Mbps 2015")
polygon(d1, col=rgb(1,0,0,0.6), border=rgb(0,0,0,0.6))
d2 <- density(total_monthly_cost_2015)
plot(d2, type="n", main="All", xlab="", ylab="")
polygon(d2, col=rgb(1,0,0,0.6), border=rgb(0,0,0,0.6))
dev.off()


## COST PER MBPS
cost_per_mbps_2015 <- upgrades.pop.cost$ia_monthly_cost_per_mbps_2015
up_cost_per_mbps_2015 <- upgrades.cost$ia_monthly_cost_per_mbps_2015

## create dataset to collect the reported numbers below:
dta.tab.cost.mbps <- data.frame(matrix(NA, nrow=3, ncol=9))
dta.tab.cost.mbps[,1] <- c('Upgraders', 'Non-Upgraders', 'All')
names(dta.tab.cost.mbps) <- c('', 'Mean Monthly Cost per mbps 2015', 'Mean Monthly Cost per mbps 2016',
                                 'Median Monthly Cost per mbps 2015', 'Median Monthly Cost per mbps 2016',
                              'Weighted Average Monthly Cost per mbps 2015', 'Weighted Average Monthly Cost per mbps 2016',
                              'Mean Bandwidth 2015', 'Mean Bandwidth 2016')

## Upgraders
## 2015
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2015`[1] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2015`[1] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## in Ultimate Master: $10.09
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2015`[1] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## in Ultimate Master: 449 mbps
dta.tab.cost.mbps$`Mean Bandwidth 2015`[1] <- mean(upgrades.pop.cost$total_ia_bw_2015[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## 2016
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2016`[1] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2016`[1] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## in Ultimate Master: $3.57
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2016`[1] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)
## in Ultimate Master: 1,363 mbps
dta.tab.cost.mbps$`Mean Bandwidth 2016`[1] <- mean(upgrades.pop.cost$total_ia_bw_2016[which(upgrades.pop.cost$upgrade == TRUE)], na.rm=T)

## Non-Upgraders
## 2015
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2015`[2] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2015`[2] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## in Ultimate Master: $5.01
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2015`[2] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## in Ultimate Master: 831 mbps
dta.tab.cost.mbps$`Mean Bandwidth 2015`[2] <- mean(upgrades.pop.cost$total_ia_bw_2015[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## 2016
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2016`[2] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2016`[2] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## in Ultimate Master: $4.74
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2016`[2] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)
## in Ultimate Master: 706 mbps
dta.tab.cost.mbps$`Mean Bandwidth 2016`[2] <- mean(upgrades.pop.cost$total_ia_bw_2016[which(upgrades.pop.cost$upgrade == FALSE)], na.rm=T)

## Total Population
## 2015
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2015`[3] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015, na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2015`[3] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015, na.rm=T)
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2015`[3] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2015, na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2015, na.rm=T)
dta.tab.cost.mbps$`Mean Bandwidth 2015`[3] <- mean(upgrades.pop.cost$total_ia_bw_2015, na.rm=T)
## 2016
dta.tab.cost.mbps$`Mean Monthly Cost per mbps 2016`[3] <- mean(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016, na.rm=T)
dta.tab.cost.mbps$`Median Monthly Cost per mbps 2016`[3] <- median(upgrades.pop.cost$ia_monthly_cost_per_mbps_2016, na.rm=T)
dta.tab.cost.mbps$`Weighted Average Monthly Cost per mbps 2016`[3] <- sum(upgrades.pop.cost$ia_monthly_cost_total_2016, na.rm=T) / sum(upgrades.pop.cost$total_ia_bw_2016, na.rm=T)
dta.tab.cost.mbps$`Mean Bandwidth 2016`[3] <- mean(upgrades.pop.cost$total_ia_bw_2016, na.rm=T)

## round
dta.tab.cost.mbps[,c(2:9)] <- round(dta.tab.cost.mbps[,c(2:9)], 2)
write.csv(dta.tab.cost.mbps, "../data/table_monthly_cost_per_mbps_upgrade_vs_no_upgrade.csv", row.names=F)


## statistically signficant difference -- p-value = 0.01
t.test(cost_per_mbps_2015, up_cost_per_mbps_2015)

## run a logit regression -- significant
## take out infinite and NA values
upgrades.pop.cost$upgrade.bin <- as.numeric(upgrades.pop.cost$upgrade)
mylogit <- glm(upgrade.bin ~ ia_monthly_cost_per_mbps_2015, data = upgrades.pop.cost, family = "binomial")
summary(mylogit)

## PLOT the distribution of starting total monthly cost
## cap at the 90th percentile (take out outliers)
quantile(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015, na.rm=T, seq(0,1,by=0.1))
cost_per_mbps_2015 <- cost_per_mbps_2015[which(cost_per_mbps_2015 <= 52)]

quantile(upgrades.pop.cost$ia_monthly_cost_per_mbps_2015[upgrades.pop.cost$upgrade == TRUE], na.rm=T, seq(0,1,by=0.1))
up_cost_per_mbps_2015 <- up_cost_per_mbps_2015[which(up_cost_per_mbps_2015 <= 70)]

pdf("../figures/distribution_of_upgraders_starting_cost_per_mbps.pdf", height=5, width=10)
## set histogram breaks
breaks <- seq(0, 70, by = 5)
layout(matrix(c(1,2), nrow=1, ncol=2, byrow = TRUE))
par(mar=c(3,3,2,1), mgp=c(1.5,0.5,0))
## plot just upgrades
hist(up_cost_per_mbps_2015, breaks=breaks, include.lowest=TRUE, main="Upgrades", xlab="Cost per Mbps 2015", 
     col=rgb(0,0,0,0.6), border=F)
## plot for all districts
hist(cost_per_mbps_2015, breaks=breaks, include.lowest=TRUE, main="All", xlab="", ylab="",
     col=rgb(0,0,0,0.6), border=F)
dev.off()

## density plot
pdf("../figures/density_of_upgraders_starting_cost_per_mbps.pdf", height=5, width=10)
## set histogram breaks
breaks <- seq(0, 70, by = 5)
layout(matrix(c(1,2), nrow=1, ncol=2, byrow = TRUE))
par(mar=c(3,3,2,1), mgp=c(1.5,0.5,0))
d1 <- density(up_cost_per_mbps_2015)
plot(d1, type="n", main="Upgrades", xlab="Cost per Mbps 2015", xlim=c(0,70))
polygon(d1, col=rgb(1,0,0,0.6), border=rgb(0,0,0,0.6))
d2 <- density(cost_per_mbps_2015)
plot(d2, type="n", main="All", xlab="", ylab="", xlim=c(0,70))
polygon(d2, col=rgb(1,0,0,0.6), border=rgb(0,0,0,0.6))
dev.off()

##===================================================================================================================================
## 7) MID-CONTRACT EXPIRATION QA

## create indicator for contract expiring in 2016
dd.2015$contract_expiration_2016 <- ifelse(dd.2015$most_recent_ia_contract_end_date >= "2016-01-01" &
                                             dd.2015$most_recent_ia_contract_end_date < "2017-01-01", 1, 0)

## merge in the contract end date into upgrades
upgrades <- merge(upgrades, dd.2015[,c('esh_id', 'contract_expiration_2016')], by='esh_id', all.x=T)
upgrades.contract <- upgrades[!is.na(upgrades$contract_expiration_2016),]


## % districts upgrades that do not have contract expiring in 2016 ('mid-contract')
table(upgrades.contract$contract_expiration_2016)
round(nrow(upgrades.contract[upgrades.contract$contract_expiration_2016 == 0,]) / nrow(upgrades.contract), 2)

## Expiring Contracts
upgrades.contract.expire <- upgrades.contract[upgrades.contract$contract_expiration_2016 == 1,]
## Non-weighted Avg/Median Percent Change in Cost for Upgrade Districts that have contract expiring in 2016
## take out AK for cost analysis
upgrades.contract.expire.cost <- upgrades.contract.expire[upgrades.contract.expire$postal_cd != 'AK',]
## take out NA and Infinite
upgrades.contract.expire.cost <- upgrades.contract.expire.cost[!is.na(upgrades.contract.expire.cost$perc.cost.change) &
                                                            !is.infinite(upgrades.contract.expire.cost$perc.cost.change),]
round(mean(upgrades.contract.expire.cost$perc.cost.change, na.rm=T), 2)
round(median(upgrades.contract.expire.cost$perc.cost.change, na.rm=T), 2)

## Non-weighted Avg/Median Change in BW for Upgrade Districts that have contract expiring in 2016
round(mean(upgrades.contract.expire.cost$perc.bw, na.rm=T), 2)
round(median(upgrades.contract.expire.cost$perc.bw, na.rm=T), 2)

## Mid-Contracts
## Non-weighted Avg/Median Change in Cost for Upgrade Districts that do not have contract expiring in 2016 ('mid-contract')
upgrades.contract.no.expire <- upgrades.contract[upgrades.contract$contract_expiration_2016 == 0,]
## take out AK for cost analysis
upgrades.contract.no.expire.cost <- upgrades.contract.no.expire[upgrades.contract.no.expire$postal_cd != 'AK',]
## take out NA and Infinite
upgrades.contract.no.expire.cost <- upgrades.contract.no.expire.cost[!is.na(upgrades.contract.no.expire.cost$perc.cost.change) &
                                                                 !is.infinite(upgrades.contract.no.expire.cost$perc.cost.change),]
round(mean(upgrades.contract.no.expire.cost$perc.cost.change, na.rm=T), 2)
round(median(upgrades.contract.no.expire.cost$perc.cost.change, na.rm=T), 2)

## Non-weighted Avg/Median Change in BW for Upgrade Districts that do not have contract expiring in 2016 ('mid-contract')
round(mean(upgrades.contract.no.expire.cost$perc.bw, na.rm=T), 2)
round(median(upgrades.contract.no.expire.cost$perc.bw, na.rm=T), 2)

