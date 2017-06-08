## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##load packaged
library(dplyr)
library(ggplot2)

##**************************************************************************************************************************************************
## READ IN DATA

redundant.ia <- read.csv("data/raw/redundant_ia.csv", as.is=T, header=T, stringsAsFactors=F)

num.districts <- unique(redundant.ia$recipient_id) %>% length()
print(paste0('There are ', num.districts, ' districts that have redundant circuits'))

redundant.ia$cost.difference <- redundant.ia$cost_per_circuit * redundant.ia$num_internet_lines - redundant.ia$median_cost_per_circuit * redundant.ia$num_internet_lines
cost.difference.total <- sum(redundant.ia$cost.difference)

print(paste0('Their circuit costs are only ', round(cost.difference.total), ' more than the national median pricing in aggregate'))

redundant.ia$med_cost_difference <- redundant.ia$cost_per_circuit - redundant.ia$median_cost_per_circuit
redundant.ia$med_cost_difference_perc <- redundant.ia$med_cost_difference / redundant.ia$cost_per_circuit %>% as.numeric()

locale.redundant.ia <- group_by(redundant.ia, locale) %>%
  summarise(cost.difference = sum(cost.difference))

pdf('figures/histogram.pdf', width = 7, height = 5)
ggplot(redundant.ia, aes(x = med_cost_difference_perc)) + 
  geom_histogram(bins = 20,fill = '#fdb913', alpha = 0.8) + 
  ggtitle("District circuit cost vs. national median") +
  labs(x = 'Cost Difference as % (cost - median) / cost', y = 'Number of Districts') +
  theme_grey()
dev.off()

pdf('figures/differnce_by_bandwidth.pdf', width = 7, height = 5)
ggplot(redundant.ia, aes(x = bandwidth_in_mbps ,y = med_cost_difference_perc)) + 
  geom_point(color = '#fdb913', alpha = 0.5) + 
  ggtitle("District circuit cost vs. national median by bandwidth") +
  labs(x = 'Bandwidth in mbps', y = 'Cost Difference as % (cost - median) / cost') +
  theme_grey()
dev.off()

pdf('figures/dollars_by_locale.pdf', width = 7, height = 5)
ggplot(locale.redundant.ia, aes(x = locale, y = cost.difference)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  ggtitle("Difference in district costs vs. national median") +
  labs(x = 'Locale', y = 'Total $ Difference (cost - median)') +
  theme_grey()
dev.off()
