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
districts_display$teachers_lost_with_oop_increase <- ifelse(districts_display$bw_constant_ia_oop_increase / cost_per_teacher < 0,
                                                            0,
                                                            districts_display$bw_constant_ia_oop_increase / cost_per_teacher)
districts_display$pct_teachers_lost <- districts_display$teachers_lost_with_oop_increase / districts_display$num_teachers
districts_display$indic_teachers_lost <- ifelse(districts_display$pct_teachers_lost > .01,1,0)
districts_display$schools_teachers_lost <- ifelse(districts_display$pct_teachers_lost > .01,districts_display$num_schools,0)

write.csv(districts_display, "C:/Users/Justine/Documents/GitHub/ficher/Projects/pai_analysis/data/interim/districts_display_teachers.csv", row.names = FALSE)

clean_districts <- filter(districts_display, exclude_from_ia_analysis == FALSE & num_teachers > 0)
clean_districts <- select(clean_districts, locale, bw_constant_ia_oop_increase, num_schools,
                          teachers_lost_with_oop_increase, num_teachers, pct_teachers_lost, 
                          indic_teachers_lost, schools_teachers_lost)

#evans mental math
#160M -- estimate of funding lost in rural districts
#100,000 -- salary
#1,600 -- teachers lost

clean_by_locale <- group_by(clean_districts, locale)
summ_clean_by_locale <- summarise(clean_by_locale,
                                  agg_ia_oop_increase = sum(bw_constant_ia_oop_increase),
                                  teachers_lost_with_oop_increase = sum(teachers_lost_with_oop_increase),
                                  agg_pct_teachers_lost=sum(teachers_lost_with_oop_increase)/sum(num_teachers),
                                  pct_teachers_lost_median=median(pct_teachers_lost),
                                  clean_districts_missing_teachers = sum(indic_teachers_lost),
                                  clean_schools_missing_teachers = sum(schools_teachers_lost),
                                  clean_districts = n(),
                                  clean_teachers = sum(num_teachers),
                                  clean_schools = sum(num_schools))

all_by_locale <- group_by(districts_display, locale)
summ_all_by_locale <- summarise(all_by_locale, 
                                all_districts = n(),
                                all_teachers = sum(num_teachers),
                                all_schools = sum(num_schools))

summ_by_locale <- summ_clean_by_locale %>% inner_join(summ_all_by_locale)
summ_by_locale <- mutate(summ_by_locale,
                         schools_per_district = all_schools/all_districts,
                         teachers_per_school = all_teachers/all_schools,  
                         teachers_per_district = all_teachers/all_districts,  
                         extrap_oop_increase = agg_ia_oop_increase*(all_districts/clean_districts),
                         extrap_tchr_decrease = teachers_lost_with_oop_increase*(all_teachers/clean_teachers),
                         extrap_schl_decrease = (clean_schools_missing_teachers/schools_per_district)*(all_schools/clean_schools),
                         extrap_dist_decrease = (clean_districts_missing_teachers)*(all_districts/clean_districts),
                         teachers_per_school_decrease = extrap_tchr_decrease/extrap_schl_decrease,
                         teachers_per_district_lost = extrap_tchr_decrease/clean_districts_missing_teachers,
                         pct_districts_tchr_decrease = extrap_tchr_decrease/all_districts)

view1 <- select(summ_by_locale, locale, extrap_tchr_decrease, extrap_schl_decrease, teachers_per_school_decrease, teachers_per_school)
view2 <- select(summ_by_locale, locale, extrap_tchr_decrease, extrap_dist_decrease, teachers_per_district_lost, teachers_per_district, schools_per_district)
notused <- select(summ_by_locale, locale, clean_teachers, agg_pct_teachers_lost, pct_districts_tchr_decrease, extrap_oop_increase, all_teachers, all_schools, all_districts, schools_per_district)
view1all <- summarise(view1, 
                      extrap_tchr_decrease = sum(extrap_tchr_decrease),
                      extrap_schl_decrease = sum(extrap_schl_decrease),
                      teachers_per_school_decrease = extrap_tchr_decrease/extrap_schl_decrease)
view2all <- summarise(view2, 
                      extrap_tchr_decrease = sum(extrap_tchr_decrease),
                      extrap_dist_decrease = sum(extrap_dist_decrease),
                      teachers_per_district_lost = extrap_tchr_decrease/extrap_dist_decrease)
view3all <- summarise(notused, 
                      teachers_per_school = sum(all_teachers)/sum(all_schools), 
                      teachers_per_district = sum(all_teachers)/sum(all_districts))

