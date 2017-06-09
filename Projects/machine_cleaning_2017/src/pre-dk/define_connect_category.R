## =========================================
##
## CONNECT CATEGORY: Logic to define the
##  connect_category field from the raw
##  line items.
##
## =========================================

define_connect_category <- function(dta){

  dta$connect_category <- ifelse(dta$function. == "Fiber" & !dta$type_of_product %in% c("Dark Fiber IRU (No Special Construction)",
                                                                                        "Dark Fiber (No Special Construction)") , "Lit Fiber",
                                 ifelse(dta$function. == "Fiber" & dta$type_of_product %in% c("Dark Fiber IRU (No Special Construction)",
                                                                                              "Dark Fiber (No Special Construction)") , "Dark Fiber",
                                        ifelse(dta$function. == "Fiber Maintenance & Operations", "Dark Fiber",
                                               ifelse(dta$function. == "Wireless" & dta$type_of_product == "Microwave", "Fixed Wireless",
                                                      ifelse(dta$function. == "Wireless" & dta$type_of_product %in% c('Satellite Service',
                                                                                                                       'Wireless data service',
                                                                                                                       'Data plan for portable device'), "Satellite/LTE",
                                                           ifelse(dta$function. == "Copper" & dta$type_of_product == "Cable Modem", "Cable",
                                                                  ifelse(dta$function. == "Copper" & dta$type_of_product == "Digital Subscriber Line (DSL)", "DSL",
                                                                         ifelse(dta$function. == "Copper" & dta$type_of_product == "T-1", "T-1",
                                                                                ifelse(dta$function. == "Copper" & !dta$type_of_product %in% c('Cable Modem',
                                                                                                                                               'Digital Subscriber Line (DSL)',
                                                                                                                                               'T-1'), "Other Copper", "Uncategorized")))))))))

  return(dta)
}
