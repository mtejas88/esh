## ======================================================================================================================
##
## Run regression on 2016 inputs and state match numbers in order to create predictions for a 
## recommended state match number (state_funding) between the min and max.
##
## Plan is to predict the MID-RANGE of the range Yasmin decided on for 2016 ("State Match Update - Feb 2017.pptx" slide 1)
## for 14 states using various state metrics (start with those used for the "advice" columns).
##      -Since there are so few datapoints, may try to use (Iteratively re-) Weighted Least Squares http://www.statisticshowto.com/weighted-least-squares/ 
##      -Will look at the confidence intervals and prediction intervals and compare to known estimated range
## ======================================================================================================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("dplyr","tidyr","ggplot2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(dplyr)
library(tidyr)

## read in data
state.metrics.2016 <- read.csv("state_metrics.csv", as.is=T, header=T, stringsAsFactors=F)

## filter for the 14 states
state.metrics.2016.14 = state.metrics.2016 %>% filter(district_postal_cd %in% c('AZ','CO','IL','IN','KS','MA','MD','MN','MT','NV','NH','TX','OR','WY'))

## define decision ratio columns
state.metrics.2016.14$ratio_miles_per_build = state.metrics.2016.14$max_miles_per_build/state.metrics.2016.14$min_miles_per_build
state.metrics.2016.14$ratio_total_cost_wan = ifelse((state.metrics.2016.14$total_cost_az_pop_wan - state.metrics.2016.14$min_total_cost_wan) > 0,
                                                    (state.metrics.2016.14$total_cost_az_wan - state.metrics.2016.14$min_total_cost_wan)/(state.metrics.2016.14$total_cost_az_pop_wan - state.metrics.2016.14$min_total_cost_wan),
                                                    (state.metrics.2016.14$total_cost_az_pop_wan - state.metrics.2016.14$min_total_cost_wan)/(state.metrics.2016.14$total_cost_az_wan - state.metrics.2016.14$min_total_cost_wan))

state.metrics.2016.14.regression = state.metrics.2016.14[, names(state.metrics.2016.14) %in% c("district_postal_cd",'ratio_miles_per_build','ratio_total_cost_wan','min_total_state_funding','max_total_state_funding')]

## add mid-range to predict
state.metrics.2016.14.regression$y_midrange = c((8+13)/2,
                                                (2+4)/2,
                                                (5+8)/2,
                                                (1+3)/2,
                                                (1+3)/2,
                                                (4+7)/2,
                                                (2+4)/2,
                                                (1.5+3)/2,
                                                (5+8)/2,
                                                (2+4)/2,
                                                (5+8)/2,
                                                (3+5)/2,
                                                (15+20)/2,
                                                (3+5)/2)

true_range_estimates = c('8-13',
                         '2-4',
                         '5-8',
                         '1-3',
                         '1-3',
                         '4-7',
                         '2-4',
                         '1.5-3',
                         '5-8',
                         '2-4',
                         '5-8',
                         '3-5',
                         '15-20',
                         '3-5')

## drop postal cd
state.metrics.2016.14.regression = state.metrics.2016.14.regression[,2:ncol(state.metrics.2016.14.regression)]

#*****************************************************************************************************************
## regular regression
reg = lm(y_midrange ~ ., data = state.metrics.2016.14.regression)
summary(reg) #not good
influence.measures(reg) # MD is problematic
plot(reg$fitted.values,reg$residuals)

## WLS1 (based on min_total_state_funding, which seems to be the most important predictor):
regw1 = lm(y_midrange ~ ., weights=min_total_state_funding^-2, data = state.metrics.2016.14.regression)
summary(regw1) #better, (smallest residuals) but could be overfitting 

## WLS2 (fitted values):
w=1/reg$fitted.values
regw.1 = lm(y_midrange ~ ., weights=w, data = state.metrics.2016.14.regression)
summary(regw.1) #not that good - eliminate

w=1/(reg$fitted.values^2)
regw.2 = lm(y_midrange ~ ., weights=w, data = state.metrics.2016.14.regression)
summary(regw.2) #better in terms of R^2 and coefficient SEs

## Iterative, to improve
fit.w = reg
for (i in 1:100) {
  w = 1/(fit.w$fitted.values^2)
  fit.w = lm(y_midrange ~ ., weights=w, data = state.metrics.2016.14.regression)
} #confirmed with more iterations that this has converged

