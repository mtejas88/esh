## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

# remove every object in the environment
rm(list = ls())

##**************************************************************************************************************************************************
## read in data
districts_display <- read.csv("data/interim/districts_display_part2.csv", as.is=T, header=T, quote="\"", stringsAsFactors=F)

#install and load packages
packages.to.install <- c("data.table", "plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(data.table)
library(plyr)

##**************************************************************************************************************v
#creating a Totals DF
#totals budget
num_students <- sum(districts_display$num_students, na.rm = TRUE)

current_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                     districts_display$include_in_universe_of_districts == TRUE &
                                                                     districts_display$ia_bandwidth_per_student_kbps >= 100], na.rm = TRUE)
current_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                    districts_display$include_in_universe_of_districts == TRUE], na.rm = TRUE)

current_num_students_meeting_extrap_perc <- current_num_students_meeting / current_num_students_sample

current_num_students_meeting_extrap <- current_num_students_meeting_extrap_perc * num_students


##max cost extraps
max_cost_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                      districts_display$include_in_universe_of_districts == TRUE &
                                                                      districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                      districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                      districts_display$max_cost_bandwidth_per_student >= 100], na.rm = TRUE)

max_cost_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                     districts_display$include_in_universe_of_districts == TRUE &
                                                                     districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                     districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

max_cost_num_students_meeting_extrap_perc <- max_cost_num_students_meeting / max_cost_num_students_sample

##cost constant extraps
cost_constant_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                           districts_display$include_in_universe_of_districts == TRUE &
                                                                           districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                           districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                           districts_display$cost_constant_bandwidth_per_student >= 100], na.rm = TRUE)

cost_constant_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                          districts_display$include_in_universe_of_districts == TRUE &
                                                                          districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                          districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

cost_constant_num_students_meeting_extrap_perc <- cost_constant_num_students_meeting / cost_constant_num_students_sample

##bw constant extraps
bw_constant_num_students_meeting <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                         districts_display$include_in_universe_of_districts == TRUE &
                                                                         districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                         districts_display$exclude_from_ia_cost_analysis == FALSE &
                                                                         districts_display$bw_constant_bandwidth_per_student >= 100], na.rm = TRUE)

bw_constant_num_students_sample <- sum(districts_display$num_students[districts_display$exclude_from_ia_analysis == FALSE & 
                                                                        districts_display$include_in_universe_of_districts == TRUE &
                                                                        districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                        districts_display$exclude_from_ia_cost_analysis == FALSE], na.rm = TRUE)

bw_constant_num_students_meeting_extrap_perc <- bw_constant_num_students_meeting / bw_constant_num_students_sample



#

cost_constant_total_pai_budg <- sum(districts_display$cost_constant_total_pai_budj, na.rm = TRUE)
bw_constant_total_pai_budg <- sum(districts_display$bw_constant_total_pai_budg, na.rm = TRUE)
max_cost_total_pai_budg <- sum(districts_display$max_cost_total_pai_budg, na.rm = TRUE)
district_cost_total <- sum(districts_display$district_cost_total, na.rm = TRUE)
current_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$ia_bandwidth_per_student_kbps >= 100])
current_districts_meeting_perc <- current_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
cost_constant_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$cost_constant_bandwidth_per_student >= 100])
cost_constant_districts_meeting_perc <- cost_constant_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
bw_constant_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$bw_constant_bandwidth_per_student >= 100])
bw_constant_districts_meeting_perc <- bw_constant_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])
max_cost_districts_meeting <- length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0 &
    districts_display$max_cost_bandwidth_per_student >= 100])
max_cost_districts_meeting_perc <- max_cost_districts_meeting / length(districts_display$exclude_from_ia_analysis[
  districts_display$exclude_from_ia_analysis == FALSE & 
    districts_display$exclude_from_ia_cost_analysis == FALSE &
    districts_display$include_in_universe_of_districts == TRUE &
    districts_display$ia_monthly_cost_per_mbps > 0])


