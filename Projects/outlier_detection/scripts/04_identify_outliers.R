# supress Warnings
options(warn = -1)
# This script is based on the extreme studentized deviate test, which is used to detect one or more outliers 
# in a univariate dataset ASSUMING normal distribution
# please see below links for the overview and a more general script
# tutorial: http://www.itl.nist.gov/div898/software/dataplot/refman1/auxillar/esd.htm
# script: http://www.itl.nist.gov/div898/handbook/eda/section3/eda35h3.r
# http://www.itl.nist.gov/div898/handbook/eda/section3/eda35h3.htm


# feeder funciton that calculates test statistics
# Function that calculates the test statistic
rval <- function(input, y) {

  ares <- abs(input[, y] - mean(input[, y])) / sd(input[, y])
  df <- data.frame(input, ares)
  r <- max(df$ares)    # R: test statistic
  list(r, df)
   
}

####################

identify_outliers <- 
  function(data, significance_level, cost_column, unique_id) {
    
    #data <-output
    
    #data <- as.data.frame(data)
    
    n <- nrow(data)
    alpha <- significance_level
    results <- c()
    
  # NOTE: setting the loop to run from 1 to n means the following in statistical language:
  # H^a: There are up to n outliers in the data
  # H^0: There are no outliers in the data
  # below, I'm doing the non-sensical thing of testing there are up to n / 2 outliers in dataset of n observations
  
    for (i in 1:(n/4)) {
      if (i == 1) {
        rt <- rval(data, cost_column)  # distribution of numbers 
        R <- unlist(rt[1])
    
        df <- data.frame(rt[2])
        
        outlier_unique_id <- df[which(df$ares == max(df$ares)), unique_id]
        outlier_value <- df[which(df$ares == max(df$ares)), cost_column]
        
        newdf <- df[df$ares!=max(df$ares),]}
  
      else if (i != 1) {
        rt <- rval(newdf, cost_column)
        R <- unlist(rt[1])
        df <- data.frame(rt[2])
        
        outlier_unique_id <- df[which(df$ares == max(df$ares)), unique_id]
        outlier_value <- df[which(df$ares == max(df$ares)), cost_column]
        newdf <- df[df$ares != max(df$ares),]}
  
  ## Compute critical value.
      p <- (1 - alpha / (2 * (n - i + 1)))
      t <- qt(p, (n - i - 1))
      lam <- (t * (n - i) / sqrt((n - i - 1 + t**2) * (n - i + 1)))
      
      results_to_append <- as.data.frame(cbind(outlier_unique_id, outlier_value, R, lam))
     
      if(!is.finite(results_to_append$R)) {
        results <- results  
      
      } else{
        results <- rbind(results, results_to_append)
      }
        
      outlier_value <- NULL
      outlier_unique_id <- NULL
      R <- NULL
      lam <- NULL
      
    } 
## Print results.
  
  results <- as.data.frame(results)

  results <- results %>%  
             filter(R > lam)
  
  # will output an error message if there are no outliers identified
  # otherwise return the outlier IDs and test statistics
  if(nrow(results) == 0)
    stop("Congratulations! There are no outliers.", call. = FALSE)
  
  
  # also bind parameters into a string for export

  use_case_parameters <- as.character(unique(data$use_case_parameters))
  str1 <- paste0("significance_level: ", significance_level)
  str2 <- paste0("outlier_value_type: ", cost_column)
  str3 <- paste0("outlier_id_type: ", unique_id)
  

  outlier_test_parameters <- paste(str1, str2, str3, sep = " | ")
  output_list <- cbind(use_case_parameters, outlier_test_parameters, results)
  colnames(output_list) <- c('use_case_parameters',    'outlier_test_parameters',    'outlier_unique_id',    'outlier_value',    'R',    'lam')
  
  master_output <- rbind(master_output, output_list)
  assign('master_output',master_output,envir=.GlobalEnv)
  }
