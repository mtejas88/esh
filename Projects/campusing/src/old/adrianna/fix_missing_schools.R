
## Clearing memory
rm(list=ls())

## set working directory
setwd("~/Google Drive/Colocation/code/")

dta.old <- read.csv("../data/final_campus_groupings_2016-08-31_school_level.csv", as.is=T, header=T)
dta.new <- read.csv("../data/final_campus_groupings_2016-09-29_school_level.csv", as.is=T, header=T)
sub <- dta.new[!dta.new$school_esh_id %in% dta.old$school_esh_id,]

#schools.missing.esh.id <- c(1073504, 1073367, 1074123, 1074704, 1074225)
#schools.missing.nces.code <- c(300329001111, 300456001108, 302420001110, 500038600337, 500002700382)

## make old campus ids numeric
dta.old$campus_id <- gsub("campus_", "", dta.old$campus_id)
dta.old$campus_id <- as.numeric(dta.old$campus_id)
dta.old <- dta.old[order(dta.old$campus_id),]

## collect ids that are matched with old campuses
collected.ids <- NULL

for (i in 1:nrow(sub)){
  sub.sub <- dta.new[dta.new$campus_id == sub$campus_id[i],]
  if (nrow(sub.sub) == 1){
    dta.old <- rbind(dta.old, c(sub.sub$school_esh_id, dta.old$campus_id[nrow(dta.old)]+1))
  } else{
    collected.ids <- append(collected.ids, sub$school_esh_id[i])
  }
}

## now cycle through the collected ids
collected.ids2 <- NULL
for (i in 1:length(collected.ids)){
  sub.sub <- dta.new[dta.new$campus_id == sub$campus_id[sub$school_esh_id == collected.ids[i]],]
  dta.old.sub <- dta.old[dta.old$school_esh_id %in% sub.sub$school_esh_id,]
  ## if there's only one original campus id,
  if (length(unique(dta.old.sub$campus_id)) == 1){
    ## find the new schools that need to be added
    need.to.add <- sub.sub$school_esh_id[!sub.sub$school_esh_id %in% dta.old.sub$school_esh_id]
    for (j in 1:length(need.to.add)){
      dta.old <- rbind(dta.old, c(need.to.add[j], dta.old.sub$campus_id[1]))
    }
  } else{
    collected.ids2 <- append(collected.ids2, collected.ids[i])
  }
}

## now cycle through the collected ids
collected.ids3 <- NULL
for (i in 1:length(collected.ids2)){
  sub.sub <- dta.new[dta.new$campus_id == sub$campus_id[sub$school_esh_id == collected.ids2[i]],]
  dta.old.sub <- dta.old[dta.old$school_esh_id %in% sub.sub$school_esh_id,]
  if (nrow(dta.old.sub) == 0){
    new.campus.id <- dta.old$campus_id[nrow(dta.old)]+1
    for (j in 1:nrow(sub.sub)){
      dta.old <- rbind(dta.old, c(sub.sub$school_esh_id[j], new.campus.id))
    }
  } else{
    collected.ids3 <- append(collected.ids3, collected.ids[i])
  }
}

collected.ids4 <- NULL
for (i in 1:length(collected.ids3)){
  sub.sub <- dta.new[dta.new$campus_id == sub$campus_id[sub$school_esh_id == collected.ids3[i]],]
  dta.old.sub <- dta.old[dta.old$school_esh_id %in% sub.sub$school_esh_id,]
  if (length(unique(dta.old.sub$campus_id)) == 1){
    "do nothing"
  } else{
    collected.ids4 <- append(collected.ids4, collected.ids3[i])
  }
}

dta.old$campus_id <- paste("campus_", dta.old$campus_id, sep='')
dta.old <- dta.old[!is.na(dta.old$school_esh_id),]
dta.old <- dta.old[!duplicated(dta.old$school_esh_id),]

dta.old <- dta.old[dta.old$school_esh_id %in% sub$school_esh_id,]

## write out the appended campus ids
write.csv(dta.old, "../data/additional_final_campus_groupings_2016-08-31_school_level.csv", row.names=F)
