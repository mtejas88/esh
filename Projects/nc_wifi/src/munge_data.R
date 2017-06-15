## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

# installing packages
library(dplyr)
library(ggplot2)
library(tidyr)

##**************************************************************************************************************************************************
## READ IN DATA AND CLEANING DATA
sw <- read.csv('data/raw/school_wifi.csv', as.is = T, header = T, stringsAsFactors = F)
cmtd_wifi <- read.csv('data/raw/cmtd_wifi.csv', as.is = T, header = T, stringsAsFactors = F)
source('../../General_Resources/common_functions/correct_dataset.R')
sw <- correct.dataset(sw, 0 , 0)
cmtd_wifi <- correct.dataset(cmtd_wifi, 0, 0)

colnames(sw)

#removing schools with no BEN because they don't have a budget
sw <- sw[!is.na(sw$ben),]

#number of schools in NC with a BEN
num_schools <- nrow(sw)

#converting remaining c2 2017 to numeric
sw$budget_remaining_c2_2017 <- sw$budget_remaining_c2_2017 %>% as.numeric()
sw$budget_remaining_c2_2017_postdiscount <- sw$budget_remaining_c2_2017_postdiscount %>% as.numeric()

##**************************************************************************************************************************************************
##CREATING FIRST PLOT (% REMAINING)

#creating percent remaining
sw$budget_remaining_17_percent <- sw$budget_remaining_c2_2017 / sw$c2_budget

#visualizing percent remaining
summary(sw$budget_remaining_17_percent)

#creating percent remaining bins to match Ray's work from NC
sw$remaining_bin <- ifelse(sw$budget_remaining_17_percent < .1,
                           '0% to 9%',
                           ifelse(sw$budget_remaining_17_percent < .2,
                                  '10% to 19%',
                                  ifelse(sw$budget_remaining_17_percent < .3,
                                         '20% to 29%',
                                         ifelse(sw$budget_remaining_17_percent < .4,
                                                '30% to 39%',
                                                ifelse(sw$budget_remaining_17_percent < .5,
                                                       '40% to 49%',
                                                       ifelse(sw$budget_remaining_17_percent < .6,
                                                              '50% to 59%',
                                                              ifelse(sw$budget_remaining_17_percent < .7,
                                                                     '60% to 69%',
                                                                     ifelse(sw$budget_remaining_17_percent < .8,
                                                                            '70% to 79%',
                                                                            ifelse(sw$budget_remaining_17_percent < .9,
                                                                                   '80% to 89%',
                                                                                   ifelse(sw$budget_remaining_17_percent < 1,
                                                                                          '90% to 99%',
                                                                                          '100%'
                                                                                   )
                                                                            )
                                                                     )
                                                              )
                                                       )
                                                )
                                         )
                                  )
                           )
)
                                  
#visualizing bins
table(sw$remaining_bin)

#setting up a 'remaining' df to plot
remaining <- group_by(sw, remaining_bin) %>%
  summarise(num_schools = n())
remaining$remaining_bin <- factor(remaining$remaining_bin, 
                                  levels = c('0% to 9%', '10% to 19%', '20% to 29%', '30% to 39%',
                                             '40% to 49%', '50% to 59%', '60% to 69%', '70% to 79%',
                                             '80% to 89%', '90% to 99%', '100%'))
remaining <- remaining[order(remaining$remaining_bin),]

theme_esh <- function(){
  theme(
    text = element_text(color="#666666", size=13),
    panel.grid.major = element_line(color = "light grey"),
    panel.grid.major.x = element_blank(),
    panel.background = element_rect(fill = "white")
  )
}

# creating plot
png('figures/schools_percent_remaining.png', width = 750, height = 500)
ggplot(remaining, aes(x = remaining_bin, y = num_schools, label = paste(num_schools))) + 
  geom_bar(stat="identity", fill = '#f09222')  + 
  geom_text(size = 3.7, position = position_stack(vjust = 0.5)) + 
  ggtitle('Number of Schools by Budget Remaining') +
  labs(x = 'Budget Remaining', y = 'Number of Schools') +
  theme_esh()
dev.off()

##**************************************************************************************************************************************************
##CREATING SECOND PLOT ($ REMAINING)

#remiaining dollars
remaining_budget <- sum(sw$budget_remaining_c2_2017)

