### Predicting Districts Meeting Goals ###
library(class)
library(caret)
library(dplyr)

raw <- read.csv('raw_update.csv') # predictors
ver <- read.csv('verified_update.csv') # outcome
ver <- ver[!is.na(ver$ia_bandwidth_per_student),]
sort(raw$esh_id) == sort(ver$esh_id)
nrow(ver)
raw <- raw %>% arrange(esh_id)
ver <- ver %>% arrange(esh_id)

table(raw$esh_id == ver$esh_id)

class(raw$ia_bandwidth_per_student)
class(ver$ia_bandwidth_per_student)

raw$ia_bandwidth_per_student <- as.numeric(as.character(raw$ia_bandwidth_per_student))
ver$ia_bandwidth_per_student <- as.numeric(as.character(ver$ia_bandwidth_per_student))
table(raw$ia_bandwidth_per_student == ver$ia_bandwidth_per_student)

joined <- merge(ver[,c(1,5)], raw, by.x="esh_id", by.y="esh_id")
joined$band_diff <- joined$ia_bandwidth_per_student.x - joined$ia_bandwidth_per_student.y
diffs <- joined$band_diff[joined$band_diff != 0]
hist(diffs, col='dodgerblue', border='white', xlab='Diffs in Kbps Per Student', main="Changed Bandwidth Distribution")
mean(diffs, na.rm=T)
table(joined$ia_bandwidth_per_student.x == joined$ia_bandwidth_per_student.y)

joined$meets_goals <- ifelse(joined$ia_bandwidth_per_student.x >= 100, 1, 0)
mean(joined$meets_goals, na.rm=T)
colnames(joined)
joined <- joined[!is.na(joined$meets_goals),]
joined <- joined[!is.na(joined$ia_bandwidth_per_student.y),]
#joined$meets_goals <- ifelse(joined$ia_bandwidth_per_student.x >= 100, 1, 0)
#mean(joined$meets_goals, na.rm = T)
View(joined)
nrow(joined)

### Validation Set ###
data.size <- nrow(joined)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size
train_vector <- sample(data.size, train.size)

### Model ###
library(randomForest)
connect.forest <- randomForest(as.factor(meets_goals) ~ ia_bandwidth_per_student.y + locale + 
                                 num_students + num_schools + percentage_fiber, 
                                 data=joined[train_vector,], importance=T, ntree=501)

#connect.forest <- randomForest(as.numeric(ia_bandwidth_per_student.x) ~ ia_bandwidth_per_student.y + locale + num_students + num_schools + percentage_fiber, data=joined[train_vector,], importance=T, ntree=501)
connect.forest$importance
predict.forest <- predict(connect.forest, joined[-train_vector,])
#bw_predictions <- data.frame(cbind(predict.forest, joined[-train_vector, 2]))
#bw_predictions$diff <- bw_predictions$V2 - bw_predictions$predict.forest
View(bw_predictions)
options(scipen=100)
#hist(bw_predictions$diff, col="dodgerblue", xlim=c(-5000,5000), breaks=30)
table(predict.forest)
confusionMatrix(predict.forest, reference=joined[-train_vector, 42])
connect.forest
colnames(joined)

