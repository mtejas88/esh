## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

rm(list=ls())
library(dplyr)
library(ggplot2)
#setwd('~/Documents/Analysis/ficher/Projects_SotS_2017/wifi/stratified_sample/')

##**************************************************************************************************************************************************
## read in data

all.wifi <- read.csv("data/raw/wifi_survey.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
dd <- read.csv("data/raw/dd.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
wifi_money <- read.csv("data/raw/wifi_money.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)
source('../../../General_Resources/common_functions/correct_dataset.R')
all.wifi <- correct.dataset(all.wifi, 0 , 0)
dd <- correct.dataset(dd, 0, 0)
wifi_money <- correct.dataset(wifi_money, 0, 0)

#list of non engaged states as of 7.18 from AZ
non.engaged <- c('AK', 'AL', 'AR', 'CT', 'DE', 'GA', 'HI', 'IA', 'ID', 'KY', 'ME', 'MI', 'MS',
                 'NC', 'ND', 'NE', 'PA', 'RI', 'SC', 'SD', 'TN', 'UT', 'VT', 'WV')

all.wifi$engaged_status <- ifelse(all.wifi$postal_cd %in% non.engaged, 'Non Engaged', 'Engaged')
dd$engaged_status <- ifelse(dd$postal_cd %in% non.engaged, 'Non Engaged', 'Engaged')

#some engaged states receiving survey (not exhaustive) as of 7.19 from AZ
engaged.states.survey <- c('NH', 'VA', 'CO')

all.wifi$receives_survey <- ifelse((all.wifi$engaged_status == 'Non Engaged' | all.wifi$postal_cd %in% engaged.states.survey) 
                                   & all.wifi$receives_survey == TRUE,
                                      'Yes',
                                      'No')

dd$receives_survey <- ifelse((dd$engaged_status == 'Non Engaged' | dd$postal_cd %in% engaged.states.survey) 
                             & dd$receives_survey == TRUE 
                             & dd$wifi_status != 'Other',
                                   'Yes',
                                   'No')

#dataframe for just the districts that will receive survey
receives.survey.df <- filter(all.wifi, receives_survey == 'Yes')

##**************************************************************************************************************************************************
## comparing all wifi districts we care about to wifi districts we care about who get survey

#all wifi districts - insert engaged vs nonengaged and other comparison
all.wifi.locale <- group_by(dd, locale) %>% summarise(total.count=n()) %>% as.data.frame()
all.wifi.locale$percent_districts <- round(all.wifi.locale$total.count / sum(all.wifi.locale$total.count),2) 
head(all.wifi.locale)
all.wifi.size <- group_by(dd, district_size) %>% summarise(total.count=n()) %>% as.data.frame()
all.wifi.size$percent_districts <- round(all.wifi.size$total.count / sum(all.wifi.size$total.count),2) 
head(all.wifi.size)
all.wifi.exclude.ia <- group_by(dd, exclude_from_ia_analysis) %>% summarise(total.count=n()) %>% as.data.frame()
all.wifi.exclude.ia$percent_districts <- round(all.wifi.exclude.ia$total.count / sum(all.wifi.exclude.ia$total.count),2) 
head(all.wifi.exclude.ia) 
all.wifi.engaged <- group_by(dd, engaged_status) %>% summarise(total.count = n()) %>% as.data.frame()
all.wifi.engaged$percent_districts <- round(all.wifi.engaged$total.count / sum(all.wifi.engaged$total.count),2) 
head(all.wifi.engaged)
all.wifi.sufficient <- group_by(dd, wifi_status) %>% summarise(total.count = n()) %>% as.data.frame()
all.wifi.sufficient$percent_districts <- round(all.wifi.sufficient$total.count / sum(all.wifi.sufficient$total.count),2) 
head(all.wifi.sufficient)
dd.wifi.suff <- group_by(dd, wifi_status) %>% summarise(total.count = n()) %>% as.data.frame()
dd.wifi.suff$percent_districts <- round(dd.wifi.suff$total.count / sum(dd.wifi.suff$total.count),2) 
head(dd.wifi.suff)



#wifi districts that receive survey - insert engaged vs nonengaged and other comparison
survey.wifi.locale <- group_by(receives.survey.df, locale) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.locale$percent_districts <- round(survey.wifi.locale$total.count / sum(survey.wifi.locale$total.count),2) 
head(survey.wifi.locale)
survey.wifi.size <- group_by(receives.survey.df, district_size) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.size$percent_districts <- round(survey.wifi.size$total.count / sum(survey.wifi.size$total.count),2) 
head(survey.wifi.size)
survey.wifi.exclude.ia <- group_by(receives.survey.df, exclude_from_ia_analysis) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.exclude.ia$percent_districts <- round(survey.wifi.exclude.ia$total.count / sum(survey.wifi.exclude.ia$total.count),2) 
head(survey.wifi.exclude.ia)
survey.wifi.engaged <- group_by(receives.survey.df, engaged_status) %>% summarise(total.count = n()) %>% as.data.frame()
survey.wifi.engaged$percent_districts <- round(survey.wifi.engaged$total.count / sum(survey.wifi.engaged$total.count),2) 
head(survey.wifi.engaged)
survey.wifi.sufficient <- group_by(receives.survey.df, wifi_status) %>% summarise(total.count = n()) %>% as.data.frame()
survey.wifi.sufficient$percent_districts <- round(survey.wifi.sufficient$total.count / sum(survey.wifi.sufficient$total.count),2) 
head(survey.wifi.sufficient)
dd.receive.wifi.suff <- group_by(dd[dd$receives_survey == 'Yes',], wifi_status) %>% summarise(total.count = n()) %>% as.data.frame()
dd.receive.wifi.suff$percent_districts <- round(dd.receive.wifi.suff$total.count / sum(dd.receive.wifi.suff$total.count),2) 
head(dd.receive.wifi.suff)

#locale comparison
all.wifi.locale$type <- 'all wifi'
survey.wifi.locale$type <- 'survey wifi'
locale.comp <- rbind(all.wifi.locale, survey.wifi.locale)
locale.comp$locale <- factor(locale.comp$locale, levels = c('Rural', 'Town', 'Suburban', 'Urban', 'Unknown'))

#size comparison
all.wifi.size$type <- 'all wifi'
survey.wifi.size$type <- 'survey wifi'
size.comp <- rbind(all.wifi.size, survey.wifi.size)
size.comp$district_size <- factor(size.comp$district_size, levels = c('Tiny', 'Small', 'Medium', 'Large', 'Mega'))

#clean comparison
all.wifi.exclude.ia$type <- 'all wifi'
survey.wifi.exclude.ia$type <- 'survey wifi'
clean.comp <- rbind(all.wifi.exclude.ia, survey.wifi.exclude.ia)

#engaged comparison
all.wifi.engaged$type <- 'all wifi'
survey.wifi.engaged$type <- 'survey wifi'
engaged.comp <- rbind(all.wifi.engaged, survey.wifi.engaged)

#sufficient comparison
all.wifi.sufficient$type <- 'all wifi'
survey.wifi.sufficient$type <- 'survey wifi'
sufficient.comp <- rbind(all.wifi.sufficient, survey.wifi.sufficient)

#dd sufficient comparison
dd.wifi.suff$type <- 'all wifi'
dd.receive.wifi.suff$type <- 'survey wifi'
dd.wifi.suff <- rbind(dd.wifi.suff, dd.receive.wifi.suff)

if (nrow(dd.wifi.suff[dd.wifi.suff$wifi_status == 'Other' & dd.wifi.suff$type == 'survey wifi',]) == 0) {
  dd.wifi.suff <- rbind(dd.wifi.suff,
                        c('Other',0,0,'survey wifi'))
}

dd.wifi.suff$percent_districts <- as.numeric(dd.wifi.suff$percent_districts)

all.wifi$tiny <- ifelse(all.wifi$district_size == 'Tiny', T, F)
all.wifi$small <- ifelse(all.wifi$district_size == 'Small', T, F)
all.wifi$med <- ifelse(all.wifi$district_size == 'Medium', T, F)
all.wifi$large <- ifelse(all.wifi$district_size == 'Large', T, F)
all.wifi$mega <- ifelse(all.wifi$district_size == 'Mega', T, F)
all.wifi$insuff <- ifelse(all.wifi$wifi_status == 'Insufficient 16-17', T, F)


tiny.comp <- rbind(all = table(all.wifi$tiny), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'tiny'])) %>% as.table()
small.comp <- rbind(all = table(all.wifi$small), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'small'])) %>% as.table()
med.comp <- rbind(all = table(all.wifi$med), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'med'])) %>% as.table()
large.comp <- rbind(all = table(all.wifi$large), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'large'])) %>% as.table()
mega.comp <- rbind(all = table(all.wifi$mega), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'mega'])) %>% as.table()
engaged.states.comp <- rbind(all = table(all.wifi$engaged_status), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'engaged_status'])) %>% as.table()
insuff.comp <- rbind(all = table(all.wifi$insuff), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'insuff'])) %>% as.table()

