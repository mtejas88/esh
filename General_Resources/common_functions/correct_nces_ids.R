## =========================================
##
## FUNCTION: Correct NCES District (leaid)
## and School (ncessch) IDs
##
## turn to character and append a leading 0
## when the id is less than 7 characters
## for a district and 12 for a school
##
## =========================================

## cast school id to character
## and correct the id (school should be 12 characters and district should be 7, may have dropped the leading 0)
correct_ids <- function(ids, district){
  ids <- as.character(ids)
  ## if district flag, check for less than 7 characters,
  ## otherwise check for 12 characters (school id)
  if (district == 1){
    ids <- ifelse(nchar(ids) < 7, paste("0", ids, sep=""), ids)
  } else {
    ids <- ifelse(nchar(ids) < 12, paste("0", ids, sep=""), ids)
  }
  return(ids)
}