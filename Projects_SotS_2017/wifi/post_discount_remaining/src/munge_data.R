## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())
library(dplyr)
library(ggplot2)
library(tidyr)

##**************************************************************************************************************************************************
## read in data

remaining.wifi <- read.csv("data/raw/remaining_wifi.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
districts.remaining.wifi <- read.csv("data/raw/districts_remaining_wifi.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
receives.services <- read.csv("data/raw/receives_services.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
c1.spend <- read.csv("data/raw/c1_spend.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
wifi.and.upgrades <- read.csv("data/raw/wifi_and_upgrades.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
source('../../../General_Resources/common_functions/correct_dataset.R')
districts.remaining.wifi <- correct.dataset(districts.remaining.wifi, 0 , 0)
receives.services <- correct.dataset(receives.services, 0 , 0)
wifi.and.upgrades <- correct.dataset(wifi.and.upgrades, 0 , 0)
head(remaining.wifi)

##Districts upgrades


##POST BUDGET ANALYSIS
starting.post <- sum(remaining.wifi$post_budget)
remaining.15.post <- sum(remaining.wifi$budget_remaining_c2_2015_postdiscount)
remaining.16.post <- sum(remaining.wifi$budget_remaining_c2_2016_postdiscount)
remaining.17.post <- sum(remaining.wifi$budget_remaining_c2_2017_postdiscount)

#DISTRICTS SPENT $0
remaining.wifi.no.spend <- subset(remaining.wifi, post_budget == budget_remaining_c2_2017_postdiscount)
table(remaining.wifi.no.spend$locale)
no.spend.size <- table(remaining.wifi.no.spend$district_size) %>% data.frame()
no.spend.size$Var1 <- factor(no.spend.size$Var1, levels = c('Tiny', 'Small', 'Medium', 'Large', 'Mega'))

#districts spent $0 by size
ggplot(no.spend.size, aes(Var1, Freq)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  labs(x = '', y = 'num districts', title = 'Districts Spent $0 by Size')

#districts spent $0 by locale
ggplot(table(remaining.wifi.no.spend$locale) %>% data.frame(), aes(Var1, Freq)) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  labs(x = '', y = 'num districts', title = 'Districts Spent $0 by Locale')

paste(sum(remaining.wifi.no.spend$num_students), 'students are in districts that have not spent any of their C2 $')
remaining.wifi.no.spend.svcs <- remaining.wifi.no.spend
remaining.wifi.no.spend.svcs <- filter(remaining.wifi.no.spend.svcs, esh_id %in% receives.services$recipient_id)
paste('and ', sum(remaining.wifi.no.spend.svcs$num_students), ' of those students do receive some C1 E-rate services')

#histogram of funds remaining
pdf('figures/district_budget_remaining.pdf', width = 11, height = 8)
ggplot(remaining.wifi, aes(budget_remaining_c2_2017_postdiscount)) +
  geom_histogram(binwidth = 100000) +
  xlim(-100000,2000000) +
  labs(x = 'Budget Remaining 2017', y = 'Number of Districts', 
       title = 'Remaining C2 Budget Histogram',
       subtitle = 'Note: removed the 128 districts who each have over $2M left') +
  theme_bw() +
  theme(text = element_text(size = 12))

ggplot(remaining.wifi, aes(budget_remaining_c2_2017_postdiscount / post_budget)) +
  geom_histogram(binwidth = .05) +
  labs(x = '% Budget Remaining 2017', y = 'Number of Districts', 
       title = '% Remaining C2 Budget Histogram') +
  theme_bw() +
  theme(text = element_text(size = 12))
dev.off()


#joining in c1 spend to remaining wifi
remaining.wifi <- merge(remaining.wifi, c1.spend, by = 'esh_id', all.x = T)
head(remaining.wifi)
remaining.wifi$c2_spend_17 <- round(remaining.wifi$budget_remaining_c2_2016_postdiscount - remaining.wifi$budget_remaining_c2_2017_postdiscount, 0)
head(remaining.wifi$c2_spend_17)

#post budget df
post.df <- rbind(starting.post = sum(remaining.wifi$post_budget), 
                 remaining.15.post = sum(remaining.wifi$budget_remaining_c2_2015_postdiscount),
                 remaining.16.post = sum(remaining.wifi$budget_remaining_c2_2016_postdiscount),
                 remaining.17.post = sum(remaining.wifi$budget_remaining_c2_2017_postdiscount)) %>% as.data.frame()

names(post.df) <- c('C2_Funding')
post.df$group <- c('Starting Budget', 'Remaining 2015', 'Remaining 2016', 'Remaining 2017')
post.df$group <- factor(post.df$group, levels = c('Starting Budget', 'Remaining 2015', 'Remaining 2016', 'Remaining 2017'))

#by size
post.df.size <- group_by(remaining.wifi, district_size) %>% 
  summarise(remaining.17.post = sum(budget_remaining_c2_2017_postdiscount),
            num_districts = n(),
            num_students = sum(num_students),
            spent.17 = sum(budget_remaining_c2_2016_postdiscount) - sum(budget_remaining_c2_2017_postdiscount),
            spent.total = sum(post_budget) - sum(budget_remaining_c2_2017_postdiscount),
            starting.post = sum(post_budget),
            remaining.15.post = sum(budget_remaining_c2_2015_postdiscount),
            remaining.16.post = sum(budget_remaining_c2_2016_postdiscount),
            c1.spend.17 = sum(erate_c1_costs)) %>% as.data.frame()
post.df.size$district_size <- factor(post.df.size$district_size, levels = c('Tiny', 'Small', 'Medium', 'Large','Mega'))
post.df.size$remaining_budget_per_district <- round(post.df.size$remaining.17.post / post.df.size$num_districts, 0)
post.df.size$spent_17_per_district <- round(post.df.size$spent.17 / post.df.size$num_districts, 0)
post.df.size$spent_total_per_district <- round(post.df.size$spent.total / post.df.size$num_districts, 0)
post.df.size$remaining_budget_17_perc <- round(post.df.size$remaining.17.post/ 
                                                 (post.df.size$remaining.17.post + post.df.size$spent.total), 2)
post.df.size$c1.spend.17.per.student <- post.df.size$c1.spend.17 / post.df.size$num_students
post.df.size$c2.spend.17.per.student <- post.df.size$spent.17 / post.df.size$num_students

post.df.size.trend <- post.df.size[,c('district_size','starting.post','remaining.15.post', 'remaining.16.post', 'remaining.17.post')]
post.df.size.trend <- gather(post.df.size.trend, value, spend, 2:5)
post.df.size.trend$value <- factor(post.df.size.trend$value, levels = c('starting.post', 'remaining.15.post', 'remaining.16.post', 'remaining.17.post'))

#by locale
post.df.locale <- group_by(remaining.wifi, locale) %>% 
  summarise(remaining.17.post = sum(budget_remaining_c2_2017_postdiscount),
            num_districts = n(),
            spent.17 = sum(budget_remaining_c2_2016_postdiscount) - sum(budget_remaining_c2_2017_postdiscount)) %>% as.data.frame()
post.df.locale$locale <- factor(post.df.locale$locale, levels = c('Rural', 'Town', 'Suburban', 'Urban'))
post.df.locale$remaining_budget_per_district <- round(post.df.locale$remaining.17.post / post.df.locale$num_districts, 0)

#by locale and size
post.df.size.locale <- group_by(remaining.wifi, district_size, locale) %>% 
  summarise(remaining.17.post = sum(budget_remaining_c2_2017_postdiscount)) %>% as.data.frame()
post.df.size.locale$size.locale <- paste(post.df.size.locale$locale, post.df.size.locale$district_size)

#by discount rate
post.df.discount <- group_by(remaining.wifi, discount_rate_c2) %>% 
  summarise(remaining.17.post = sum(budget_remaining_c2_2017_postdiscount),
            num_districts = n(),
            spent.17 = sum(budget_remaining_c2_2016_postdiscount) - sum(budget_remaining_c2_2017_postdiscount),
            starting.post = sum(post_budget)) %>% as.data.frame()
post.df.discount$remaining_budget_per_district <- round(post.df.discount$remaining.17.post / post.df.discount$num_districts, 0)
post.df.discount$spent_17_per_district <- round(post.df.discount$spent.17 / post.df.discount$num_districts, 0)
post.df.discount$remaining_budget_17_percent <- round(post.df.discount$remaining.17.post / post.df.discount$starting.post, 2)

#budget remaining over time bars
ggplot(post.df, aes(group, C2_Funding, label = paste0('$',round(C2_Funding/1000000000,2),' B') )) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'E-rate funds available for C2 over time', subtitle = 'About 50% of C2 funds remain') +
  theme(axis.text = element_text(size = 10))

#budget remaining over time line
ggplot(post.df, aes(group, C2_Funding, group = 1 )) +
  geom_point() + geom_line() +
  scale_y_continuous(limits = c(0, 5000000000), labels = scales::comma) +
  labs(x = '', y = '', title = 'E-rate funds available for C2 over time') +
  theme(axis.text = element_text(size = 10)) +
  theme_classic()

#budget remaining by size over time
ggplot(post.df.size.trend, aes(value, spend, group = 1)) + geom_point(aes(color = factor(district_size)))

#budget remaining by size
ggplot(post.df.size, aes(district_size, remaining.17.post)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'Remaining C2 E-rate Funds by Size') +
  theme(axis.text = element_text(size = 10)) +
  theme_classic()

#budget remaining percent by size
ggplot(post.df.size, aes(district_size, remaining_budget_17_perc)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(limits = c(0,1), labels = scales::comma) +
  labs(x = '', y = '', title = '% Remaining C2 E-rate Funds by Size') +
  theme(axis.text = element_text(size = 10)) +
  theme_classic()

#budget remaining percent by discount rate
ggplot(post.df.discount, aes(factor(discount_rate_c2), remaining_budget_17_percent)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(limits = c(0,1), labels = scales::comma) +
  labs(x = '', y = '', title = '% Remaining C2 E-rate Funds by Discount Rate') +
  theme(axis.text = element_text(size = 10)) +
  theme_classic()

#budget spent 17 by size
ggplot(post.df.size, aes(district_size, spent.17)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'E-rate Funds Spent in 2017 by Size') +
  theme(axis.text = element_text(size = 10)) +
  theme_classic()

#budget remaining per district by size
ggplot(post.df.size, aes(district_size, remaining_budget_per_district, label = paste0('$',round(remaining_budget_per_district/1000000,2),' M'))) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = '', title = 'Avg. Remaining C2 E-rate Funds per District by Size') +
  theme(axis.text.x = element_text(size = 10),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank()) +
  theme_classic()

#budget remaining per district by discount rate
ggplot(post.df.discount, aes(factor(discount_rate_c2), remaining_budget_per_district, label = paste0('$',round(remaining_budget_per_district/1000,1),' K'))) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = '', title = 'Avg. Remaining C2 E-rate Funds per District by Discount Rate') +
  theme(axis.text.x = element_text(size = 10),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank()) +
  theme_classic()

#budget spent 17 per district by size
ggplot(post.df.size, aes(district_size, spent_17_per_district, label = paste0('$',round(spent_17_per_district/1000000,2),' M'))) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = '', title = 'Avg. E-rate Funds Spent in 2017 per District by Size') +
  theme(axis.text.x = element_text(size = 10),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank()) +
  theme_classic()

#budget remaining by locale
ggplot(post.df.locale, aes(locale, remaining.17.post)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'Remaining C2 E-rate Funds by Locale') +
  theme(axis.text = element_text(size = 10))

#budget remaining per district by locale
ggplot(post.df.locale, aes(locale, remaining_budget_per_district, label = paste0('$',round(remaining_budget_per_district/1000000,2),' M'))) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = '', title = 'Avg. Remaining C2 E-rate Funds per District by Locale') +
  theme(axis.text.x = element_text(size = 10),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank()) +
  theme_classic()

#erate c1 spend vs c2 spend by size
ggplot(post.df.size, aes(district_size, c1.spend.17/spent.17, label = paste0(round(c1.spend.17/spent.17, 1),'x'))) + 
  geom_bar(stat = 'identity', fill = '#fdb913') + 
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  labs(x = '', y = '', title = 'E-rate funding of C1 / C2 by district size') +
  theme_classic()

#size and locale.doesn't look good
ggplot(post.df.size.locale, aes(size.locale, remaining.17.post)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'Remaining C2 E-rate Funds by Size') +
  theme(axis.text = element_text(size = 8))

ggplot(post.df, aes(group, C2_Funding, label = paste0('$',round(C2_Funding/1000000000,2),' B') )) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'E-rate funds available for C2 over time', subtitle = 'About 50% of C2 funds remain') +
  theme(axis.text = element_text(size = 10))


remaining.df.17 <- group_by(remaining.wifi, postal_cd) %>% 
  summarize(remaining.17 = sum(remaining.17.post)) %>% as.data.frame()

remaining.df.17$rank <- rank(-remaining.df.17$remaining.17)
remaining.df.17$rank.group <- ifelse(remaining.df.17$rank <= 5, remaining.df.17$postal_cd, 'others')

remaining.df.17.rank <- group_by(remaining.df.17, rank.group) %>% 
  summarize(remaining.17 = sum(remaining.17)) %>% as.data.frame()

remaining.df.17.rank$rank.group <- factor(remaining.df.17.rank$rank.group, levels = c('CA', 'TX','NY','FL','OH','others'))

#not working right now - the states are gone
ggplot(remaining.df.17.rank, aes(rank.group, remaining.17, label = paste0('$',round(remaining.17/1000000,0),' M') )) + 
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(size = 5, position = position_stack(vjust = .5)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = '', y = 'C2 $', title = 'E-rate funds available for C2 by State', subtitle = 'Almost 40% of remaining C2 funds are in 5 states') +
  theme(axis.text = element_text(size = 10))


ggplot(remaining.df.17.rank, aes('', remaining.17, fill = rank.group)) + 
  geom_bar(stat = 'identity') +
  coord_polar("y", start = 0) +
  scale_fill_brewer(palette = 'Blues')
  

districts.remaining.wifi$e.bucket <- ifelse(districts.remaining.wifi$perc_spent_post >= 0.15 & districts.remaining.wifi$perc_spent_post <= 0.25,
                                            'Between 15-25%',
                                            'Not between 15-25%')
districts.remaining.wifi$e.bucket <- as.factor(districts.remaining.wifi$e.bucket)

pdf('figures/district_budget_spent.pdf', width = 11, height = 8)
ggplot(districts.remaining.wifi, aes(as.numeric(perc_spent_post))) + 
  geom_histogram(binwidth = .02, aes(fill = e.bucket)) +
  scale_fill_manual(values = c('red','grey')) +
  labs(x = 'Percent of Remaining Budget Spent in 2017', y = 'Number of Districts', fill = 'Bucket', 
       title = 'Most districts spent less than 5% of their remaining budget in 2017') +
  theme(text = element_text(size = 12))
dev.off()