all.wifi.engaged.comp <- table(all.wifi[all.wifi$wifi_status != 'No wifi info 17', 'wifi_status'], all.wifi[all.wifi$wifi_status != 'No wifi info 17', 'engaged_status'])
all.wifi.engaged.comp <- t(all.wifi.engaged.comp)

##******************************************************************************************************************************
##ATTEMPTING BY STATE
all.wifi.states <- table(dd$wifi_status, dd$postal_cd)
all.wifi.states <- t(all.wifi.states)
all.wifi.states <- prop.table(all.wifi.states,1)
all.wifi.states <- as.data.frame(all.wifi.states)
names(all.wifi.states) <- c('postal_cd', 'wifi_status','percent')

num_buckets <- 10
bucket_vector <- c()
for (i in 1:num_buckets){
  print(i)
  bucket_vector <- append(bucket_vector, i/num_buckets)
}


#new buckets after discussing with Solomon
bucket_vector <- c(.1, .9, 1)

all.wifi.states <- filter(all.wifi.states, wifi_status == 'Insufficient 16-17')

bucket <- c()
for (i in all.wifi.states$percent){
  print(i)
  temp <- ifelse(i <= bucket_vector[1], '0 - 10%',
                 ifelse(i <= bucket_vector[2], '10 - 90%',
                        '90 - 100%'
                        )
                 )
  print(max(temp))
  bucket <- append(bucket, max(temp))
}

