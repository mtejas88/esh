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

#dd_2017 <- read.csv("data/raw/2017_deluxe_districts_2017-08-25_15.00.04.csv", as.is=T, header=T)
dd_2017 <- read.csv("data/raw/2017_deluxe_districts_ficher.csv", as.is=T, header=T)
dd_2017_end <- read.csv("data/raw/2017_deluxe_districts_endpoint.csv", as.is=T, header=T)

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

sub <- dta[which(dd_comparison$district_size == FALSE),]
sub.end <- dta_end[which(dd_comparison$district_size == FALSE),]

sub <- dta[which(dd_comparison$name == FALSE),]
sub.end <- dta_end[which(dd_comparison$name == FALSE),]

sub <- dta[which(dd_comparison$exclude_from_ia_analysis == FALSE),]
sub.end <- dta_end[which(dd_comparison$exclude_from_ia_analysis == FALSE),]


#compare(sr_2017, sr_2017_end, "line_item_id")

#dta <- dd_2017
#dta_end <- dd_2017_end

