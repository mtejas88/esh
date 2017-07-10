## =========================================================================
##
## CORRECT DELUXE DISTRICT DATASETS
##
## Since different versions of the same datasets exist (Deluxe Districts, Services Received),
## (based on the date the data is pulled),
## there is a need to correct the column values and names to keep consistency.
##
## These commands are generic so as to work with any dataset.
##
## Works with one dataset at a time.
##
## =========================================================================

correct.dataset <- function(dataset, sots.flag, services.flag){
  
  ## CONVERT ALL COLUMNS THAT ARE CHARACTERS TO NUMERIC
  ##-----------------------------------------------------
  if (sots.flag == 0){
    for (i in 1:ncol(dataset)){
      ## do not change esh_id or nces_cd to numeric
      if (!names(dataset)[i] %in% c('esh_id', 'nces_cd', names(dataset)[grepl('contract_end_date', names(dataset))], 'school_esh_ids')){
        ## assign TRUE if there is a presence of any letter
        truth.vector <- grepl("[a-zA-Z]", dataset[,i])
        ## also look for "e+" string as that is actually a number
        e.vector <- grepl("e\\+", dataset[,i])
        ## if there is no letter in the column, make numeric OR
        ## if the length of where truth.vector == TRUE is the same as where e.vector == TRUE
        if (!TRUE %in% truth.vector | (length(truth.vector[truth.vector == TRUE]) == length(e.vector[e.vector == TRUE]))){
          dataset[,i] <- suppressWarnings(as.numeric(as.character(dataset[,i])))
        } else{
          dataset[,i] <- as.character(dataset[,i])
        }
      }
    }
  }

  
  ## BOOLEANS
  ##---------------
  ## change "true"/"false" variables to TRUE/FALSE boolean
  if (sots.flag == 0){
    for (i in 1:ncol(dataset)){
      values <- unique(dataset[,i])
      if ("true" %in% values | "false" %in% values){
        dataset[,i] <- as.logical(dataset[,i])
      }
      if ("t" %in% values | "f" %in% values){
        dataset[,i] <- gsub("t", "True", dataset[,i])
        dataset[,i] <- gsub("f", "False", dataset[,i])
        dataset[,i] <- as.logical(dataset[,i])
      }
    }
  }

  
  ## IA_BANDWIDTH_PER_STUDENT
  ##---------------------------
  ## create "ia_bandwidth_per_student_kbps" column if it doesn't exist
  ## (can also be "ia_bandwidth_per_student")
  if (services.flag == 0){
    col <- names(dataset)[grepl("ia_bandwidth_per_student", names(dataset))]
    dataset$ia_bandwidth_per_student_kbps <- suppressWarnings(as.numeric(dataset[,col]))
  }
  
  
  ## MEETING_3_PER_MBPS_AFFORDABILITY
  ##-----------------------------------
  ## create "meeting_3_per_mbps_affordability_target" column
  ## (can also be "meeting_.3_per_mbps_affordability_target")
  if (sots.flag == 0 & services.flag == 0){
    names(dataset)[grepl('_per_mbps_affordability_target', names(dataset))] <- "meeting_3_per_mbps_affordability_target"
  }

  
  ## IA_MONTHLY_COST_TOTAL
  ##-----------------------------------
  ## correct "ia_monthly_cost_total"
  ## (can also be "total_ia_monthly_cost")
  if (sots.flag == 0 & services.flag == 0){
    ## only correct for dd.2015
    if (length(names(dataset)[grepl('ia_monthly_cost', names(dataset))]) == 1){
      names(dataset)[grepl('ia_monthly_cost', names(dataset))] <- "ia_monthly_cost_total"
    }
  }
  
  ## IA_MONTHLY_COST_PER_MBPS
  ##-----------------------------------
  ## correct "ia_monthly_cost_per_mbps"
  if (sots.flag == 0 & services.flag == 0){
    ## convert ia_monthly_cost_per_mbps to numeric
    if (length(names(dataset)[grepl('ia_monthly_cost_per_mbps', names(dataset))]) == 1){
      dataset$ia_monthly_cost_per_mbps <- as.numeric(dataset$ia_monthly_cost_per_mbps, na.rm = TRUE)
    }
  }
  
  
  ## IA_BW_MBPS_TOTAL
  ##--------------------
  ## correct "ia_bw_mbps_total"
  ## (can also be "total_ia_bw_mbps")
  if (sots.flag == 0 & services.flag == 0){
    names(dataset)[grepl('ia_bw_mbps', names(dataset))] <- "ia_bw_mbps_total"
  }
  
  
  ## LINE ITEM: TOTAL NUM OF LINES, BANDWIDTH IN MBPS
  ##---------------------------------------------------
  if (services.flag == 1){
    dataset$line_item_total_num_lines <- suppressWarnings(as.numeric(dataset$line_item_total_num_lines))
    dataset$bandwidth_in_mbps <- suppressWarnings(as.numeric(dataset$bandwidth_in_mbps))
  }
  
  
  ## FORMAT DATE -- most_recent_ia_contract_end_date
  ##---------------------------------------------------
  if (length(which((grepl("contract_end_date", names(dataset))))) > 0){
    date.col <- dataset[,grepl("contract_end_date", names(dataset))]
    t.f <- grepl("/", date.col)
    if (TRUE %in% t.f){
      for (i in 1:nrow(dataset)){
        date.col[i] <- strsplit(date.col[i], " ")[[1]][1]
      }
      date.col <- as.Date(date.col, format="%m/%d/%Y")
    } else{
      date.col <- as.Date(date.col, format="%Y-%m-%d")
    }
    dataset[,grepl("contract_end_date", names(dataset))] <- date.col
  }
  
  
  ## RETURN DATASET
  return(dataset)
}