all.wifi.states <- cbind(all.wifi.states, bucket)
state.buckets <- all.wifi.states[,c('postal_cd', 'bucket')]

insuff.buckets <- all.wifi.states[all.wifi.states$wifi_status == 'Insufficient 16-17',]
all.wifi.states <- table(dd$wifi_status, dd$postal_cd)
all.wifi.states <- t(all.wifi.states)
all.wifi.states <- as.data.frame(all.wifi.states)
names(all.wifi.states) <- c('postal_cd', 'wifi_status','number_districts')

#insuff.buckets <- merge(insuff.buckets, all.wifi.states[all.wifi.states$wifi_status == 'Insufficient 16-17', c('postal_cd', 'number_districts')], by = 'postal_cd')
insuff.buckets <- merge(insuff.buckets, all.wifi.states[, c('postal_cd', 'number_districts')], by = 'postal_cd')
insuff.buckets <- group_by(insuff.buckets, bucket) %>% summarise(num_districts = sum(number_districts))
insuff.buckets <- as.data.frame(insuff.buckets)
insuff.buckets$percent <- insuff.buckets$num_districts/sum(insuff.buckets$num_districts)
insuff.buckets$type <- 'all wifi'

survey.wifi.states <- table(receives.survey.df$wifi_status, receives.survey.df$postal_cd)
survey.wifi.states <- t(survey.wifi.states)
survey.wifi.states <- survey.wifi.states %>% as.data.frame()
names(survey.wifi.states) <- c('postal_cd', 'wifi_status','number_districts')
#survey.wifi.states <- survey.wifi.states[survey.wifi.states$wifi_status == 'Insufficient 16-17',]
survey.wifi.states <- merge(x = survey.wifi.states, y = state.buckets, by = 'postal_cd', all.x = T)

survey.insuff.buckets <- group_by(survey.wifi.states, bucket) %>% summarise(num_districts = sum(number_districts))
survey.insuff.buckets <- as.data.frame(survey.insuff.buckets)
survey.insuff.buckets$percent <- survey.insuff.buckets$num_districts/sum(survey.insuff.buckets$num_districts)
survey.insuff.buckets$type <- 'survey wifi'

insuff.buckets <- rbind(insuff.buckets, survey.insuff.buckets)

