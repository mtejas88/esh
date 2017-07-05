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

contracts <- read.csv("data/raw/contracts.csv", as.is=T, header=T, stringsAsFactors=F)
head(contracts)

na_contract <- filter(contracts, is.na(contract_end_date)) %>% nrow()
na_expiry <- filter(contracts, is.na(expiration_date)) %>% nrow()

paste('There are', na_contract, 'FRNs with a null contract end date')
paste('There are', na_expiry, 'FRNs with a null expiration date')

contracts$contract_end_date_year <- substr(contracts$contract_end_date, 1, 4) %>% as.numeric()
contracts$expiry_end_date_year <- substr(contracts$expiration_date, 1, 4) %>% as.numeric()
contracts$same_year <- contracts$contract_end_date_year == contracts$expiry_end_date_year

#visualizing and removing outliers
summary(contracts$contract_end_date_year)
ggplot(contracts, aes(x = factor(0), contract_end_date_year)) + geom_boxplot() + coord_flip()
ggplot(contracts, aes(x = factor(0), expiry_end_date_year)) + geom_boxplot() + coord_flip()

#assuming anything above 2050 is an outlier
num_outliers_contract <- filter(contracts, contract_end_date_year > 2050) %>% nrow()
num_outliers_expiry <- filter(contracts, expiry_end_date_year > 2050) %>% nrow()
contracts <- filter(contracts, contract_end_date_year <= 2050)
summary(contracts$expiry_end_date_year)
contracts <- filter(contracts, expiry_end_date_year <= 2050 | is.na(expiry_end_date_year))

contracts2 <- contracts[!is.na(contracts$expiration_date),]
head(contracts2)

pdf('figures/same_year.pdf', width = 11, height = 8)
ggplot(contracts2, aes(same_year)) + 
  geom_bar(fill = '#fcd56a') + 
  geom_text(stat = 'count', aes(label = ..count..), size = 3.7, position = position_stack(vjust = .5)) +
  labs(x = '', y = 'number of FRNs', title = 'Contract ending year matched expiration ending year')
dev.off()

ggplot(contracts2, aes(contract_end_date_year)) + geom_bar()
ggplot(contracts2, aes(expiry_end_date_year)) + geom_bar()

pdf('figures/contract_histogram.pdf', width = 11, height = 8)
ggplot(contracts, aes(contract_end_date_year)) + 
  geom_bar(fill = '#fcd56a') + 
  labs(x = 'Year', y = 'number of FRNs', title = 'Contract End Date Year')
dev.off()

pdf('figures/comparison_histogram.pdf', width = 11, height = 8)
ggplot(contracts2, aes(expiry_minus_contract)) + 
  geom_histogram(binwidth = 365, fill = '#fcd56a') + 
  labs(x = 'Difference in Days (Expiration - Contract)', y = 'number of FRNs', title = 'Comparing Expiration Date to Contract End Date')
dev.off()

contracts2$comparing_dates_adj <- ifelse(contracts2$comparing_dates == 'contract end date is earlier than expiration date',
                                         'contract < expiry',
                                         ifelse(contracts2$comparing_dates == 'same dates',
                                                'contract = expiry',
                                                'contract > expiry'
                                                )
                                         )

pdf('figures/contract_expiry_summary_diff.pdf', width = 11, height = 8)
ggplot(contracts2, aes(comparing_dates_adj)) + 
  geom_bar(fill = '#fcd56a') + 
  geom_text(stat = 'count', aes(label = ..count..), size = 3.7, position = position_stack(vjust = .5)) +
  labs(x = '', y = 'number of FRNs', title = 'Summary of Contract vs. Expiration Date')
dev.off()
