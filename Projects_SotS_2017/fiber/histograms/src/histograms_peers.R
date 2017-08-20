## =========================================
##
## Create histograms
##
## =========================================

## Clearing memory
rm(list=ls())

## set working directory
setwd("C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects_SotS_2017/fiber/histograms/")

## load packages (if not already in the environment)
packages.to.install <- c("dplyr", "ggplot2", "reshape2", "plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(plyr)
library(ggplot2)
library(reshape2)


##import and filter
districts_not_meeting_goals <- read.csv("data/districts_not_meeting_goals.csv")
districts_with_state_peers <- filter(districts_not_meeting_goals, diagnosis == 'meet the prices available in your state') 


##histogram of prices
p.prices <- ggplot(districts_with_state_peers, aes(num_prices_to_meet_goals_with_same_budget))
p.prices + geom_histogram(binwidth=2, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of price examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),100,150))+ 
  geom_vline(xintercept = median(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts_with_state_peers$num_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
             )+ 
  annotate("text", x = 60, y = 25, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but \ncould with peer pricing")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))


##histogram of districts
p.districts <- ggplot(districts_with_state_peers, aes(num_districts_w_prices_to_meet_goals_with_same_budget))
p.districts + geom_histogram(binwidth=2.5, fill="#009296")+
  ylab("Number of districts")+
  xlab("Number of districts with examples in state")+
  scale_x_continuous(breaks = c(unname(quantile(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.5,.75))),200,300))+ 
  geom_vline(xintercept = median(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget), color = 'black', linetype="dashed", size = 1.5)+ 
  geom_vline(xintercept = quantile(districts_with_state_peers$num_districts_w_prices_to_meet_goals_with_same_budget, c(.25,.75)), color = 'black', linetype="dashed", size = .5
  )+ 
  annotate("text", x = 120, y = 15, label = "quantiles", color = 'black')+
  ggtitle("Districts not meeting goals but \ncould with peer pricing")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))

##histogram of contract end time
p.contract <- ggplot(districts_not_meeting_goals, aes(contract_end_time))
p.contract + geom_histogram(binwidth=1, fill="#009296")+
  ylab("Number of districts")+
  xlab("Years until contract end of soonest expiring internet contract")+
  scale_x_continuous(breaks = c(1,2,3,4,5,6,7))+ 
  geom_text(aes( label = scales::percent(..prop..),
                 y= ..prop.. ), stat= "count", vjust = -.5)+
  ggtitle("Districts not meeting goals")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))



##from https://github.com/educationsuperhighway/ficher/blob/new_scalable/Projects_SotS_2017/students_not_meeting_categorized.sql
##from https://github.com/educationsuperhighway/ficher/blob/new_scalable/Projects_SotS_2017/affordability/oop_per_student_meeting_not_meeting.sql
n = c(.17, .24, .52, .55) 
cat = c('spend more $', 'not meeting goals', 'all districts', 'meeting goals') 
df = data.frame(n, cat)
df

##bar chart for cost/student
p.cost.student <- ggplot(df, aes(cat))
p.cost.student + geom_bar(aes(weight = n), fill="#009296")+
  ylab("Monthly OOP spend per student")+
  xlab("")+
  ggtitle("$/student by category")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))+
  coord_flip()+
  geom_text(aes( label = paste('$',n),
                 y= n, hjust= 1.1 ), color = 'white')

##from https://github.com/educationsuperhighway/ficher/blob/new_scalable/Projects_SotS_2017/unscalable_campuses_with_state_match_frequency.sql
match = c(.04, .03, .06, .08, .14, .04) 
pending = c(.01, .04, .06, .15, .20, .16) 
dr = c('40%', '50%', '60%', '70%', '80%', '90%') 
df2 = data.frame(pending, match, dr)
df2 <- melt(df2, id.var="dr")
df2

##bar chart for discounts
p.discounts <- ggplot(df2, aes(x=dr, y=value, fill=variable)) +
  geom_bar(stat="identity")+
  scale_fill_manual(values = c('grey','#009296') )+
  ylab("% unscalable campuses with state match")+
  xlab("")+
  ggtitle("Campuses needing fiber with \nstate match by discount")+ 
  theme(plot.title = element_text(size = 30, face = "bold")) +
  annotate("text", x = 3, y = .3, label = "54% of campuses including pending have free fiber builds", color = 'black')+
  annotate("text", x = 3, y = .28, label = "45% of campuses excluding pending have free fiber builds", color = 'black')+
  geom_text(aes(label = paste0(sprintf("%.0f", value*100), "%")), position = position_stack(vjust = 0.5), size = 4, color = 'white')
p.discounts


medians <- districts_with_state_peers %>% 
  group_by(postal_cd) %>% 
  summarise(median = median(num_districts_w_prices_to_meet_goals_with_same_budget, na.rm = TRUE),
            count = n())

##plot of medians
p.medians <- ggplot(medians, aes(postal_cd))
p.medians + geom_bar(aes(weight = median), fill="#009296")+
  ylab("Median Num District Peers")+
  xlab("")+
  ggtitle("District peers by state")+ 
  theme(plot.title = element_text(size = 30, face = "bold"))+
  coord_flip()

