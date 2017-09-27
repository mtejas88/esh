## ======================================================================================================================
##
## Run regression on 2016 inputs and state match numbers in order to create predictions for a 
## recommended state match number (state_funding) between the min and max.
##
## Plan is to predict the MID-RANGE of the range Yasmin decided on for 2016 ("State Match Update - Feb 2017.pptx" slide 1)
## for 14 states using various state metrics (start with those used for the "advice" columns).
##      -Since there are so few datapoints, may try to use (Iteratively re-) Weighted Least Squares http://www.statisticshowto.com/weighted-least-squares/ 
##      -Will look at the confidence intervals and prediction intervals and compare to known estimated range
##      -Might look into bootstrapping
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

## will use fit.w and regw1 to run bootstrapping

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


#*****************************************************************************************************************
# Bootstrap 95% CI for regression predictions - using fixed X



# bootw1=bootCase(regw1, function(x)predict(x), B=999)
# 
# results=as.data.frame(cbind(as.data.frame(predict(regw1)), as.data.frame(apply(bootw1, 2, quantile, 0.025)),as.data.frame(apply(bootw1, 2, quantile, .975)), state.metrics.2016.14.regression$y_midrange, true_range_estimates, state.metrics.2016.14.regression$min_total_state_funding/1000000,state.metrics.2016.14.regression$max_total_state_funding/1000000))
# names(results) = c("fit","lwr","upr","y_midrange", "true_range_estimate", "data_min", "data_max")
# results = results %>% mutate(error = y_midrange - fit, pred_range = upr - lwr, data_range = data_max - data_min)
# results