ggplot(insuff.buckets, aes(factor(bucket), percent)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Percent Insufficient Districts by State Suffiency Bucket', x = 'State % of Insufficient Districts') +
  scale_y_continuous(limits = c(0, 1)) + 
  theme(axis.text = element_text(size = 10))



##******************************************************************************************************************************


#test to determine if sample is similar enough to population
prop.test(tiny.comp, correct = FALSE)
prop.test(small.comp, correct = FALSE)
prop.test(med.comp, correct = FALSE)
prop.test(large.comp, correct = FALSE)
prop.test(mega.comp, correct = FALSE)
prop.test(engaged.states.comp, correct = FALSE)
prop.test(insuff.comp, correct = FALSE)

#is suffiency different between engaged and non engaged states (trying to answer the question of wheter or not the engaged comparison is needed)
prop.test(all.wifi.engaged.comp, correct = FALSE) #NO, p-value is .3594 and the proportions are very similar



table(all.wifi$district_size)
table(all.wifi[all.wifi$receives_survey == 'Yes', 'district_size'])
locale.comp.test <- rbind(all = table(all.wifi$district_size), survey = table(all.wifi[all.wifi$receives_survey == 'Yes', 'district_size'])) %>% as.table()


chisq.test(locale.comp.test)


t.test(all.wifi$c2_prediscount_budget_15, all.wifi[all.wifi$receives_survey == 'Yes','c2_prediscount_budget_15'])

##**************************************************************************************************************************************************
## visualizing results

x <- nrow(receives.survey.df)

pdf('figures/survey_v_population_comps.pdf', width = 8, height = 11)
ggplot(locale.comp, aes(locale, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Locale of All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, .8)) + 
  theme(axis.text = element_text(size = 10))

ggplot(size.comp, aes(district_size, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Size of All Wifi districts vs. Wifi districts receiving survey', x = '') +
  scale_y_continuous(limits = c(0, .8)) + 
  theme(axis.text = element_text(size = 15), legend.text = element_text(size = 15))

ggplot(clean.comp, aes(exclude_from_ia_analysis, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Excluded from IA for All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, 1))+ 
  theme(axis.text = element_text(size = 10))

ggplot(all.wifi, aes(c2_prediscount_budget_15)) + 
  geom_histogram(binwidth = 50000) +
  xlim(c(-25000,2000000)) + 
  labs(x = 'C2 Budget', y = 'number of districts receiving survey', 
       title = 'Wi-Fi Starting Budget All Wifi Districts', 
       caption = 'Note: removed districts over $5M') +
  theme_bw()

ggplot(receives.survey.df, aes(c2_prediscount_budget_15)) + 
  geom_histogram(binwidth = 50000) +
  xlim(c(-25000,2000000)) + 
  labs(x = 'C2 Budget', y = 'number of districts receiving survey', 
       title = 'Wi-Fi Starting Budget for Wifi districts receiving survey', 
       caption = 'Note: removed districts over $5M') +
  theme_bw()

ggplot(prop.table(all.wifi.engaged.comp, 1) %>% as.data.frame(), aes(Var2, Freq)) + 
  geom_bar(stat = 'identity', aes(fill = Var1), position = 'dodge') +
  labs(title = 'Comparing Sufficiency Responses for Engaged vs. Non Engaged', 
       x='', y = '% Districts', subtitle = 'Note: null responses in 2017 not included') +
  scale_y_continuous(limits = c(0, 1)) + 
  scale_fill_discrete(name = 'Engaged Status') +
  theme(axis.text = element_text(size = 10))

ggplot(sufficient.comp, aes(wifi_status, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Suffiency Status for All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, 0.8))+ 
  theme(axis.text = element_text(size = 10))

ggplot(dd.wifi.suff, aes(wifi_status, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
  labs(title = 'Suffiency Status for All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, 0.8))+ 
  theme(axis.text = element_text(size = 10))

dev.off()


##**************************************************************************************************************************************************
## comparing the three Wifi groups who receive survey (suff both years, insuff both years, null in 17)
head(receives.survey.df)
table(receives.survey.df$wifi_status)

receives.survey.df$locale <- factor(receives.survey.df$locale, levels = c('Rural', 'Town', 'Suburban', 'Urban', 'Unknown'))
receives.survey.df$district_size <- factor(receives.survey.df$district_size, levels = c('Tiny', 'Small', 'Medium', 'Large', 'Mega'))
receives.survey.df$wifi_status <- factor(receives.survey.df$wifi_status, levels = c('No wifi info 17', 'Insufficient 16-17', 'Sufficient  16-17'))

wifi.groups <- group_by(receives.survey.df, wifi_status) %>% summarise(total.in.group = n()) %>% as.data.frame()

survey.wifi.comp.locale <- group_by(receives.survey.df, wifi_status, locale) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.comp.locale <- merge(survey.wifi.comp.locale, wifi.groups, by = 'wifi_status')
survey.wifi.comp.locale$percent_districts <- round(survey.wifi.comp.locale$total.count / survey.wifi.comp.locale$total.in.group,2) 
head(survey.wifi.comp.locale)

survey.wifi.comp.size <- group_by(receives.survey.df, wifi_status, district_size) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.comp.size <- merge(survey.wifi.comp.size, wifi.groups, by = 'wifi_status')
survey.wifi.comp.size$percent_districts <- round(survey.wifi.comp.size$total.count / survey.wifi.comp.size$total.in.group,2) 
head(survey.wifi.comp.size)

survey.wifi.comp.exclude.ia <- group_by(receives.survey.df, wifi_status, exclude_from_ia_analysis) %>% summarise(total.count=n()) %>% as.data.frame()
survey.wifi.comp.exclude.ia <- merge(survey.wifi.comp.exclude.ia, wifi.groups, by = 'wifi_status')
survey.wifi.comp.exclude.ia$percent_districts <- round(survey.wifi.comp.exclude.ia$total.count / survey.wifi.comp.exclude.ia$total.in.group,2) 
head(survey.wifi.comp.exclude.ia)



##**************************************************************************************************************************************************
## visualizing results

pdf('figures/wifi_survey_comps.pdf', width = 8, height = 11)
ggplot(survey.wifi.comp.locale, aes(locale, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = wifi_status), position = 'dodge') +
  labs(title = 'Locale of All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, .8))

ggplot(survey.wifi.comp.size, aes(district_size, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = wifi_status), position = 'dodge') +
  labs(title = 'Size of All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, .8))

ggplot(survey.wifi.comp.exclude.ia, aes(exclude_from_ia_analysis, percent_districts)) + 
  geom_bar(stat = 'identity', aes(fill = wifi_status), position = 'dodge') +
  labs(title = 'Excluded from IA for All Wifi districts vs. Wifi districts receiving survey') +
  scale_y_continuous(limits = c(0, 1))

ggplot(receives.survey.df[receives.survey.df$wifi_status == 'No wifi info 17',], aes(c2_prediscount_budget_15)) + 
  geom_histogram(binwidth = 50000, fill = '#F8766D', color = 'black') +
  xlim(c(-25000,5000000)) + 
  labs(x = 'C2 Budget', y = 'number of districts receiving survey', 
       title = 'Wi-Fi Starting Budget for No Wifi Info districts receiving survey', 
       caption = 'Note: removed districts over $5M') +
  theme_bw()

ggplot(receives.survey.df[receives.survey.df$wifi_status == 'Insufficient 16-17',], aes(c2_prediscount_budget_15)) + 
  geom_histogram(binwidth = 50000, fill = '#00BA38', color = 'black') +
  xlim(c(-25000,5000000)) + 
  labs(x = 'C2 Budget', y = 'number of districts receiving survey', 
       title = 'Wi-Fi Starting Budget for Insufficient Wifi districts receiving survey', 
       caption = 'Note: removed districts over $5M') +
  theme_bw()

ggplot(receives.survey.df[receives.survey.df$wifi_status == 'Sufficient  16-17',], aes(c2_prediscount_budget_15)) + 
  geom_histogram(binwidth = 50000, fill = '#619Cff', color = 'black') +
  xlim(c(-25000,5000000)) + 
  labs(x = 'C2 Budget', y = 'number of districts receiving survey', 
       title = 'Wi-Fi Starting Budget for Sufficient Wifi districts receiving survey', 
       caption = 'Note: removed districts over $5M') +
  theme_bw()
dev.off()

##**************************************************************************************************************************************************
## comparing subsets of wifi districts we care about to subsets of wifi districts we care about who get survey

wifi.statuses <- unique(all.wifi$wifi_status)

for (status in wifi.statuses) {
  print(status)
  all.by.locale <- group_by(all.wifi[all.wifi$wifi_status == status,], locale) %>% summarise(total.count=n()) %>% as.data.frame()
  all.by.locale$percent_districts <- round(all.by.locale$total.count / sum(all.by.locale$total.count),2)
  all.by.locale$type = 'all subset'
  print(head(all.by.locale))
  
  all.by.size <- group_by(all.wifi[all.wifi$wifi_status == status,], district_size) %>% summarise(total.count=n()) %>% as.data.frame()
  all.by.size$percent_districts <- round(all.by.size$total.count / sum(all.by.size$total.count),2)
  all.by.size$type = 'all subset'
  print(head(all.by.size))
  
  all.by.exclude.ia <- group_by(all.wifi[all.wifi$wifi_status == status,], exclude_from_ia_analysis) %>% summarise(total.count=n()) %>% as.data.frame()
  all.by.exclude.ia$percent_districts <- round(all.by.exclude.ia$total.count / sum(all.by.exclude.ia$total.count),2)
  all.by.exclude.ia$type = 'all subset'
  print(head(all.by.exclude.ia))
  
  survey.by.locale <- group_by(receives.survey.df[receives.survey.df$wifi_status == status,], locale) %>% summarise(total.count=n()) %>% as.data.frame()
  survey.by.locale$percent_districts <- round(survey.by.locale$total.count / sum(survey.by.locale$total.count),2)
  survey.by.locale$type = 'survey subset'
  print(head(survey.by.locale))
  
  survey.by.size <- group_by(receives.survey.df[receives.survey.df$wifi_status == status,], district_size) %>% summarise(total.count=n()) %>% as.data.frame()
  survey.by.size$percent_districts <- round(survey.by.size$total.count / sum(survey.by.size$total.count),2)
  survey.by.size$type = 'survey subset'
  print(head(survey.by.size))
  
  survey.by.exclude.ia <- group_by(receives.survey.df[receives.survey.df$wifi_status == status,], exclude_from_ia_analysis) %>% summarise(total.count=n()) %>% as.data.frame()
  survey.by.exclude.ia$percent_districts <- round(survey.by.exclude.ia$total.count / sum(survey.by.exclude.ia$total.count),2)
  survey.by.exclude.ia$type = 'survey subset'
  print(head(survey.by.exclude.ia))
  
  print(paste(status, 'locale'))
  loc <- rbind(all.by.locale, survey.by.locale)
  size <- rbind(all.by.size, survey.by.size)
  exclude <- rbind(all.by.exclude.ia, survey.by.exclude.ia)
  
  #assign(gsub(' ', '_', status), rbind(all.by.locale, survey.by.locale))
  
  pdf(paste0('figures/', gsub(' ', '_', status), '.pdf'), width = 8, height = 11)
  #pdf(paste0('figures/test.pdf'), width = 8, height = 11)
  print(ggplot(loc, aes(locale, percent_districts)) + 
    geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
    labs(title = 'Locale of All Wifi districts vs. Wifi districts receiving survey') +
    scale_y_continuous(limits = c(0, .8)))
  
  print(ggplot(size, aes(district_size, percent_districts)) + 
    geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
    labs(title = 'Size of All Wifi districts vs. Wifi districts receiving survey') +
    scale_y_continuous(limits = c(0, .8)))
  
  print(ggplot(exclude, aes(exclude_from_ia_analysis, percent_districts)) + 
    geom_bar(stat = 'identity', aes(fill = type), position = 'dodge') +
    labs(title = 'Excluded from IA for All Wifi districts vs. Wifi districts receiving survey') +
    scale_y_continuous(limits = c(0, 1)))
  dev.off()
}

##**************************************************************************************************************************************************
## adding districts to survey

table(dd$receives_survey)
no.survey <- filter(dd, receives_survey == 'No', engaged_status == 'Non Engaged')
no.survey <- select(no.survey, esh_id, name, postal_cd, district_size, locale)
head(no.survey)

set.seed(101)
random.num <- runif(nrow(no.survey))
no.survey$random.num <- random.num
head(no.survey)

num.tiny <- 75
new.tiny <- no.survey[no.survey$district_size == 'Tiny',]
new.tiny <- new.tiny[order(-new.tiny[,6]),]
head(new.tiny)
head(receives.survey.df)

new.tiny <- new.tiny[1:num.tiny,]
head(receives.survey.df)
names(new.tiny)
new.tiny <- new.tiny[,-6]

new.receives.survey.df <- receives.survey.df[,c('esh_id','name','postal_cd','district_size','locale')]
new.receives.survey.df <- rbind(new.receives.survey.df, new.tiny)
new.size <- group_by(new.receives.survey.df, district_size) %>% summarize(total.count = n()) %>% as.data.frame()
new.size$percent <- round(new.size$total.count / sum(new.size$total.count),2)

#figuring out how many locales to survey
temp.locale <- group_by(new.receives.survey.df, locale) %>% summarize(total.count = n()) %>% as.data.frame()
temp.locale$percent <- round(temp.locale$total.count / sum(temp.locale$total.count),2)
locale.comp
#rural-52, suburban-24, town-19,urban-6, unknown-0
num.sub <- round(.24 * sum(temp.locale$total.count) - (temp.locale[temp.locale$locale == 'Suburban', 'total.count']),0)
temp.locale[temp.locale$locale == 'Suburban','total.count'] <- temp.locale[temp.locale$locale == 'Suburban','total.count'] + num.sub
temp.locale$percent <- round(temp.locale$total.count / sum(temp.locale$total.count),2)
num.town <- round(.19 * sum(temp.locale$total.count) - (temp.locale[temp.locale$locale == 'Town', 'total.count']),0)
temp.locale[temp.locale$locale == 'Town','total.count'] <- temp.locale[temp.locale$locale == 'Town','total.count'] + num.town
temp.locale$percent <- round(temp.locale$total.count / sum(temp.locale$total.count),2)
num.urban <- round(.06 * sum(temp.locale$total.count) - (temp.locale[temp.locale$locale == 'Urban', 'total.count']),0)
temp.locale[temp.locale$locale == 'Urban','total.count'] <- temp.locale[temp.locale$locale == 'Urban','total.count'] + num.urban
temp.locale$percent <- round(temp.locale$total.count / sum(temp.locale$total.count),2)
temp.locale

nrow(no.survey)
not.surveyed <- !(no.survey$esh_id %in% new.receives.survey.df$esh_id)
no.survey <- no.survey[not.surveyed,-6]
nrow(no.survey)

set.seed(101)
random.num <- runif(nrow(no.survey))
no.survey$random.num <- random.num
head(no.survey)

#selecting new locales to survey
new.sub <- no.survey[no.survey$locale == 'Suburban',]
new.sub <- new.sub[order(-new.sub[,6]),]
head(new.sub)
new.sub <- new.sub[1:num.sub,]

new.town <- no.survey[no.survey$locale == 'Town',]
new.town <- new.town[order(-new.town[,6]),]
head(new.town)
new.town <- new.town[1:num.town,]

new.urban <- no.survey[no.survey$locale == 'Urban',]
new.urban <- new.urban[order(-new.urban[,6]),]
head(new.urban)
new.urban <- new.urban[1:num.urban,]

new.sub <- new.sub[,-6]
new.town <- new.town[,-6]
new.urban <- new.urban[,-6]
new.receives.survey.df <- rbind(new.receives.survey.df, new.sub, new.town, new.urban)

num.sub + num.urban + num.town + num.tiny
#Final checking of stratification
final.locale <- group_by(new.receives.survey.df, locale) %>% summarize(total.count = n()) %>% as.data.frame()
final.locale$percent <- round(final.locale$total.count / sum(final.locale$total.count),2)
final.locale
final.size <- group_by(new.receives.survey.df, district_size) %>% summarize(total.count = n()) %>% as.data.frame()
final.size$percent <- round(final.size$total.count / sum(final.size$total.count),2)
final.size

new.districts <- rbind(new.tiny, new.sub, new.town, new.urban)
nrow(new.districts)
head(new.districts)

new.tiny.comp <- rbind(all = table(dd$district_size == 'Tiny'),survey = table(new.receives.survey.df$district_size == 'Tiny'))
new.small.comp <- rbind(all = table(dd$district_size == 'Small'),survey = table(new.receives.survey.df$district_size == 'Small'))
new.med.comp <- rbind(all = table(dd$district_size == 'Medium'),survey = table(new.receives.survey.df$district_size == 'Medium'))
new.large.comp <- rbind(all = table(dd$district_size == 'Large'),survey = table(new.receives.survey.df$district_size == 'Large'))
new.mega.comp <- rbind(all = table(dd$district_size == 'Mega'),survey = table(new.receives.survey.df$district_size == 'Mega'))

prop.test(new.tiny.comp, correct = FALSE)
prop.test(new.small.comp, correct = FALSE)
prop.test(new.med.comp, correct = FALSE)
prop.test(new.large.comp, correct = FALSE)
prop.test(new.mega.comp, correct = FALSE)

new.rural.comp <- rbind(all = table(dd$locale == 'Rural'),survey = table(new.receives.survey.df$locale == 'Rural'))
new.town.comp <- rbind(all = table(dd$locale == 'Town'),survey = table(new.receives.survey.df$locale == 'Town'))
new.suburban.comp <- rbind(all = table(dd$locale == 'Suburban'),survey = table(new.receives.survey.df$locale == 'Suburban'))
new.urban.comp <- rbind(all = table(dd$locale == 'Urban'),survey = table(new.receives.survey.df$locale == 'Urban'))
new.unknown.comp <- rbind(all = table(dd$locale == 'Unknown'),survey = table(new.receives.survey.df$locale == 'Unknown'))

prop.test(new.rural.comp, correct = FALSE)
prop.test(new.town.comp, correct = FALSE)
prop.test(new.rural.comp, correct = FALSE)
prop.test(new.suburban.comp, correct = FALSE)
prop.test(new.unknown.comp, correct = FALSE)

#need to adjust sample
set.seed(101)
random.num <- runif(nrow(new.districts))
new.districts$random.num <- random.num
head(new.districts)

new.districts <- new.districts[order(-new.districts[,6]),]
head(new.districts)

num.lost.med.sub <- 20
num.lost.med.town <- 9

#taking out some districts
lost.med.sub <- new.districts[new.districts$district_size == 'Medium' & new.districts$locale == 'Suburban',]
lost.med.sub <- lost.med.sub[1:num.lost.med.sub,]
lost.med.town <- new.districts[new.districts$district_size == 'Medium' & new.districts$locale == 'Town',]
lost.med.town <- lost.med.town[1:num.lost.med.town,]
lost.districts <- rbind(lost.med.sub, lost.med.town)
new.districts <- new.districts[!new.districts$esh_id %in% lost.districts$esh_id,]

#adding back some districts
no.survey <- filter(dd, receives_survey == 'No', engaged_status == 'Non Engaged')
not.surveyed <- !(no.survey$esh_id %in% new.districts$esh_id)
no.survey <- select(no.survey, esh_id, name, postal_cd, district_size, locale)
no.survey <- no.survey[not.surveyed,]
nrow(no.survey)

num.new.tiny.town <- 6
num.new.large.sub <- 15

set.seed(101)
random.num <- runif(nrow(no.survey))
no.survey$random.num <- random.num
head(no.survey)

new.tiny.town <- no.survey[no.survey$locale == 'Town' & no.survey$district_size == 'Tiny',]
new.tiny.town <- new.tiny.town[order(-new.tiny.town[,6]),]
head(new.tiny.town)
new.tiny.town <- new.tiny.town[1:num.new.tiny.town,]
new.tiny.town <- select(new.tiny.town, -6)

new.large.sub <- no.survey[no.survey$locale == 'Suburban' & no.survey$district_size == 'Large',]
new.large.sub <- new.large.sub[order(-new.large.sub[,6]),]
head(new.large.sub)
new.large.sub <- new.large.sub[1:num.new.large.sub,]
new.large.sub <- select(new.large.sub, -6)

new.districts <- select(new.districts, -6)
new.districts <- rbind(new.districts, new.large.sub, new.tiny.town)

new.receives.survey.df <- receives.survey.df[,c('esh_id','name','postal_cd','district_size','locale')]
new.receives.survey.df <- rbind(new.receives.survey.df, new.districts)

new.tiny.comp <- rbind(all = table(dd$district_size == 'Tiny'),survey = table(new.receives.survey.df$district_size == 'Tiny'))
new.small.comp <- rbind(all = table(dd$district_size == 'Small'),survey = table(new.receives.survey.df$district_size == 'Small'))
new.med.comp <- rbind(all = table(dd$district_size == 'Medium'),survey = table(new.receives.survey.df$district_size == 'Medium'))
new.large.comp <- rbind(all = table(dd$district_size == 'Large'),survey = table(new.receives.survey.df$district_size == 'Large'))
new.mega.comp <- rbind(all = table(dd$district_size == 'Mega'),survey = table(new.receives.survey.df$district_size == 'Mega'))

prop.test(new.tiny.comp, correct = FALSE)
prop.test(new.small.comp, correct = FALSE)
prop.test(new.med.comp, correct = FALSE)
prop.test(new.large.comp, correct = FALSE)
prop.test(new.mega.comp, correct = FALSE)

new.rural.comp <- rbind(all = table(dd$locale == 'Rural'),survey = table(new.receives.survey.df$locale == 'Rural'))
new.town.comp <- rbind(all = table(dd$locale == 'Town'),survey = table(new.receives.survey.df$locale == 'Town'))
new.suburban.comp <- rbind(all = table(dd$locale == 'Suburban'),survey = table(new.receives.survey.df$locale == 'Suburban'))
new.urban.comp <- rbind(all = table(dd$locale == 'Urban'),survey = table(new.receives.survey.df$locale == 'Urban'))
new.unknown.comp <- rbind(all = table(dd$locale == 'Unknown'),survey = table(new.receives.survey.df$locale == 'Unknown'))

prop.test(new.rural.comp, correct = FALSE)
prop.test(new.town.comp, correct = FALSE)
prop.test(new.rural.comp, correct = FALSE)
prop.test(new.suburban.comp, correct = FALSE)
prop.test(new.unknown.comp, correct = FALSE)

write.csv(new.districts, 'data/interim/new_districts_survey.csv')
