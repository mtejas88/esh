
##first run machine_learn_clean_2.R
##this is to assess cleanliness of a district after its dirty line items are machine learned

setwd("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Data Strategy/Machine Learn Clean")
library(dplyr)

### DETERMINE CLEANLINESS BASED ON PREDICTION
##line_item
##unknown_conn_type, rare_conn_type, fiber_lowbandwidth, product_bandwidth: cleaned by changing connect_type
##unknown_purpose, not_ia, Wan_Product: cleaned by changing purpose

##entity
##district_missing_ia: cleaned when district receives newly cleaned line item with change to internet or isp
##district_dirty_services_received: cleaned all districts dirty services have only above flags, and corresponding
##                                  field was changed
##district_ia_only_missing_transport: district has a line item changed to Internet, or
##                                    district has a line item changed to Upstream


svcs_to_district <- read.csv('services_received_for_district_cleanliness.csv')
svcs_to_district$dirty_line_item_level_flags <- as.character(svcs_to_district$dirty_line_item_level_flags)
svcs_to_district$connect_cat_flag_indic <- ifelse( grepl('unknown_conn_type', svcs_to_district$dirty_line_item_level_flags), as.integer(1), as.integer(0))
svcs_to_district$connect_cat_flag_indic <- ifelse( grepl('rare_conn_type', svcs_to_district$dirty_line_item_level_flags), 
                                                   as.integer(1), 
                                                   svcs_to_district$connect_cat_flag_indic)
svcs_to_district$connect_cat_flag_indic <- ifelse( grepl('fiber_lowbandwidth', svcs_to_district$dirty_line_item_level_flags), 
                                                   as.integer(1), 
                                                   svcs_to_district$connect_cat_flag_indic)
svcs_to_district$connect_cat_flag_indic <- ifelse( grepl('product_bandwidth', svcs_to_district$dirty_line_item_level_flags), 
                                                   as.integer(1), 
                                                   svcs_to_district$connect_cat_flag_indic)
svcs_to_district$purpose_flag_indic <- ifelse( grepl('unknown_purpose', svcs_to_district$dirty_line_item_level_flags), as.integer(1), as.integer(0))
svcs_to_district$purpose_flag_indic <- ifelse( grepl('not_ia', svcs_to_district$dirty_line_item_level_flags), 
                                               as.integer(1), 
                                               svcs_to_district$purpose_flag_indic)
svcs_to_district$purpose_flag_indic <- ifelse( grepl('wan_product', svcs_to_district$dirty_line_item_level_flags), 
                                               as.integer(1), 
                                               svcs_to_district$purpose_flag_indic)
svcs_to_district$purpose_flag_indic <- ifelse( grepl('telecom_voice', svcs_to_district$dirty_line_item_level_flags), 
                                               as.integer(1), 
                                               svcs_to_district$purpose_flag_indic)

svcs_to_district$remaining_flag_indic <- ifelse( grepl('zero_values', svcs_to_district$dirty_line_item_level_flags), 
                                                                 as.integer(1),
                                                                 ifelse( grepl('outliers', svcs_to_district$dirty_line_item_level_flags), 
                                                                         as.integer(1), 0))


svcs_to_district$purpose_and_cc_flag_indic <- ifelse( svcs_to_district$purpose_flag_indic == 1,
                                                      ifelse(svcs_to_district$connect_cat_flag_indic == 1, 
                                                             ifelse(svcs_to_district$remaining_flag_indic == 0, 1, 0),0),0)
svcs_to_district$purpose_only_flag_indic <- ifelse(svcs_to_district$remaining_flag_indic == 0, 
                                                   svcs_to_district$purpose_flag_indic - svcs_to_district$purpose_and_cc_flag_indic, 0)
svcs_to_district$cc_only_flag_indic <- ifelse(svcs_to_district$remaining_flag_indic == 0,
                                              svcs_to_district$connect_cat_flag_indic - svcs_to_district$purpose_and_cc_flag_indic, 0)

x <- svcs_to_district
x <- x %>% 
  group_by(district_esh_id) %>% 
  summarise(line_item_flags_cant_be_fixed_ml = sum(remaining_flag_indic))
y <- svcs_to_district
y <- y %>% 
  group_by(district_esh_id) %>% 
  summarise(line_item_flag_purpose_only = sum(purpose_only_flag_indic))
z <- svcs_to_district
z <- z %>% 
  group_by(district_esh_id) %>% 
  summarise(line_item_flag_cc_only = sum(cc_only_flag_indic))
a <- svcs_to_district
a <- a %>% 
  group_by(district_esh_id) %>% 
  summarise(line_item_flag_purpose_and_cc = sum(purpose_and_cc_flag_indic))
districts <- unique(svcs_to_district[,c('district_esh_id','dirty_entity_level_flags','dirty_entity_level_flag_count')])
districts <- merge(x = x, y = districts, by = 'district_esh_id')
districts <- merge(x = y, y = districts, by = 'district_esh_id')
districts <- merge(x = z, y = districts, by = 'district_esh_id')
districts <- merge(x = a, y = districts, by = 'district_esh_id')
# districts$able_to_be_ml_cleaned <- ifelse(districts$line_item_flags_cant_be_fixed_ml==0,TRUE,FALSE)
# districts$able_to_be_ml_cleaned <- ifelse(districts$dirty_entity_level_flag_count==1,
#                                           ifelse(grepl('call_to_clarify',districts$dirty_entity_level_flags),
#                                                  FALSE,
#                                                  ifelse(grepl('district_dirty_services_received', districts$dirty_entity_level_flags),
#                                                         districts$able_to_be_ml_cleaned, 
#                                                         FALSE)),
#                                           ifelse(grepl('call_to_clarify', districts$dirty_entity_level_flags),
#                                                  FALSE,
#                                                 districts$able_to_be_ml_cleaned))

