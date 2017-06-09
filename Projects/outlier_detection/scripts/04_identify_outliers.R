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
# Function that computes the test statistics and identifies the outliers
# NOTE: setting the loop to run from 1 to N means the following in statistical language:
# H^a: There are up to N outliers in the data
# H^0: There are no outliers in the data
outliers_loop <- function(N,data,alpha,cost_column,unique_id,n_17_at_time) {
  n=nrow(data)
  results=c()
  for (i in 1:N) {
    if (i == 1) {
      rt <- rval(data, cost_column)  # distribution of numbers 
      R <- unlist(rt[1])
      df <- data.frame(rt[2])
      
      outlier_unique_id <- df[which(df$ares == max(df$ares)), unique_id]
      outlier_value <- df[which(df$ares == max(df$ares)), cost_column]
      outlier_year <- df[which(df$ares == max(df$ares)), "year"]     
      newdf <- df[df$ares!=max(df$ares),]}
    
    else if (i != 1) {
      rt <- rval(newdf, cost_column)
      R <- unlist(rt[1])
      df <- data.frame(rt[2])
     
      outlier_unique_id <- df[which(df$ares == max(df$ares)), unique_id]
      outlier_value <- df[which(df$ares == max(df$ares)), cost_column]
      outlier_year <- df[which(df$ares == max(df$ares)), "year"]
      newdf <- df[df$ares != max(df$ares),]}
    
    ## Compute critical value.
    p <- (1 - alpha / (2 * (n - i + 1)))
    t <- qt(p, (n - i - 1))
    lam <- (t * (n - i) / sqrt((n - i - 1 + t**2) * (n - i + 1)))
    
    results_to_append <- as.data.frame(cbind(outlier_unique_id, outlier_value, R, lam,outlier_year))
    
    if(!is.finite(results_to_append$R)) {
      results <- results  
      
    } else{
      results <- rbind(results, results_to_append)
    }
    outlier_value <- NULL
    outlier_unique_id <- NULL
    R <- NULL
    lam <- NULL
    outlier_year <- NULL
  } 
  ## Print results.
  
  results <- as.data.frame(results)
  results <- results %>%  
    filter(R > lam)

  if (n_17_at_time > 0) {
    #filter to only include 2017 datapoints, if they were flagged as outliers
    results <- results %>%  
      filter(outlier_year > 2016)
  }
  return(results[,-ncol(results)])
}
####################

identify_outliers <- 
  function(d, significance_level, cost_column, unique_id,use_case_name,with_16,n_17_at_time) {
    n <- nrow(d)
    alpha <- significance_level
    results <- c()
  #1. if we are removing the 2016 outliers first    
  if (with_16==0) {
    #then, the number of 'potential outliers' passed to ESD is just the number of 2017 data points we introduce 
    N=n_17_at_time
    results=outliers_loop(N,d,alpha,cost_column,unique_id,n_17_at_time)
  }
  else {
    #otherwise, the number of 'potential outliers' passed to ESD is n/4 (to catch 2016 outliers) + the number of 2017 data points we introduce 
    N=(n/4) + n_17_at_time
    results=outliers_loop(N,d,alpha,cost_column,unique_id,n_17_at_time)
  }
  
  #2. will output an error message if there are no outliers identified, otherwise return the outlier IDs and test statistics
  if(nrow(results) != 0)
  {
    #bind parameters into a string for export
    use_case_parameters <- as.character(unique(d$use_case_parameters))
    str1 <- paste0("\"significance_level\" => \"", significance_level,"\"")
    str2 <- paste0("\"outlier_value_type\" => \"", cost_column,"\"")
    str3 <- paste0("\"outlier_id_type\" => \"", unique_id,"\"")
    
    use_case_cd <- tolower(gsub(" ","_",use_case_name))
    
    outlier_test_parameters <- paste(str1, str2, str3, sep = ",")
    output_list <- cbind(use_case_name, use_case_cd, use_case_parameters, outlier_test_parameters, results)
    colnames(output_list) <- c('outlier_use_case_name','outlier_use_case_cd','outlier_use_case_parameters',    'outlier_test_parameters',    'outlier_unique_id',    'outlier_value',    'R',    'lam')
    
    return(output_list)
  }
  
}