#creating percent remaining bins to match Ray's work from NC
sw$remaining_dollars_bin <- ifelse(sw$budget_remaining_c2_2017 <= 0,
                           'None',
                           ifelse(sw$budget_remaining_c2_2017 < 1000,
                                  '1 to 999',
                                  ifelse(sw$budget_remaining_c2_2017 < 5000,
                                         '1,000 to 5K',
                                         ifelse(sw$budget_remaining_c2_2017 < 25000,
                                                '5K to 25K',
                                                ifelse(sw$budget_remaining_c2_2017 < 50000,
                                                       '25K - 50K',
                                                       ifelse(sw$budget_remaining_c2_2017 < 100000,
                                                              '50K - 100K',
                                                              ifelse(sw$budget_remaining_c2_2017 < 200000,
                                                                     '100K - 200K',
                                                                     ifelse(sw$budget_remaining_c2_2017 < 300000,
                                                                            '200K - 300K',
                                                                            ifelse(sw$budget_remaining_c2_2017 < 400000,
                                                                                   '300K - 400K',
                                                                                   'Over 400K'
                                                                            )
                                                                     )
                                                              )
                                                       )
                                                )
                                         )
                                  )
                           )
)
table(sw$remaining_dollars_bin)

remaining_dollars <- group_by(sw, remaining_dollars_bin) %>%
  summarise(num_schools = n())

remaining_dollars$remaining_dollars_bin <- factor(remaining_dollars$remaining_dollars_bin, 
                                  levels = c('None', '1 to 999', '1,000 to 5K',
                                             '5K to 25K', '25K - 50K', '50K - 100K', '100K - 200K',
                                             '200K - 300K', '300K - 400K', 'Over 400K'))

remaining_dollars <- remaining_dollars[order(remaining_dollars$remaining_dollars_bin),]

# creating plot
png('figures/schools_dollars_remaining.png', width = 750, height = 500)
ggplot(remaining_dollars, aes(x = remaining_dollars_bin, y = num_schools, label = paste(num_schools))) + 
  geom_bar(stat="identity", fill = '#f09222')  + 
  geom_text(size = 3.7, position = position_stack(vjust = 0.5)) + 
  ggtitle('Number of Schools by Budget Remaining in Dollars') +
  labs(x = 'Budget Remaining', y = 'Number of Schools') +
  theme_esh()
dev.off()

##**************************************************************************************************************************************************
##CREATING THIRD PLOT ($ 15-17)
colnames(sw)

sw$pre_discount_spent <- sw$c2_budget - sw$budget_remaining_c2_2017
summary(sw$pre_discount_spent)
sw$post_discount_spent <- sw$c2_budget_postdiscount - sw$budget_remaining_c2_2017_postdiscount
summary(sw$post_discount_spent)

head(cmtd_wifi)

cmtd_wifi <- select(cmtd_wifi, school_esh_id, remaining_after_cmtd = budget_remaining_c2_2017_postdiscount)

sw <- merge(x = sw, y = cmtd_wifi, by = 'school_esh_id')
sw$post_discount_cmtd <- sw$c2_budget_postdiscount - sw$remaining_after_cmtd
sw$post_discount_pending <- sw$post_discount_spent - sw$post_discount_cmtd

table(sw$c2_discount_rate)
sw$discount_bin <- ifelse(sw$c2_discount_rate < 0.5,
                                   '40% - 49%',
                                   ifelse(sw$c2_discount_rate < 0.6,
                                          '50% - 59%',
                                          ifelse(sw$c2_discount_rate < 0.7,
                                                 '60% - 69%',
                                                 ifelse(sw$c2_discount_rate < 0.8,
                                                        '70% - 79%',
                                                        ifelse(sw$c2_discount_rate < 0.9,
                                                               '80% - 89%',
                                                               NA
                                                        )
                                                 )
                                          )
                                   )
)

cmtd <- select(sw,  discount_bin, pre_discount_spent, post_discount_spent, post_discount_cmtd, post_discount_pending)

cmtd <- group_by(cmtd, discount_bin) %>%
  summarise(a = sum(pre_discount_spent),
            b = sum(post_discount_spent),
            c = sum(post_discount_cmtd),
            d = sum(post_discount_pending))

colnames(cmtd) <- c('discount_bin', 'Pre_discount', 'Requested', 'Committed', 'Pending')
cmtd <- gather(cmtd, status, dollars, Pre_discount,Requested,Committed,Pending)

png('figures/cat2_dollars.png', width = 750, height = 500)
ggplot(cmtd, aes(discount_bin, dollars)) + 
  geom_point(aes(color = status), size = 5) + 
  ggtitle('CAT2 Since Modernization (2015-17)') +
  labs(x = 'Discount Rate', y = 'Dollars') +
  theme_esh()
dev.off()
