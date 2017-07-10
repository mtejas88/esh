## =========================================
##
## BROADBAND: Logic to define whether
##  a line item is broadband from the raw
##  line items.
##
## =========================================

define_broadband <- function(dta){

  dta$broadband <- ifelse(dta$service_type == "Data Transmission and/or Internet Access" &
                            !dta$function. %in% c('Miscellaneous', 'Cabinets', 'Cabling', 'Conduit',
                                                  'Connectors/Couplers', 'Patch Panels', 'Routers', 'Switches', 'UPS'), TRUE, FALSE)


  return(dta)
}