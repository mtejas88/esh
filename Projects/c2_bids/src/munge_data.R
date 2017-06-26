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

##**************************************************************************************************************************************************
## READ IN DATA AND CLEANING DATA
c2_16 <- read.csv('data/raw/c2_bids_16.csv', as.is = T, header = T, stringsAsFactors = F)

source('../../General_Resources/common_functions/correct_dataset.R')
c2_16 <- correct.dataset(c2_16, 0 , 0)

#exploring num bids received
c2_16[is.na(c2_16$num_bids_received),] %>% nrow()
table(c2_16$num_bids_received)

#creating bids buckets
c2_16$bids_bucket <- ifelse(c2_16$num_bids_received == 0, '0',
                            ifelse(c2_16$num_bids_received == 1, '1',
                                   ifelse(c2_16$num_bids_received == 2, '2',
                                          '>2')))

bids_summary <- group_by(c2_16, bids_bucket) %>%
  summarise(count.frns = n())

bids_summary$bids_bucket <- bids_summary$bids_bucket %>% as.factor()
levels(bids_summary$bids_bucket) <- c('0','1','2','>2')

str(bids_summary)

pdf('figures/num_c2_bids.pdf')
ggplot(bids_summary, aes(x = bids_bucket, y = count.frns, label = count.frns)) + 
  geom_bar(stat = 'identity', fill = '#fcd56a') +
  geom_text(size = 3.7, position = position_stack(vjust = .5)) +
  labs(x = 'number of bids', y = 'count of FRNs', title = '2016 C2 FRNs by Number of Bids') +
  theme_bw()
dev.off()

bids_summary_contract <- group_by(c2_16, based_on_state_master_contract, bids_bucket) %>%
  summarise(count.frns = n())
bids_summary_contract$bids_bucket <- as.factor(bids_summary_contract$bids_bucket)
levels(bids_summary_contract$bids_bucket) <- c('0','1','2','>2')

pdf('figures/num_c2_bids_state_contract.pdf')
ggplot(bids_summary_contract, aes(x = bids_bucket, y = count.frns, label = count.frns)) +
  geom_bar(stat = 'identity', fill = '#fcd56a') +
  geom_text(size = 3.7, position = position_stack(vjust = 1)) +
  labs(x = 'number of bids', y = 'count of FRNs', title = '2016 C2 FRNs by Number of Bids and Part of State Master Contract') +
  facet_grid(. ~ based_on_state_master_contract)
dev.off()


qa.num_frns <- nrow(c2_16)
qa.num_frns

qa.num.bids <- sum(c2_16$num_bids_received)
qa.num.bids
