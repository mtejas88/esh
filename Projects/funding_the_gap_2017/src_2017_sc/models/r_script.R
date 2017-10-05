state.metrics.2017 <- state.metrics.2017[state.metrics.2017$min_total_state_funding >0,]

state.metrics.2017$ratio_miles_per_build = state.metrics.2017$max_miles_per_build/state.metrics.2017$min_miles_per_build
state.metrics.2017$ratio_total_cost_wan = ifelse((state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan) > 0,
                                                 (state.metrics.2017$total_cost_az_wan - state.metrics.2017$min_total_cost_wan)/(state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan),
                                                 (state.metrics.2017$total_cost_az_pop_wan - state.metrics.2017$min_total_cost_wan)/(state.metrics.2017$total_cost_az_wan - state.metrics.2017$min_total_cost_wan))

state.metrics.2017.regression = state.metrics.2017[, names(state.metrics.2017) %in% c('ratio_miles_per_build','ratio_total_cost_wan','min_total_state_funding','max_total_state_funding')]

model <- readRDS("../state_match_fund_regression/regw1.rds")
pred = as.data.frame(predict(model,newdata = state.metrics.2017.regression))
names(pred) = c("pred")

result_export=as.data.frame(cbind(state.metrics.2017$district_postal_cd, state.metrics.2017$min_total_state_funding/1000000,state.metrics.2017$max_total_state_funding/1000000, pred))
names(result_export) = c("postal_cd", "min_2017", "max_2017", "prediction")

result_export$prediction=ifelse(result_export$prediction < result_export$min_2017 , result_export$min_2017, result_export$prediction)

result_export$prediction_lwr = ifelse(result_export$prediction == result_export$min_2017,result_export$min_2017,
                                      result_export$prediction - (.2*result_export$prediction))
result_export$prediction_upr = ifelse(result_export$prediction >= result_export$max_2017,result_export$max_2017,
                                                  result_export$prediction + (.2*result_export$prediction))

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