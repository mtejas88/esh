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

redundant.ia$cost.difference <- redundant.ia$redundant_monthly_cost - redundant.ia$national_median_cost_per_circuit_at_bw 
cost.difference.total <- round(sum(redundant.ia$cost.difference),0)

print(paste0('Their costs are ', round(cost.difference.total), ' more than the national median pricing in aggregate per month'))

redundant.ia$cost.difference.thirtieth <- redundant.ia$redundant_monthly_cost - redundant.ia$national_thirtieth_percentile_at_bw
cost.difference.total.thirtieth <- round(sum(redundant.ia$cost.difference.thirtieth),2)

print(paste0('Their costs are ', round(cost.difference.total.thirtieth), ' more than the national benchamrk pricing in aggregate (30th percentile) per month'))

##redundant.ia$med_cost_difference <- redundant.ia$cost_per_circuit - redundant.ia$median_cost_per_circuit
redundant.ia$med_cost_difference_perc <- redundant.ia$cost.difference / redundant.ia$redundant_monthly_cost %>% as.numeric()
##redundant.ia$thirtieth_cost_difference_circuit <- redundant.ia$cost_per_circuit - redundant.ia$thirtieth_percentile
redundant.ia$thirtieth_cost_difference_perc <- redundant.ia$cost.difference.thirtieth / redundant.ia$redundant_monthly_cost %>% as.numeric()

districts.affected.median <- filter(redundant.ia, med_cost_difference_perc > 0) %>% nrow()
districts.affected.thirthieth <- filter(redundant.ia, thirtieth_cost_difference_perc > 0) %>% nrow()

locale.redundant.ia <- group_by(redundant.ia, locale) %>%
  summarise(cost.difference = sum(cost.difference),
            cost.difference.thirtieth = sum(cost.difference.thirtieth))

pdf('figures/histogram.pdf', width = 7, height = 6)
ggplot(redundant.ia, aes(x = med_cost_difference_perc)) + 
  geom_histogram(bins = 20,fill = '#fdb913', alpha = 0.8) + 
  ggtitle("District redundant bw cost vs. national median") +
  labs(x = 'Cost Difference as % (cost - median) / cost', y = 'Number of Districts') +
  theme_grey()
dev.off()

pdf('figures/differnce_by_bandwidth.pdf', width = 7, height = 6)
ggplot(redundant.ia, aes(x = redundant_bw ,y = med_cost_difference_perc)) + 
  geom_point(color = '#fdb913', alpha = 0.5) + 
  ggtitle("District redundant bw cost vs. national median by bandwidth") +
  labs(x = 'Bandwidth in mbps', y = 'Cost Difference as % (cost - median) / cost') +
  theme_grey()
dev.off()

pdf('figures/dollars_by_locale.pdf', width = 7, height = 6)
ggplot(locale.redundant.ia, aes(x = locale, y = cost.difference, label = cost.difference)) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(aes(label = round(cost.difference,0)), vjust=-1) +
  ggtitle("Difference in district costs vs. national median") +
  labs(x = 'Locale', y = 'Total $ Difference (cost - median)') +
  theme_grey()
dev.off()

pdf('figures/histogram_thirtieth.pdf', width = 7, height = 6)
ggplot(redundant.ia, aes(x = thirtieth_cost_difference_perc)) + 
  geom_histogram(bins = 20,fill = '#fdb913', alpha = 0.8) + 
  ggtitle("District redundant bw cost vs. national benchmarks") +
  labs(x = 'Cost Difference as % (cost - 30th percentile) / cost', y = 'Number of Districts') +
  theme_grey()
dev.off()

pdf('figures/differnce_by_bandwidth_thirtieth.pdf', width = 7, height = 6)
ggplot(redundant.ia, aes(x = redundant_bw ,y = thirtieth_cost_difference_perc)) + 
  geom_point(color = '#fdb913', alpha = 0.5) + 
  ggtitle("District redundant bw cost vs. national benchmarks by bandwidth") +
  labs(x = 'Bandwidth in mbps', y = 'Cost Difference as % (cost - 30th percentile) / cost') +
  theme_grey()
dev.off()

pdf('figures/dollars_by_locale_thirtieth.pdf', width = 7, height = 6)
ggplot(locale.redundant.ia, aes(x = locale, y = cost.difference.thirtieth), label = cost.difference.thirtieth) +
  geom_bar(stat = 'identity', fill = '#fdb913') +
  geom_text(aes(label = round(cost.difference.thirtieth,0)), vjust=-1) +
  ggtitle("Difference in district costs vs. national benchmakrs") +
  labs(x = 'Locale', y = 'Total $ Difference (cost - 30th percentile)') +
  theme_grey()
dev.off()

