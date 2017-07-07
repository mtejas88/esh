## ===============================================
##
## MUNGE DATA: Subset and Clean data for follow-up
##
## ===============================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## read in data

#blockcode
dta.477s_fiber_bc = read.csv("../data/raw/form_477s_fiber_bc3.csv", as.is=T, header=T, stringsAsFactors=F)
names(dta.477s_fiber_bc) = c("district_esh_id", "fiber_target_status","nproviders_bc","providerlist_bc")
#blockgroup
dta.477s_fiber_bg = read.csv("../data/raw/form_477s_fiber_bg3.csv", as.is=T, header=T, stringsAsFactors=F)
names(dta.477s_fiber_bg) = c("district_esh_id", "fiber_target_status","nproviders_bg","providerlist_bg")
#censustract
dta.477s_fiber_ct = read.csv("../data/raw/form_477s_fiber_ct3.csv", as.is=T, header=T, stringsAsFactors=F)
names(dta.477s_fiber_ct) = c("district_esh_id", "fiber_target_status","nproviders_ct","providerlist_ct")

##**************************************************************************************************************************************************
### merge so it's easier to summarize together
districts_schools_blocks_bg_ct=merge(dta.477s_fiber_bc,dta.477s_fiber_bg[,c("district_esh_id","nproviders_bg")], by="district_esh_id")
districts_schools_blocks_bg_ct=merge(districts_schools_blocks_bg_ct,dta.477s_fiber_ct[,c("district_esh_id","nproviders_ct")], by="district_esh_id")
summary(districts_schools_blocks_bg_ct)
##**************************************************************************************************************************************************
## write out the interim datasets
write.csv(districts_schools_blocks_bg_ct, "../data/interim/districts_schools_blocks_final_bg_ct3.csv", row.names=F)
