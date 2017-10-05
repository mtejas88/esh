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
spent_ge85_c2 <- read.csv("spent_ge85_c2.csv", as.is=T, header=T, stringsAsFactors=F)

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

##**************************************************************************************************************************************************
##create a column indicating if the CosN school name matches any of our names in the state

match_indicator_column <- function(col) {
  matched=c()
  for(i in 1:nrow(cosn)){
    sub=spent_ge85_c2[spent_ge85_c2$postal_cd == cosn[i,"postal_cd"],]
    vec=sapply(sub[,col], function(x) { matchx(x,cosn[i,col]) })
    matched=append(matched,any(vec==TRUE)) 
  }
  return(matched)
}

cosn$all_match=match_indicator_column("name")
sum(cosn$all_match==TRUE) 

##create another column indicating if the first 2 words in the CosN school name matches the first 2 words of any of our names in the state
getwords <- function(data) {
  word1 = word(data$name, 1)
  word2 = ifelse(!is.na(word(data$name, 2)), word(data$name, 2), "")
  return(paste(word1, word2, sep = ""))
}
cosn$first2words=getwords(cosn)
#spent_ge85_c2$first2words=getwords(spent_ge85_c2)
spent_ge85_c2$first2words=gsub(" ", "", spent_ge85_c2$name, fixed = TRUE)

cosn$first2match = match_indicator_column("first2words")

sum(cosn$first2match==TRUE) 
  
#add column to original dataset
cosn_export <- read.xlsx("cosn_partners_targets.xlsx", 1,endRow = 934)
cosn_export$match = cosn$first2match

#filter
cosn_export = cosn_export[cosn_export$match==TRUE,]
cosn_export = cosn_export[,c(1:(ncol(cosn_export) -1))]
##**************************************************************************************************************************************************
## write out dataset

write.csv(cosn_export, "cosn_partners_targets_subset_in_universe.csv", row.names=F,na="")
