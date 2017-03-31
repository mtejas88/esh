library(dplyr)

districts_display <- read.csv("C:/Users/Justine/Documents/GitHub/ficher/Projects/pai_analysis/data/interim/districts_display.csv", as.is=T, header=T, stringsAsFactors=F)

#http://blogs.edweek.org/edweek/campaign-k-12/2017/03/trump_cut_teacher_funding_meaning_schools.html?cmp=eml-eb-popweek+03312017&M=57882870&U=1583176
#25% of the 2.3 billion title 2 funds go to paying 9000 teachers.
#More than half of school districts use Title II funds to pay for professional development, 
#and another quarter use it for class size reduction, according this August 2016 report on the program by the U.S. Department of Education. 
#The money for class-size reduction has helped pay for the salaries of nearly 9,000 teachers nationwide, according to the report.
#...instead of the current $2.3 billion.

cost_per_teacher <- (2300000000 * .25 )/ 9000

districts_display$bw_constant_ia_oop_increase <- districts_display$bw_constant_total_pai_oop - districts_display$total_current_oop
districts_display$bw_constant_ia_oop_increase_teachers <- districts_display$bw_constant_ia_oop_increase / cost_per_teacher 
districts_display$pct_teachers_lost <- ifelse( districts_display$bw_constant_ia_oop_increase_teachers < 0,
                                               0,
                                               districts_display$bw_constant_ia_oop_increase_teachers) / districts_display$num_teachers
districts_display$indic_teachers_lost <- ifelse(districts_display$pct_teachers_lost > .01,1,0)

#write.csv(districts_display, "C:/Users/Justine/Documents/GitHub/ficher/Projects/pai_analysis/data/interim/districts_display_teachers.csv", row.names = FALSE)

clean_districts <- filter(districts_display, exclude_from_ia_analysis == FALSE & num_teachers > 0)
clean_districts <- select(clean_districts, locale, bw_constant_ia_oop_increase, 
                          bw_constant_ia_oop_increase_teachers, num_teachers, pct_teachers_lost, indic_teachers_lost)

#evans mental math
#160M -- estimate of funding lost in rural districts
#100,000 -- salary
#1,600 -- teachers lost

clean_by_locale <- group_by(clean_districts, locale)
summ_clean_by_locale <- summarise(clean_by_locale,
                                  agg_ia_oop_increase = sum(bw_constant_ia_oop_increase),
                                  agg_ia_oop_increase_teachers = sum(bw_constant_ia_oop_increase_teachers),
                                  agg_pct_teachers_lost=sum(bw_constant_ia_oop_increase_teachers)/sum(num_teachers),
                                  pct_teachers_lost_median=median(pct_teachers_lost),
                                  clean_districts_missing_teachers = sum(indic_teachers_lost),
                                  clean_districts = n(),
                                  clean_teachers = sum(num_teachers))

all_by_locale <- group_by(districts_display, locale)
summ_all_by_locale <- summarise(all_by_locale, 
                                all_districts = n(),
                                all_teachers = sum(num_teachers))

summ_by_locale <- summ_clean_by_locale %>% inner_join(summ_all_by_locale)
summ_by_locale <- mutate(summ_by_locale, 
                         extrap_oop_increase = agg_ia_oop_increase*(all_districts/clean_districts),
                         extrap_tchr_decrease = agg_ia_oop_increase_teachers*(all_teachers/clean_teachers),
                         pct_districts_tchr_decrease = clean_districts_missing_teachers/clean_districts)

select(summ_by_locale, locale, extrap_oop_increase, extrap_tchr_decrease, agg_pct_teachers_lost, pct_districts_tchr_decrease)
