## =========================================================================
##
## REFRESH STATE METRICS:
## FORMAT SERVICE PROVIDER INFORMATION
##
## For Dedicated ISP and Bundled Internet
## =========================================================================

combine.sp <- function(dataset){
  for (i in 1:nrow(dataset)){
    sp <- unique(c(dataset$bundled_internet_sp[i], dataset$dedicated_isp_sp[i]))
    sp <- sp[sp != ""]
    if (length(sp) == 0){
      sp <- NA
    }
    if (length(sp) > 1){
      sp.value <- NULL
      for (j in length(sp)){
        sp.value <- paste(sp.value, sp[j], sep=' ')
      }
    } else{
      sp.value <- sp
    }
    dataset$bundled_and_dedicated_isp_sp[i] <- sp.value
  }
  ## clean spaces in the beginning and end of the line
  trim <- function (x) gsub("^\\s+|\\s+$", "", x)
  dataset$bundled_and_dedicated_isp_sp <- trim(dataset$bundled_and_dedicated_isp_sp)
  dataset$bundled_and_dedicated_isp_sp <- ifelse(dataset$bundled_and_dedicated_isp_sp == "NA", NA, dataset$bundled_and_dedicated_isp_sp)
  
  ## for each dataset, calculate the total number of internet upstream lines
  dataset$num_internet_upstream_lines <- rowSums(dataset[,names(dataset)[grepl("_upstream_lines", names(dataset))]])
  
  return(dataset)
}