### All Districts ###
dists <- dbGetQuery(con, '
                    select * from districts')
dists$ia_bandwidth_per_student.y <- dists$ia_bandwidth_per_student
dists$ia_bandwidth_per_student.y <- as.numeric(as.character(dists$ia_bandwidth_per_student.y))
dists$num_schools <- as.numeric(as.character(dists$num_schools))
dists$num_students <- as.numeric(as.character(dists$num_students))
dists$predicted <- predict(connect.forest, dists)
dists$num_schools <- as.integer(dists$num_schools)
dists$num_students <- as.integer(dists$num_students)
dists$locale <- as.factor(dists$locale)
dists$percentage_fiber <- as.factor(dists$percentage_fiber)
View(dists)

typeof(joined$ia_bandwidth_per_student.y)  == typeof(dists$ia_bandwidth_per_student.y)
typeof(joined$num_schools)  == typeof(dists$num_schools)  

typeof(joined$locale)  == typeof(dists$locale)
typeof(joined$num_students)  == typeof(dists$num_students)  
typeof(joined$percentage_fiber)  == typeof(dists$percentage_fiber)  

dists$predicted <- predict(connect.forest, dists)
View(dists)
mean(as.numeric(as.character(dists$predicted)), na.rm=T)
dists$according_to_data <- ifelse(dists$ia_bandwidth_per_student.y >= 100, 1, 0)
mean(dists$according_to_data, na.rm=T)
table(dists$according_to_data, dists$predicted)

write.csv(dists, 'dists_with_predictions.csv')

### In Universe - calculating meeting goals for all districts ###
dirty_meet <- .6707
clean_meet <- .7638
all <- .7407
clean <- 7247
dirty <- 5778
total <- clean + dirty
max_dirty_meet <- (dirty_meet + .04) * dirty
min_dirty_meet <- (dirty_meet - .04) * dirty
(clean * clean_meet + max_dirty_meet) /  total
(clean * clean_meet + min_dirty_meet) /  total

### Ad hoc request from Evan 2/19
setwd("~/Desktop/R Projects/Meeting Goals Prediction")
dists_predict <- read.csv('dists_with_predictions.csv')

# Load NCES ethnic group data
eth_query <- "
  select districts.postal_cd, sc.\"NCESSCH\", sc.id, sc.\"HISP\", schools.esh_id, schools.district_esh_id,schools.school_nces_cd, schools.num_students,
    districts.num_students as num_students_district, districts.num_schools, districts.ia_bandwidth_per_student, districts.*
  from sc121a sc
  left join schools
  on sc.\"NCESSCH\" = schools.school_nces_cd
  left join districts
  on schools.district_esh_id = districts.esh_id
  where schools.charter = false
  and schools.max_grade_level != 'PK'
  and exclude_from_analysis = false
  and include_in_universe_of_districts = true
  order by districts.num_schools, sc.\"NCESSCH\""

eth <- dbGetQuery(con, eth_query)
nrow(eth)
View(eth)
# Callculate percent of Latino students that are meeting goals, by state and nationally
library(sqldf)
library(dplyr)
# exclude dirty, and universe
colnames(eth)
eth <- eth[,-c(1,23,25,40,11)]
eth$ia_bandwidth_per_student <- as.numeric(as.character(eth$ia_bandwidth_per_student))
eth$meeting_goals <- ifelse(eth$ia_bandwidth_per_student >=100, 1, 0)

eth_sub <- eth %>% filter(HISP > 0) %>% filter(!is.na(ia_bandwidth_per_student)) %>% 
    filter(!is.na(num_students))

nrow(eth_sub)

### By State ### 
eth_sub$num_students <- as.numeric(as.character(eth_sub$num_students))
eth_goals <- eth_sub %>% group_by(postal_cd, meeting_goals) %>% summarise(sum_students = sum(num_students, na.rm=T))
eth_goals_percent <- eth_goals %>% mutate(total_meeting = meeting_goals*sum_students) %>%
                    group_by(postal_cd) %>% summarise(total = sum(sum_students), total_meeting_sum = sum(total_meeting)) %>%
                    mutate(percent_meeting = total_meeting_sum / total)

hisp_goals <- eth_sub %>% group_by(postal_cd, meeting_goals) %>% summarise(sum_students = sum(HISP, na.rm=T))
hisp_goals_percent <- hisp_goals %>% mutate(total_meeting = meeting_goals*sum_students) %>%
  group_by(postal_cd) %>% summarise(hisp_total = sum(sum_students), hisp_total_meeting_sum = sum(total_meeting)) %>%
  mutate(hisp_percent_meeting = hisp_total_meeting_sum / hisp_total)

final_goals <- merge(eth_goals_percent, hisp_goals_percent, by.x="postal_cd", by.y="postal_cd")
View(final_goals)
write.csv(final_goals, 'goals_by_state_ethnic_group.csv')
write.csv(eth_sub, 'raw_goals.csv')

### National ###
eth_sub$num_students <- as.numeric(as.character(eth_sub$num_students))
eth_goals <- eth_sub %>% group_by(meeting_goals) %>% summarise(sum_students = sum(num_students, na.rm=T))
eth_goals_percent <- eth_goals %>% mutate(total_meeting = meeting_goals*sum_students) %>%
  summarise(total=sum(sum_students), total_meeting = sum(total_meeting)) %>%
  mutate(percent_meeting = total_meeting / total)

hisp_goals <- eth_sub %>% group_by(meeting_goals) %>% summarise(sum_students = sum(HISP, na.rm=T))
hisp_goals_percent <- hisp_goals %>% mutate(total_meeting = meeting_goals*sum_students) %>%
  summarise(hisp_total=sum(sum_students), hisp_total_meeting = sum(total_meeting)) %>%
  mutate(hisp_percent_meeting = hisp_total_meeting / hisp_total)

final_goals_national <- cbind(eth_goals_percent, hisp_goals_percent)
View(final_goals_national)
write.csv(final_goals_national, 'goals_national_by_ethnic_group.csv')
