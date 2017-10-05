## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("xlsx","stringr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(xlsx)
library(stringr)

##**************************************************************************************************************************************************
## read in data

cosn <- read.xlsx("cosn_partners_targets.xlsx", 1,endRow = 934)
base_list <- read.xlsx("low remaining lists to share.xlsx", 2)
ffl <- read.xlsx("low remaining lists to share.xlsx", 4)
esh <- read.xlsx("low remaining lists to share.xlsx", 5)

#filter out other lists
spent_ge85_c2 = base_list[!(base_list$esh_id %in% ffl$esh_id),]
spent_ge85_c2 = spent_ge85_c2[!(spent_ge85_c2$esh_id %in% esh$esh_id__c),]

##**************************************************************************************************************************************************
## subset and format data
names(cosn)=c( "name",  "target_status", "postal_cd" )

##lower and ignore punctuation
spent_ge85_c2$name = tolower(spent_ge85_c2$name)
spent_ge85_c2$name <- gsub("[[:punct:]]", "", spent_ge85_c2$name)
cosn$name = tolower(cosn$name)
cosn$name <- gsub("[[:punct:]]", "", cosn$name)

#function to match string
matchx <- function(x,p) {
  y <- grepl(p, x)
  return(y)
}

#convert postal_cds to string
spent_ge85_c2$postal_cd = as.character(spent_ge85_c2$postal_cd)
cosn$postal_cd = as.character(cosn$postal_cd)

##**************************************************************************************************************************************************
##create a column indicating if the CosN school name matches any of our names in the state, and which esh_ids that corresponds to

match_indicator_column <- function(col) {
  matched=c()
  esh_ids=list()
  for(i in 1:nrow(cosn)){
    sub=spent_ge85_c2[spent_ge85_c2$postal_cd == cosn[i,"postal_cd"],]
    vec=sapply(sub[,col], function(x) { matchx(x,cosn[i,col]) })
    inds=which(vec==TRUE)
    esh_ids[[i]] = sub[inds,"esh_id"]
    matched=append(matched,any(vec==TRUE)) 
  }
  return(list(matched=matched,esh_ids=esh_ids))
}

##create another column indicating if the first 2 words in the CosN school name matches the first 2 words of any of our names in the state
getwords <- function(data) {
  word1 = word(data$name, 1)
  word2 = ifelse(!is.na(word(data$name, 2)), word(data$name, 2), "")
  for (i in c(1:length(word1))) {
    if (((!is.na(word1[i]) & !is.na(word2[i]) & word1[i]=="school" & word2[i]=="district")) || 
        ((!is.na(word1[i]) & !is.na(word2[i]) & word1[i]=="community" & word2[i]=="consolidated"))) {
      word1[i] = data$name[i]
      word2[i] = ""
    }
  }
  return(paste(word1, word2, sep = ""))
}

cosn$first2words=getwords(cosn)
cosn$first2words=gsub(" ", "", cosn$first2words, fixed = TRUE)
spent_ge85_c2$first2words=gsub(" ", "", spent_ge85_c2$name, fixed = TRUE)

matches=match_indicator_column("first2words")

cosn$first2match = matches$matched
eshids=matches$esh_ids
eshids=unlist(eshids)
eshids=unique(eshids)
  
#add column to original dataset
cosn_export=base_list
cosn_export$CoSN = sapply(cosn_export$esh_id, function(x) {ifelse((x %in% eshids), "Y", NA)})

##**************************************************************************************************************************************************
## write out dataset

write.xlsx(cosn_export, "low remaining lists to share-CoSN.xlsx", row.names=F,showNA = FALSE)