#totals oop
cost_constant_total_pai_oop <- sum(districts_display$cost_constant_total_pai_oop, na.rm = TRUE)
bw_constant_total_pai_oop <- sum(districts_display$bw_constant_total_pai_oop, na.rm = TRUE)
max_cost_total_oop <- sum(districts_display$max_cost_total_oop, na.rm = TRUE)
total_current_oop <- sum(districts_display$total_current_oop, na.rm = TRUE)


#joining tables
totals_df <- data.frame(num_students, cost_constant_total_pai_budg,bw_constant_total_pai_budg,max_cost_total_pai_budg,district_cost_total,
                        cost_constant_total_pai_oop,bw_constant_total_pai_oop,max_cost_total_oop,total_current_oop)
totals_df$cost_constant_total_erate_share <- totals_df$cost_constant_total_pai_budg - totals_df$cost_constant_total_pai_oop
totals_df$bw_constant_total_erate_share_category <- totals_df$bw_constant_total_pai_budg - totals_df$bw_constant_total_pai_oop
totals_df$max_cost_total_erate_share_category <- totals_df$max_cost_total_pai_budg - totals_df$max_cost_total_oop
totals_df$total_erate_share_category <- totals_df$district_cost_total - totals_df$total_current_oop



#creating a per student totals df
totals_df_per_student <- totals_df
totals_df_per_student$cost_constant_total_per_student <- totals_df_per_student$cost_constant_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$bw_constant_total_per_student <- totals_df_per_student$bw_constant_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$max_cost_total_per_student <- totals_df_per_student$max_cost_total_pai_budg / totals_df_per_student$num_students
totals_df_per_student$current_total_per_student <- totals_df_per_student$district_cost_total / totals_df_per_student$num_students
totals_df_per_student$cost_constant_erate_per_student <- totals_df_per_student$cost_constant_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$bw_constant_erate_per_student <- totals_df_per_student$bw_constant_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$max_cost_erate_per_student <- totals_df_per_student$max_cost_total_erate_share / totals_df_per_student$num_students
totals_df_per_student$current_erate_per_student <- totals_df_per_student$total_erate_share / totals_df_per_student$num_students
totals_df_per_student$cost_constant_dist_per_student <- totals_df_per_student$cost_constant_total_pai_oop / totals_df_per_student$num_students
totals_df_per_student$bw_constant_dist_per_student <- totals_df_per_student$bw_constant_total_pai_oop / totals_df_per_student$num_students
totals_df_per_student$max_cost_dist_per_student <- totals_df_per_student$max_cost_total_oop / totals_df_per_student$num_students
totals_df_per_student$current_dist_per_student <- totals_df_per_student$total_current_oop / totals_df_per_student$num_students

