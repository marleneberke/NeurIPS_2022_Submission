#####################################################################################
#helper functions for bootstrapping
compute_mean <- function(DataList, indices){
  sampled_data = DataList[indices]
  return(mean(sampled_data))
}

get_ci <- function(data_column){
  #if there's an NaN, bootstrapping won't work 
  if (is.nan(data_column[1])){
    return(c(NaN, NaN))
  }
  data_column <- na.omit(data_column)
  simulations <- boot(data = data_column, statistic=compute_mean, R=10000)
  results <- boot.ci(simulations) #type doesn't seem to work
  lower <- results$percent[4]
  upper <- results$percent[5]
  return(c(lower, upper))
}

#####################################################################################
