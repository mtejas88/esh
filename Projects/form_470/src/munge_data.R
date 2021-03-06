## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

##**************************************************************************************************************************************************
## READ IN DATA

dd.2016 <- read.csv("data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)
dta.470 <- read.csv("data/raw/form_470.csv", as.is=T, header=T, stringsAsFactors=F)
bens <- read.csv("data/raw/bens.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## format the column names (take out capitalization and spaces)
names(dta.470) <- tolower(names(dta.470))
names(dta.470) <- gsub(" ", ".", names(dta.470))
## rename column "function"
names(dta.470)[names(dta.470) == 'function'] <- 'function1'
## rename column "470.number"
names(dta.470)[names(dta.470) == '470.number'] <- 'x470.number'
## convert capacity to numeric
dta.470$maximum.capacity.reported <- dta.470$maximum.capacity
dta.470$maximum.capacity <- suppressWarnings(ifelse(grepl('Mbps', dta.470$maximum.capacity), as.numeric(gsub('Mbps', '', dta.470$maximum.capacity)),
                                                    as.numeric(gsub('Gbps', '', dta.470$maximum.capacity))*1000))
## merge in BENs to DD
dd.2016 <- merge(dd.2016, bens, by.x='esh_id', by.y='entity_id', all.x=T)

## merge in number of students and number of campuses
dta.470 <- merge(dta.470, dd.2016[,c('ben', 'esh_id', 'num_students', 'num_campuses')], by='ben', all.x=T)

## the possible missing BENS (NA number of students),
## could be things we don't care about (ie Libraries)
## OR could be one-school districts that used their school BEN instead of their district BEN
## for now, take them out
dta.470.na.students <- dta.470[which(is.na(dta.470$num_students)),]
dta.470 <- dta.470[which(!is.na(dta.470$num_students)),]

## take out the BENs that file multiple 470s and subset to the most recent one filed (as long as the same service)

##**************************************************************************************************************************************************
## APPLY LOGIC

## IA MEETING GOALS
##=====================================================================================================
## Service Type = 'Internet Access and/or Telecommunications' 
dta.470.ia <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications"),]
## AND Function in ('Internet Access: ISP Service Only', 'Internet Access and Transport Bundled')
dta.470.ia <- dta.470.ia[which(dta.470.ia$function1 == 'Internet Access and Transport Bundled' |
                                 dta.470.ia$function1 == 'Internet Access: ISP Service Only' & is.na(dta.470.ia$quantity)),]
dta.470.ia <- dta.470.ia[which(dta.470.ia$quantity == 1 | is.na(dta.470.ia$quantity)),]
dta.470.ia2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                               dta.470$function1 == 'Other'),]
dta.470.ia <- rbind(dta.470.ia, dta.470.ia2)
## AND maximum capacities are meeting the 2014 connectivity goal
## find the max of the maximum capacities reported for each ID
max.capacity <- suppressWarnings(aggregate(dta.470.ia$maximum.capacity, by=list(dta.470.ia$x470.number), FUN=max, na.rm=T))
names(max.capacity) <- c('x470.number', 'maximum.capacity')
## merge in the number of students
max.capacity <- merge(max.capacity, dta.470.ia[,c('x470.number', 'num_students')], by='x470.number', all.x=T)
max.capacity$bw_per_student <- (max.capacity$maximum.capacity*1000) / max.capacity$num_students
max.capacity$meeting_goals_ia_2014 <- ifelse(max.capacity$bw_per_student >= 100, TRUE, FALSE)
max.capacity$meeting_goals_ia_2018 <- ifelse(max.capacity$bw_per_student >= 1000, TRUE, FALSE)
## how many are meeting goals?
table(max.capacity$meeting_goals_ia_2014)
ia.meeting.goals <- max.capacity$x470.number[max.capacity$meeting_goals_ia_2014 == TRUE]
## merge in the meeting goal status
dta.470.ia <- merge(dta.470.ia, max.capacity[,c('x470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')],
                    by='x470.number', all.x=T)
## overwrite the goal meeting status if the function is Other
dta.470.ia$meeting_goals_ia_2014 <- ifelse(dta.470.ia$function1 == 'Other', NA, dta.470.ia$meeting_goals_ia_2014)
dta.470.ia$meeting_goals_ia_2018 <- ifelse(dta.470.ia$function1 == 'Other', NA, dta.470.ia$meeting_goals_ia_2018)

## the number of forms meeting goals
length(unique(dta.470.ia$x470.number[which(dta.470.ia$meeting_goals_ia_2014 == TRUE)]))
length(unique(dta.470.ia$x470.number[which(dta.470.ia$meeting_goals_ia_2014 == FALSE)]))
length(unique(dta.470.ia$x470.number))