line_items_predicted <- read.csv("orig_verif_predict_cross_all_2015.csv")

line_items_predicted <- line_items_predicted[!is.na(line_items_predicted$predicted_cc),]  
line_items_predicted <- line_items_predicted[!is.na(line_items_predicted$predicted_purpose),] 
line_items_predicted <- line_items_predicted[line_items_predicted$count_recipient_districts > 0,]
line_items_predicted <- line_items_predicted[line_items_predicted$number_of_dirty_line_item_flags > 0,]
line_items_predicted$line_item_id <- line_items_predicted$production_id

line_items_predicted_received <- merge(x = line_items_predicted, y = svcs_to_district, by = 'line_item_id')


line_items_predicted_received$cleaned_indic <- ifelse(line_items_predicted_received$purpose_and_cc_flag_indic == 1,
                                                      ifelse(as.character(line_items_predicted_received$purpose_same) == 'FALSE',
                                                             ifelse(as.character(line_items_predicted_received$cc_same) == 'FALSE',1,0),0),0)
line_items_predicted_received$cleaned_indic <- ifelse(line_items_predicted_received$purpose_only_flag_indic == 1,
                                                      ifelse(as.character(line_items_predicted_received$purpose_same) == 'FALSE',
                                                             ifelse(as.character(line_items_predicted_received$cc_same) != 'FALSE',1,0),0),
                                                      line_items_predicted_received$cleaned_indic)
line_items_predicted_received$cleaned_indic <- ifelse(line_items_predicted_received$cc_only_flag_indic == 1,
                                                      ifelse(as.character(line_items_predicted_received$purpose_same) != 'FALSE',
                                                             ifelse(as.character(line_items_predicted_received$cc_same) == 'FALSE',1,0),0),
                                                      line_items_predicted_received$cleaned_indic)

b <- line_items_predicted_received
b <- b %>% 
  group_by(district_esh_id) %>% 
  summarise(cleaned_line_items = sum(cleaned_indic))

districts <- merge(x = b, y = districts, by = 'district_esh_id')

line_items_predicted_received$district_ia_indic <- ifelse(line_items_predicted_received$cleaned_indic == 1,
                                                          ifelse(as.character(line_items_predicted_received$predicted_purpose) == 'ISP',1,
                                                                 ifelse(as.character(line_items_predicted_received$predicted_purpose) == 'Internet',1,0)),0)
c <- line_items_predicted_received
c <- c %>% 
  group_by(district_esh_id) %>% 
  summarise(district_ia_indic = sum(district_ia_indic))

districts <- merge(x = c, y = districts, by = 'district_esh_id')


line_items_predicted_received$district_miss_transp_indic <- ifelse(line_items_predicted_received$cleaned_indic == 1,
                                                                   ifelse(as.character(line_items_predicted_received$predicted_purpose) == 'Upstream',1,
                                                                          ifelse(as.character(line_items_predicted_received$predicted_purpose) == 'Internet',1,0)),0)
d <- line_items_predicted_received
d <- d %>% 
  group_by(district_esh_id) %>% 
  summarise(district_miss_transp_indic = sum(district_miss_transp_indic))

districts <- merge(x = d, y = districts, by = 'district_esh_id')

districts$district_dirty_indic <- ifelse(districts$cleaned_line_items ==  districts$line_item_flag_purpose_and_cc + 
                                           districts$line_item_flag_cc_only + 
                                           districts$line_item_flag_purpose_only + 
                                           districts$line_item_flags_cant_be_fixed_ml, 1, 0)

districts$call_to_clarify <- ifelse( grepl('call_to_clarify', as.character(districts$dirty_entity_level_flags)), 1, 0)
districts$district_dirty_services_received <- ifelse( grepl('district_dirty_services_received', as.character(districts$dirty_entity_level_flags)), 1, 0)
districts$district_missing_ia <- ifelse( grepl('district_missing_ia', as.character(districts$dirty_entity_level_flags)), 1, 0)
districts$district_ia_only_missing_transport <- ifelse( grepl('district_ia_only_missing_transport', as.character(districts$dirty_entity_level_flags)), 1, 0)

districts$district_dirty_indic_2 <- ifelse(districts$district_dirty_services_received == 1, 
                                           ifelse(districts$district_dirty_indic > 0, 1, 0), 0)
districts$district_miss_transp_indic_2 <- ifelse(districts$district_ia_only_missing_transport == 1, 
                                                 ifelse(districts$district_miss_transp_indic > 0, 1, 0), 0)
districts$district_ia_indic_2 <- ifelse(districts$district_missing_ia == 1, 
                                        ifelse(districts$district_ia_indic > 0, 1, 0), 0)

districts$cleaned_indic <- ifelse( as.numeric(districts$dirty_entity_level_flag_count) == districts$district_dirty_indic_2 + 
                                     districts$district_miss_transp_indic_2 + 
                                     districts$district_ia_indic_2, 1, 0)
write.csv(districts, "districts.csv", row.names = FALSE)
write.csv(line_items_predicted_received, "line_items_predicted_received.csv", row.names = FALSE)