summary(fit.w)

## visualize
plot(reg,which=2)
plot(regw1,which=2)
plot(fit.w,which=2)

## results with CI
result_table = function(model,int) {
  results=as.data.frame(cbind(as.data.frame(predict(model,interval=int)), state.metrics.2016.14.regression$y_midrange, true_range_estimates, ((state.metrics.2016.14.regression$min_total_state_funding/1000000) + (state.metrics.2016.14.regression$max_total_state_funding/1000000))/2,state.metrics.2016.14.regression$min_total_state_funding/1000000,state.metrics.2016.14.regression$max_total_state_funding/1000000))
  names(results) = c("fit","lwr","upr","y_midrange", "true_range_estimate", "data_midrange","data_min", "data_max")
  results = results %>% mutate(error = y_midrange - fit, pred_range = upr - lwr, data_range = data_max - data_min)
  return(results)
}

reg.results_c=result_table(reg,"c")
regw1.results_c=result_table(regw1,"c")
fit.w.results_c=result_table(fit.w,"c")
reg.results_c #predicted value is outside the range too much
regw1.results_c #5or6/14x, model range > data range; 2/14x the predicted value was outside true range, data is 5x
fit.w.results_c #4/14x, model range > data range; 3/14x the predicted value was outside true range, data is 5x

saveRDS(regw1, "regw1.rds")
saveRDS(fit.w, "fit.w")
#*****************************************************************************************************************
##### 2017 data
state.metrics.2017 <- read.csv("../../data/state_metrics.csv", as.is=T, header=T, stringsAsFactors=F)
state.metrics.2017 <- state.metrics.2017[state.metrics.2017$min_total_state_funding >0,]

state.metrics.2017$ratio_miles_per_build = state.metrics.2017$max_miles_per_build/state.metrics.2017$min_miles_per_build
state.metrics.2017$ratio_total_cost_wan = ifelse((state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan) > 0,
                                                 (state.metrics.2017$total_cost_az_wan - state.metrics.2017$min_total_cost_wan)/(state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan),
                                                 (state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan)/(state.metrics.2017$total_cost_az_wan - state.metrics.2017$min_total_cost_wan))

state.metrics.2017.regression = state.metrics.2017[, names(state.metrics.2017) %in% c('ratio_miles_per_build','ratio_total_cost_wan','min_total_state_funding','max_total_state_funding')]

regw1_pred = as.data.frame(predict(regw1,newdata = state.metrics.2017.regression))
names(regw1_pred) = c("regw1_pred")
fit.w_pred = as.data.frame(predict(fit.w,newdata = state.metrics.2017.regression))
names(fit.w_pred) = c("fit.w_pred")

result_export=as.data.frame(cbind(state.metrics.2017$district_postal_cd, state.metrics.2017$min_total_state_funding/1000000,state.metrics.2017$max_total_state_funding/1000000, regw1_pred, fit.w_pred))
names(result_export) = c("postal_cd", "min_2017", "max_2017", "prediction_wm", "prediction_wf")

dim(result_export[result_export$prediction_wm < 0,])
dim(result_export[result_export$prediction_wf < 0,])

result_export = result_export %>% mutate(prediction=ifelse(prediction_wm < min_2017 , min_2017, prediction_wm))
result_export = result_export[, names(result_export) %in% c("postal_cd", "min_2017", "max_2017", "prediction")]
result_export = result_export %>% mutate(prediction_lwr = 
                                           ifelse(result_export$prediction == result_export$min_2017,result_export$min_2017,
                                                  result_export$prediction - (.2*result_export$prediction)),
                                         prediction_upr = 
                                           ifelse(result_export$prediction >= result_export$max_2017,result_export$max_2017,
                                                  result_export$prediction + (.2*result_export$prediction)))
result_export$approved_state = ifelse(result_export$postal_cd %in% c('AZ',
                                                                     'CO',
                                                                     'FL',
                                                                     'ID',
                                                                     'MA',
                                                                     'MD',
                                                                     'ME',
                                                                     'MO',
                                                                     'MT',
                                                                     'NC',
                                                                     'NH',
                                                                     'NM',
                                                                     'NV',
                                                                     'NY',
                                                                     'OK',
                                                                     'TX',
                                                                     'VA'),"Already approved/known","To estimate")

write.csv(result_export, file = "initial_results_2017.csv")

#*****************************************************************************************************************