length(unique(dta.470.ia$x470.number[which(dta.470.ia$meeting_goals_ia_2018 == TRUE)]))
length(unique(dta.470.ia$x470.number[which(dta.470.ia$meeting_goals_ia_2018 == FALSE)]))
length(unique(dta.470.ia$x470.number))

## define unknown status
dta.470.ia.unknown <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                      dta.470$function1 == 'Internet Access and Transport Bundled' &
                                      dta.470$quantity > 1),]
dta.470.ia.unknown2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                       dta.470$function1 == 'Internet Access and Transport Bundled' &
                                       dta.470$quantity == 0),]
dta.470.ia.unknown <- rbind(dta.470.ia.unknown, dta.470.ia.unknown2)
dta.470.ia.unknown <- dta.470.ia.unknown[which(!dta.470.ia.unknown$x470.number %in% dta.470.ia$x470.number),]
dta.470.ia.unknown$meeting_goals_ia_2014 <- 'UNKNOWN'
dta.470.ia.unknown$meeting_goals_ia_2018 <- 'UNKNOWN'
length(unique(dta.470.ia.unknown$x470.number))



## WAN MEETING GOALS
##=====================================================================================================
## Service Type = 'Internet Access and/or Telecommunications' 
dta.470.wan <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications"),]
## AND Function = ‘Transport Only - No ISP Service Included’ OR ‘Lit Fiber Service’
dta.470.wan <- dta.470.wan[which(dta.470.wan$function1 %in% c('Transport Only - No ISP Service Included', 'Lit Fiber Service', 'Other')),]
## AND quantity is >= (num_campuses - 1)
dta.470.wan$meeting_goals_wan <- ifelse(dta.470.wan$quantity >= (dta.470.wan$num_campuses - 1), TRUE, FALSE)
## overwrite the goal meeting status if the function is Other
dta.470.wan$meeting_goals_wan <- ifelse(dta.470.wan$function1 == 'Other', NA, dta.470.wan$meeting_goals_wan)

## the number of forms meeting goals
length(unique(dta.470.wan$x470.number[which(dta.470.wan$meeting_goals_wan == TRUE)]))
length(unique(dta.470.wan$x470.number[which(dta.470.wan$meeting_goals_wan == FALSE)]))
length(unique(dta.470.wan$x470.number))

## define unknown status
dta.470.wan.unknown <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" & 
                                       dta.470$function1 %in% c('Dark Fiber', 'Self-provisioning')),]
dta.470.wan.unknown2 <- dta.470[which(dta.470$service.category == "Internet Access and/or Telecommunications" &
                                        dta.470$function1 == 'Internet Access and Transport Bundled' &
                                        dta.470$quantity == 0),]
dta.470.wan.unknown <- rbind(dta.470.wan.unknown, dta.470.wan.unknown2)
dta.470.wan.unknown <- dta.470.wan.unknown[which(!dta.470.wan.unknown$x470.number %in% dta.470.wan$x470.number),]
dta.470.wan.unknown$meeting_goals_wan <- 'UNKNOWN'
length(unique(dta.470.wan.unknown$x470.number))

##**************************************************************************************************************************************************
## merge together the indicators

dta.470.ia.sub <- dta.470.ia[,c('esh_id', 'x470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')]
dta.470.ia.sub <- unique(dta.470.ia.sub)
dta.470.ia.sub <- rbind(dta.470.ia.sub, dta.470.ia.unknown[,c('esh_id', 'x470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018')])
dta.470.sub <- merge(dta.470.ia.sub, dta.470.wan[,c('esh_id', 'x470.number', 'meeting_goals_wan')], by=c('esh_id', 'x470.number'), all=T)
dta.470.wan.unknown$meeting_goals_ia_2014 <- NA
dta.470.wan.unknown$meeting_goals_ia_2018 <- NA
dta.470.wan.unknown <- dta.470.wan.unknown[,c('esh_id', 'x470.number', 'meeting_goals_ia_2014', 'meeting_goals_ia_2018', 'meeting_goals_wan')]
dta.470.sub <- rbind(dta.470.sub, dta.470.wan.unknown)
dta.470.sub <- unique(dta.470.sub)

##**************************************************************************************************************************************************
## write out the interim datasets

write.csv(dta.470.sub, "data/processed/470_status.csv", row.names=F)
write.csv(dta.470.ia, "data/interim/470_ia_status.csv", row.names=F)
write.csv(dta.470, "data/interim/470_all.csv", row.names=F)
