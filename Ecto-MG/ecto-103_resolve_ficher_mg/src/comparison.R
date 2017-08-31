## =========================================
##
## COMPARE SAME DATASETS FROM DIFFERENT DB
##
## =========================================

## Clearing memory
rm(list=ls())

setwd("~/Documents/ESH-Code/ficher/Ecto-MG/ecto-103_resolve_ficher_mg/")

##**************************************************************************************************************************************************
## read data

dd_2017 <- read.csv("data/raw/2017_deluxe_districts_ficher.csv", as.is=T, header=T, stringsAsFactors=F)
dd_2017_end <- read.csv("data/raw/2017_deluxe_districts_endpoint.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## compare by columns

compare <- function(dta, dta_end, id_col){
  
  ## first, check if the dimensions are the same
  ## rows
  nrow(dta) == nrow(dta_end)
  dta_end[!dta_end[,id_col] %in% dta[,id_col],id_col]
  dta[!dta[,id_col] %in% dta_end[,id_col],id_col]
  
  ## subset to overlapping rows
  dta_end <- dta_end[which(dta_end[,id_col] %in% dta[,id_col]),]
  dta <- dta[which(dta[,id_col] %in% dta_end[,id_col]),]
  
  ## cols
  ncol(dta) == ncol(dta_end)
  names(dta_end)[!names(dta_end) %in% names(dta)]
  names(dta)[!names(dta) %in% names(dta_end)]
  
  ## order the same way
  dta <- dta[order(dta[,id_col]),]
  dta_end <- dta_end[order(dta_end[,id_col]),]
  
  ## subset to overlapping columns
  dta <- dta[,which(names(dta) %in% names(dta_end))]
  dta_end <- dta_end[,which(names(dta_end) %in% names(dta))]
  
  dta.compare <- data.frame(matrix(NA, nrow=nrow(dta), ncol=ncol(dta)))
  names(dta.compare) <- names(dta)
  diff.array <- NULL
  num.diff <- NULL
  
  for (i in 1:ncol(dta)){
    if (names(dta)[i] != names(dta_end)[i]){
      print("ERROR: NOT THE SAME COLUMN")
    } else{
      print(names(dta)[i])
    }
    dta.compare[,i] <- dta[,i] == dta_end[,i]
    if (FALSE %in% dta.compare[,i]){
      diff.array <- append(diff.array, names(dta.compare)[i])
      num.diff <- append(num.diff, nrow(dta.compare[which(dta.compare[,i] == FALSE),]))
    }
  }
  
  assign("dta", dta, envir = .GlobalEnv)
  assign("dta_end", dta_end, envir = .GlobalEnv)
  assign("dd_comparison", dta.compare, envir = .GlobalEnv)
  assign("cols_diff", diff.array, envir = .GlobalEnv)
  assign("num_entries_diff", num.diff, envir = .GlobalEnv)
  
}

compare(dd_2017, dd_2017_end, "esh_id")
dta.diff <- data.frame(cols=cols_diff, num_diff=num_entries_diff)

## write name of column you want to look at
col.to.compare <- "name"
col.to.compare <- "c2_prediscount_remaining_15"


#sub <- dta[which(dd_comparison[,col.to.compare] == FALSE),]
#sub.end <- dta_end[which(dd_comparison[,col.to.compare] == FALSE),]


#cols.greater.than.100.diff <- as.character.factor(dta.diff$cols[which(dta.diff$num_diff > 100)])
#cols.c2 <- cols.greater.than.100.diff[grepl("c2", cols.greater.than.100.diff)]
#cols.greater.than.100.diff <- cols.greater.than.100.diff[!grepl("c2", cols.greater.than.100.diff)]
#cols.greater.than.100.diff <- append(cols.greater.than.100.diff, "c2_prediscount_remaining_15")

##**************************************************************************************************************************************************
## write out data

write.csv(dta.diff, "data/processed/all_columns_differences.csv", row.names=F)