##**************************************************************************************************************************************************
#CREATING A CATEGORY DF
num_students_category <- aggregate(districts_display$num_students, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(num_students_category) <- c('category','num_students_category')

cost_constant_total_pai_budg_category <- aggregate(districts_display$cost_constant_total_pai_budj, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_budg_category) <- c('category','cost_constant_total_pai_budg_category')

bw_constant_total_pai_budg_category <- aggregate(districts_display$bw_constant_total_pai_budg, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_budg_category) <- c('category','bw_constant_total_pai_budg_category')

max_cost_total_pai_budg_category <- aggregate(districts_display$max_cost_total_pai_budg, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_total_pai_budg_category) <- c('category','max_cost_total_pai_budg_category')

district_cost_total_category <- aggregate(districts_display$district_cost_total, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(district_cost_total_category) <- c('category','district_cost_total_category')

#cost_constant_total_pai_oop, bw_constant_total_pai_oop, max_cost_total_oop, total_current_oop
cost_constant_total_pai_oop_category <- aggregate(districts_display$cost_constant_total_pai_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_oop_category) <- c('category','cost_constant_total_pai_oop')

bw_constant_total_pai_oop_category <- aggregate(districts_display$bw_constant_total_pai_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_oop_category) <- c('category','bw_constant_total_pai_oop')

max_cost_total_oop_category <- aggregate(districts_display$max_cost_total_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_total_oop_category) <- c('category','max_cost_total_oop')

total_current_oop_category <- aggregate(districts_display$total_current_oop, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(total_current_oop_category) <- c('category','total_current_oop')


current_num_students_meeting_category <- aggregate(districts_display$current_num_students_meeting, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(current_num_students_meeting_category) <- c('category','current_num_students_meeting_category')
max_cost_num_students_meeting_category <- aggregate(districts_display$max_cost_num_students_meeting, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_meeting_category) <- c('category','max_cost_num_students_meeting_category')

current_num_students_sample_category <- aggregate(districts_display$current_num_students_sample, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(current_num_students_sample_category) <- c('category','current_num_students_sample_category')

max_cost_num_students_sample_category <- aggregate(districts_display$max_cost_num_students_sample, by=list(districts_display$category), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_sample_category) <- c('category','max_cost_num_students_sample_category')



#joining tables
category_df <- merge(x=num_students_category,y=cost_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_pai_budg_category, by='category')
category_df <- merge(x=category_df,y=district_cost_total_category, by='category')
category_df <- merge(x=category_df,y=cost_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=bw_constant_total_pai_oop_category, by='category')
category_df <- merge(x=category_df,y=max_cost_total_oop_category, by='category')
category_df <- merge(x=category_df,y=total_current_oop_category, by='category')
category_df <- merge(x=category_df,y=current_num_students_meeting_category, by='category')
category_df <- merge(x=category_df,y=max_cost_num_students_meeting_category, by='category')
category_df <- merge(x=category_df,y=current_num_students_sample_category, by='category')
category_df <- merge(x=category_df,y=max_cost_num_students_sample_category, by='category')
category_df$current_num_students_meeting_extrap_by_category <- (category_df$current_num_students_meeting_category / category_df$current_num_students_sample_category) * category_df$num_students_category
category_df$max_cost_num_students_meeting_extrap_by_category <- (category_df$max_cost_num_students_meeting_category / category_df$max_cost_num_students_sample_category) * category_df$num_students_category
category_df$cost_constant_total_erate_share_category <- category_df$cost_constant_total_pai_budg_category - category_df$cost_constant_total_pai_oop
category_df$bw_constant_total_erate_share_category <- category_df$bw_constant_total_pai_budg_category - category_df$bw_constant_total_pai_oop
category_df$max_cost_total_erate_share_category <- category_df$max_cost_total_pai_budg_category - category_df$max_cost_total_oop
category_df$total_erate_share_category <- category_df$district_cost_total_category - category_df$total_current_oop

#creating a per student category df
category_df_per_student <- category_df
category_df_per_student$cost_constant_total_per_student <- category_df_per_student$cost_constant_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$bw_constant_total_per_student <- category_df_per_student$bw_constant_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$max_cost_total_per_student <- category_df_per_student$max_cost_total_pai_budg_category / category_df_per_student$num_students_category
category_df_per_student$current_total_per_student <- category_df_per_student$district_cost_total_category / category_df_per_student$num_students_category
category_df_per_student$cost_constant_erate_per_student <- category_df_per_student$cost_constant_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$bw_constant_erate_per_student <- category_df_per_student$bw_constant_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$max_cost_erate_per_student <- category_df_per_student$max_cost_total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$current_erate_per_student <- category_df_per_student$total_erate_share_category / category_df_per_student$num_students_category
category_df_per_student$cost_constant_dist_per_student <- category_df_per_student$cost_constant_total_pai_oop / category_df_per_student$num_students_category
category_df_per_student$bw_constant_dist_per_student <- category_df_per_student$bw_constant_total_pai_oop / category_df_per_student$num_students_category
category_df_per_student$max_cost_dist_per_student <- category_df_per_student$max_cost_total_oop / category_df_per_student$num_students_category
category_df_per_student$current_dist_per_student <- category_df_per_student$total_current_oop / category_df_per_student$num_students_category
category_df_per_student <- category_df_per_student[,c('category','cost_constant_total_per_student','bw_constant_total_per_student','max_cost_total_per_student',
                                                      'current_total_per_student','cost_constant_erate_per_student','bw_constant_erate_per_student',
                                                      'max_cost_erate_per_student','current_erate_per_student','cost_constant_dist_per_student',
                                                      'bw_constant_dist_per_student','max_cost_dist_per_student','current_dist_per_student')]

category_df$current_num_students_meeting_extrap <- category_df$num_students_category * current_num_students_meeting_extrap_perc
category_df$max_cost_num_students_meeting_extrap <- category_df$num_students_category * max_cost_num_students_meeting_extrap_perc

##**************************************************************************************************************************************************
#CREATING A LOCALE DF
num_students_locale <- aggregate(districts_display$num_students, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(num_students_locale) <- c('locale','num_students_locale')

cost_constant_total_pai_budg_locale <- aggregate(districts_display$cost_constant_total_pai_budj, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_budg_locale) <- c('locale','cost_constant_total_pai_budg_locale')

bw_constant_total_pai_budg_locale <- aggregate(districts_display$bw_constant_total_pai_budg, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_budg_locale) <- c('locale','bw_constant_total_pai_budg_locale')

max_cost_total_pai_budg_locale <- aggregate(districts_display$max_cost_total_pai_budg, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_total_pai_budg_locale) <- c('locale','max_cost_total_pai_budg_locale')

district_cost_total_locale <- aggregate(districts_display$district_cost_total, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(district_cost_total_locale) <- c('locale','district_cost_total_locale')

#cost_constant_total_pai_oop, bw_constant_total_pai_oop, max_cost_total_oop, total_current_oop
cost_constant_total_pai_oop_locale <- aggregate(districts_display$cost_constant_total_pai_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_total_pai_oop_locale) <- c('locale','cost_constant_total_pai_oop')

bw_constant_total_pai_oop_locale <- aggregate(districts_display$bw_constant_total_pai_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_total_pai_oop_locale) <- c('locale','bw_constant_total_pai_oop')

max_cost_total_oop_locale <- aggregate(districts_display$max_cost_total_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_total_oop_locale) <- c('locale','max_cost_total_oop')

total_current_oop_locale <- aggregate(districts_display$total_current_oop, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(total_current_oop_locale) <- c('locale','total_current_oop')

#num meeting
current_num_students_meeting_locale <- aggregate(districts_display$current_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_num_students_meeting_locale) <- c('locale','current_num_students_meeting_locale')

max_cost_num_students_meeting_locale <- aggregate(districts_display$max_cost_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_meeting_locale) <- c('locale','max_cost_num_students_meeting_locale')

cost_constant_num_students_meeting_locale <- aggregate(districts_display$cost_constant_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_num_students_meeting_locale) <- c('locale','cost_constant_num_students_meeting_locale')

bw_constant_num_students_meeting_locale <- aggregate(districts_display$bw_constant_num_students_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_num_students_meeting_locale) <- c('locale','bw_constant_num_students_meeting_locale')

#num in sample
current_num_students_sample_locale <- aggregate(districts_display$current_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_num_students_sample_locale) <- c('locale','current_num_students_sample_locale')

max_cost_num_students_sample_locale <- aggregate(districts_display$max_cost_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_num_students_sample_locale) <- c('locale','max_cost_num_students_sample_locale')

cost_constant_num_students_sample_locale <- aggregate(districts_display$cost_constant_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_num_students_sample_locale) <- c('locale','cost_constant_num_students_sample_locale')

bw_constant_num_students_sample_locale <- aggregate(districts_display$bw_constant_num_students_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_num_students_sample_locale) <- c('locale','bw_constant_num_students_sample_locale')

#num districts meeting
current_districts_meeting_locale <- aggregate(districts_display$current_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_districts_meeting_locale) <- c('locale','current_districts_meeting_locale')

max_cost_districts_meeting_locale <- aggregate(districts_display$max_cost_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_districts_meeting_locale) <- c('locale','max_cost_districts_meeting_locale')

cost_constant_districts_meeting_locale <- aggregate(districts_display$cost_constant_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_districts_meeting_locale) <- c('locale','cost_constant_districts_meeting_locale')

bw_constant_districts_meeting_locale <- aggregate(districts_display$bw_constant_districts_meeting, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_districts_meeting_locale) <- c('locale','bw_constant_districts_meeting_locale')

#num districts in sample
current_districts_sample_locale <- aggregate(districts_display$current_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(current_districts_sample_locale) <- c('locale','current_districts_sample_locale')

max_cost_districts_sample_locale <- aggregate(districts_display$max_cost_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(max_cost_districts_sample_locale) <- c('locale','max_cost_districts_sample_locale')

cost_constant_districts_sample_locale <- aggregate(districts_display$cost_constant_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(cost_constant_districts_sample_locale) <- c('locale','cost_constant_districts_sample_locale')

bw_constant_districts_sample_locale <- aggregate(districts_display$bw_constant_districts_sample, by=list(districts_display$locale), FUN = sum, na.rm = TRUE)
names(bw_constant_districts_sample_locale) <- c('locale','bw_constant_districts_sample_locale')






#joining tables
locale_df <- merge(x=num_students_locale,y=cost_constant_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_total_pai_budg_locale, by='locale')
locale_df <- merge(x=locale_df,y=district_cost_total_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_total_pai_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_total_pai_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_total_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=total_current_oop_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_num_students_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_num_students_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_districts_meeting_locale, by='locale')
locale_df <- merge(x=locale_df,y=current_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=max_cost_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=cost_constant_districts_sample_locale, by='locale')
locale_df <- merge(x=locale_df,y=bw_constant_districts_sample_locale, by='locale')
locale_df$current_num_students_meeting_extrap_by_locale <- (locale_df$current_num_students_meeting_locale / locale_df$current_num_students_sample_locale) * locale_df$num_students_locale
locale_df$max_cost_num_students_meeting_extrap_by_locale <- (locale_df$max_cost_num_students_meeting_locale / locale_df$max_cost_num_students_sample_locale) * locale_df$num_students_locale
locale_df$cost_constant_num_students_meeting_extrap_by_locale <- (locale_df$cost_constant_num_students_meeting_locale / locale_df$cost_constant_num_students_sample_locale) * locale_df$num_students_locale
locale_df$bw_constant_num_students_meeting_extrap_by_locale <- (locale_df$bw_constant_num_students_meeting_locale / locale_df$bw_constant_num_students_sample_locale) * locale_df$num_students_locale

locale_df$current_districts_meeting_perc <- (locale_df$current_districts_meeting_locale / locale_df$current_districts_sample_locale)
locale_df$max_cost_districts_meeting_perc <- (locale_df$max_cost_districts_meeting_locale / locale_df$max_cost_districts_sample_locale)
locale_df$cost_constant_districts_meeting_perc <- (locale_df$cost_constant_districts_meeting_locale / locale_df$cost_constant_districts_sample_locale)
locale_df$bw_constant_districts_meeting_perc <- (locale_df$bw_constant_districts_meeting_locale / locale_df$bw_constant_districts_sample_locale)

locale_df$cost_constant_total_erate_share_locale <- locale_df$cost_constant_total_pai_budg_locale - locale_df$cost_constant_total_pai_oop
locale_df$bw_constant_total_erate_share_locale <- locale_df$bw_constant_total_pai_budg_locale - locale_df$bw_constant_total_pai_oop
locale_df$max_cost_total_erate_share_locale <- locale_df$max_cost_total_pai_budg_locale - locale_df$max_cost_total_oop
locale_df$total_erate_share_locale <- locale_df$district_cost_total_locale - locale_df$total_current_oop

#creating a per student category df
locale_df_per_student <- locale_df
locale_df_per_student$cost_constant_total_per_student <- locale_df_per_student$cost_constant_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_total_per_student <- locale_df_per_student$bw_constant_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_total_per_student <- locale_df_per_student$max_cost_total_pai_budg_locale / locale_df_per_student$num_students_locale
locale_df_per_student$current_total_per_student <- locale_df_per_student$district_cost_total_locale / locale_df_per_student$num_students_locale
locale_df_per_student$cost_constant_erate_per_student <- locale_df_per_student$cost_constant_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_erate_per_student <- locale_df_per_student$bw_constant_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_erate_per_student <- locale_df_per_student$max_cost_total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$current_erate_per_student <- locale_df_per_student$total_erate_share_locale / locale_df_per_student$num_students_locale
locale_df_per_student$cost_constant_dist_per_student <- locale_df_per_student$cost_constant_total_pai_oop / locale_df_per_student$num_students_locale
locale_df_per_student$bw_constant_dist_per_student <- locale_df_per_student$bw_constant_total_pai_oop / locale_df_per_student$num_students_locale
locale_df_per_student$max_cost_dist_per_student <- locale_df_per_student$max_cost_total_oop / locale_df_per_student$num_students_locale
locale_df_per_student$current_dist_per_student <- locale_df_per_student$total_current_oop / locale_df_per_student$num_students_locale
locale_df_per_student <- locale_df_per_student[,c('locale','cost_constant_total_per_student','bw_constant_total_per_student','max_cost_total_per_student',
                                                  'current_total_per_student','cost_constant_erate_per_student','bw_constant_erate_per_student',
                                                  'max_cost_erate_per_student','current_erate_per_student','cost_constant_dist_per_student',
                                                  'bw_constant_dist_per_student','max_cost_dist_per_student','current_dist_per_student')]

locale_df$current_num_students_meeting_extrap <- locale_df$num_students_locale * current_num_students_meeting_extrap_perc
locale_df$max_cost_num_students_meeting_extrap <- locale_df$num_students_locale * max_cost_num_students_meeting_extrap_perc

##**************************************************************************************************************v

#creating a rural town rich df to look at discount rates
rich_df <- districts_display
rich_df <- subset(rich_df, rich_df$category == 'Rural_Town_Rich')
rich_students_df <- aggregate(rich_df$num_students, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_students_df) <- c('Adj C1 Discount Rate', 'Num Students')
rich_budget_pai_df <- aggregate(rich_df$district_budget_pai, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_budget_pai_df) <- c('Adj C1 Discount Rate', 'Pai Budget')
rich_budget_current_df <- aggregate(rich_df$district_cost_total, by=list(rich_df$adj_c1_discount_rate), FUN = sum)
names(rich_budget_current_df) <- c('Adj C1 Discount Rate', 'Current Budget')
rich_summary_df <- merge(x=rich_students_df, y=rich_budget_pai_df, by = 'Adj C1 Discount Rate')
rich_summary_df <- merge(x=rich_summary_df, y=rich_budget_current_df, by = 'Adj C1 Discount Rate')
rich_summary_df$pai_erate_share <- .75 * rich_summary_df$`Pai Budget`
rich_summary_df$current_erate_share <- (1-rich_summary_df$`Adj C1 Discount Rate`) * rich_summary_df$`Current Budget`


rich_c2_df <- aggregate(rich_df$num_students, by=list(rich_df$adjusted_c2), FUN = sum)

##************************************************************************************************************************
#Creating the summary tables by model and locale
models <- c('Today', 'Pai OOP', 'Same OOP', 'Pay to Keep BW')
locales <- locale_df$locale
locales_and_models <- NULL



for(i in 1:length(locales)) {
  for(j in 1:length(models)) {
    #locales_and_models = paste(locales[i], models[j], sep=' ')
    locales_and_models <- append(locales_and_models,paste(locales[i], models[j], sep=' - '))
  }
}

locales_and_models <- paste(rep(locale_df$locale, 4), c(rep("Today",4), rep("Pai_OOP",4), rep("Keep_BW",4), rep("Same_OOP",4)), sep="-")
summary_df <- data.frame(locales_and_models,
                         "total_funding"=c(locale_df$district_cost_total_locale, locale_df$cost_constant_total_pai_budg_locale,
                                           locale_df$bw_constant_total_pai_budg_locale, locale_df$max_cost_total_pai_budg_locale),
                         "erate_funding"=c(locale_df$district_cost_total_locale - locale_df$total_current_oop, 
                                           locale_df$cost_constant_total_erate_share_locale,
                                           locale_df$bw_constant_total_erate_share_locale,
                                           locale_df$max_cost_total_erate_share_locale),
                         "district_portion"=c(locale_df$total_current_oop, locale_df$cost_constant_total_pai_oop,
                                              locale_df$bw_constant_total_pai_oop, locale_df$max_cost_total_oop),
                         "students_meeting_goals_extrap"=c(locale_df$current_num_students_meeting_extrap_by_locale, 
                                                           locale_df$cost_constant_num_students_meeting_extrap_by_locale,
                                                           locale_df$bw_constant_num_students_meeting_extrap_by_locale, 
                                                           locale_df$max_cost_num_students_meeting_extrap_by_locale),
                         "total_funding_per_student"=c(locale_df_per_student$current_total_per_student, 
                                                       locale_df_per_student$cost_constant_total_per_student,
                                                       locale_df_per_student$bw_constant_total_per_student, 
                                                       locale_df_per_student$max_cost_total_per_student),
                         "erate_funding_per_student"=c(locale_df_per_student$current_erate_per_student, 
                                                       locale_df_per_student$cost_constant_erate_per_student,
                                                       locale_df_per_student$bw_constant_erate_per_student, 
                                                       locale_df_per_student$max_cost_erate_per_student),
                         "district_portion_per_student"=c(locale_df_per_student$current_dist_per_student, 
                                                          locale_df_per_student$cost_constant_dist_per_student,
                                                          locale_df_per_student$bw_constant_dist_per_student, 
                                                          locale_df_per_student$max_cost_dist_per_student),
                         "districts_meeting"=c(locale_df$current_districts_meeting_perc, 
                                               locale_df$cost_constant_districts_meeting_perc,
                                               locale_df$bw_constant_districts_meeting_perc, 
                                               locale_df$max_cost_districts_meeting_perc)
)


current_extrap_students_meeting <- sum(locale_df$current_num_students_meeting_extrap_by_locale)
cost_constant_extrap_students_meeting <- sum(locale_df$cost_constant_num_students_meeting_extrap_by_locale)
bw_constant_extrap_students_meeting <- sum(locale_df$bw_constant_num_students_meeting_extrap_by_locale)
max_cost_extrap_students_meeting <- sum(locale_df$max_cost_num_students_meeting_extrap_by_locale)

models <- c('Today', 'Pai OOP', 'Pay to Keep BW','Same OOP')
summary_models_total_df <- data.frame(models,
                                      "total_funding" = c(totals_df$district_cost_total,
                                                          totals_df$cost_constant_total_pai_budg,
                                                          totals_df$bw_constant_total_pai_budg,
                                                          totals_df$max_cost_total_pai_budg),
                                      "erate_funding" = c(totals_df$total_erate_share_category,
                                                          totals_df$cost_constant_total_erate_share,
                                                          totals_df$bw_constant_total_erate_share_category,
                                                          totals_df$max_cost_total_erate_share_category),
                                      "district_portion" = c(totals_df$total_current_oop,
                                                             totals_df$cost_constant_total_pai_oop,
                                                             totals_df$bw_constant_total_pai_oop,
                                                             totals_df$max_cost_total_oop),
                                      "total_funding_per_student" = c(totals_df_per_student$current_total_per_student,
                                                                      totals_df_per_student$cost_constant_total_per_student,
                                                                      totals_df_per_student$bw_constant_total_per_student,
                                                                      totals_df_per_student$max_cost_total_per_student),
                                      "erate_funding_per_student" = c(totals_df_per_student$current_erate_per_student,
                                                                      totals_df_per_student$cost_constant_erate_per_student,
                                                                      totals_df_per_student$bw_constant_erate_per_student,
                                                                      totals_df_per_student$max_cost_erate_per_student),
                                      "district_portion_per_student" = c(totals_df_per_student$current_dist_per_student,
                                                                         totals_df_per_student$cost_constant_dist_per_student,
                                                                         totals_df_per_student$bw_constant_dist_per_student,
                                                                         totals_df_per_student$max_cost_dist_per_student),
                                      "districts_meeting" = c(current_districts_meeting_perc,
                                                              cost_constant_districts_meeting_perc,
                                                              bw_constant_districts_meeting_perc,
                                                              max_cost_districts_meeting_perc),
                                      "students_meeting_goals_extrap" = c(current_extrap_students_meeting,
                                                                          cost_constant_extrap_students_meeting,
                                                                          bw_constant_extrap_students_meeting,
                                                                          max_cost_extrap_students_meeting)
)


#adding extrapoloated current num students meeting to districts display
locale_df$current_num_students_meeting_extrap_perc <- (locale_df$current_num_students_meeting_locale / locale_df$current_num_students_sample_locale)
districts_display$current_num_students_meeting_extrap_perc <- ifelse(districts_display$locale == 'Rural', locale_df[1,'current_num_students_meeting_extrap_perc'],
                                                                     ifelse(districts_display$locale == 'Suburban', locale_df[2,'current_num_students_meeting_extrap_perc'], 
                                                                            ifelse(districts_display$locale == 'Town', locale_df[3,'current_num_students_meeting_extrap_perc'],
                                                                                   locale_df[4,'current_num_students_meeting_extrap_perc'])))

districts_display$current_num_students_meeting_extrap <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & districts_display$include_in_universe_of_districts == TRUE,
                                                                districts_display$current_num_students_meeting,
                                                                districts_display$current_num_students_meeting_extrap_perc * districts_display$num_students)


#max cost
locale_df$max_cost_num_students_meeting_extrap_perc <- (locale_df$max_cost_num_students_meeting_locale / locale_df$max_cost_num_students_sample_locale)

districts_display$max_cost_num_students_meeting_extrap_perc <- ifelse(districts_display$locale == 'Rural', locale_df[1,'max_cost_num_students_meeting_extrap_perc'],
                                                                      ifelse(districts_display$locale == 'Suburban', locale_df[2,'max_cost_num_students_meeting_extrap_perc'], 
                                                                             ifelse(districts_display$locale == 'Town', locale_df[3,'max_cost_num_students_meeting_extrap_perc'],
                                                                                    locale_df[4,'max_cost_num_students_meeting_extrap_perc'])))

#districts_display$max_cost_num_students_meeting_extrap <- districts_display$max_cost_num_students_meeting_extrap_perc * districts_display$num_students
districts_display$max_cost_num_students_meeting_extrap <- ifelse(districts_display$exclude_from_ia_analysis == FALSE & 
                                                                   districts_display$include_in_universe_of_districts == TRUE &
                                                                   districts_display$ia_monthly_cost_per_mbps > 0 &
                                                                   districts_display$exclude_from_ia_cost_analysis == FALSE,
                                                                districts_display$max_cost_num_students_meeting,
                                                                districts_display$max_cost_num_students_meeting_extrap_perc * districts_display$num_students)

districts_display$total_current_erate_share <-districts_display$district_cost_total - districts_display$total_current_oop

write.csv(category_df_per_student, "data/processed/pai_analysis_per_student_spending.csv", row.names = FALSE)
write.csv(category_df, "data/processed/pai_analysis_category_spending.csv", row.names = FALSE)
write.csv(totals_df, "data/processed/pai_analysis_total_spending.csv", row.names = FALSE)
write.csv(totals_df_per_student, "data/processed/pai_analysis_total_per_student_spending.csv", row.names = FALSE)
write.csv(locale_df, "data/processed/locale_df.csv", row.names = FALSE)
write.csv(locale_df_per_student, "data/processed/locale_df_per_student.csv", row.names = FALSE)
write.csv(summary_df, "data/processed/summary_df.csv", row.names = FALSE)
write.csv(summary_models_total_df, "data/processed/summary_models_total_df.csv", row.names = FALSE)
write.csv(districts_display, "data/processed/districts_display.csv", row.names = FALSE)

