#This is the main script for analyzing the processed data
#Uncomment lines 10-11 to read the csv file saved in analysis_of_raw_data.R
#If you're using the our data, use lines 12-19

library(tidyverse)
library(Rfast)
set.seed(1)
##################################
## Read the processed data
setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/Simulated_data_and_analysis/May/5.26Version/05_16_22")
combined_data <- read_csv("Jaccard_acc_processed.csv")

data <- combined_data %>% select(-percept_number...7) %>% rename(percept_number = percept_number...2)
#get down to 4000 different sims
total = length(unique(data$simID))
how_many_to_get_rid_of = total - 40000
samp <- sample(1:total, size = how_many_to_get_rid_of, replace = FALSE)
data <- data %>% filter(!simID %in% samp)
#length(unique(data$simID))==40,000 so good!
###################################################################
accuracy_plot <- function(data){
  #drop rows for percept0
  data <- na.omit(data)
  
  df_Accuracy <-
    data %>% gather(
      Model,
      Score,
      A_retrospective_metagen,
      A_lesioned_metagen,
      A_online_metagen,
      #A_threshold
    )
  
  GetLowerCI <- function(x,y){return(prop.test(x,y)$conf.int[1])}
  GetTopCI <- function(x,y){return(prop.test(x,y)$conf.int[2])}
  
  toPlot_Accuracy <- df_Accuracy %>% group_by(percept_number,Model) %>% summarize(Samples=n(),Hits=sum(Score),Mean=mean(Score),Lower=GetLowerCI(Hits,Samples),Top=GetTopCI(Hits,Samples))
  
  p <- ggplot(
    toPlot_Accuracy,
    aes(
      x = percept_number,
      y = Mean,
      ymin = Lower,
      ymax = Top,
      fill = Model,
      group = Model
    )
  ) + geom_ribbon() + geom_line() + coord_cartesian(xlim = c(1, 75)) + theme(aspect.ratio=1)
  
  ggsave("accuracy_plot.pdf",p)
}


###################################################################
mse_V_plot <- function(data){
  df_V <-
    data %>% gather(
      V_param,
      MSE,
      MSE_FA,
      MSE_M,
      exp_MSE_FA,
      exp_MSE_M,
    )
  
  GetMean <- function(x){return(t.test(x)$estimate)}
  GetLowerCI <- function(x){return(t.test(x)$conf.int[1])}
  GetTopCI <- function(x){return(t.test(x)$conf.int[2])}
  
  toPlot_V <- df_V %>% group_by(percept_number,V_param) %>% summarize(Mean_MSE=GetMean(MSE),Lower=GetLowerCI(MSE),Top=GetTopCI(MSE))
  
  p <- ggplot(
    toPlot_V,
    aes(
      x = percept_number,
      y = Mean_MSE,
      ymin = Lower,
      ymax = Top,
      fill = V_param,
      group = V_param
    )
  ) + geom_ribbon() + geom_line() + coord_cartesian(ylim = c(0, 0.02), xlim = c(1, 75)) + theme(aspect.ratio=1)
  
  ggsave("mse_V_plot.pdf",p)
}

###################################################################
noise_averaging_window_plot <- function(data){
  data <- na.omit(data)
  df_Accuracy <-
    data %>% gather(
      Model,
      Score,
      A_retrospective_metagen,
      A_lesioned_metagen,
      #A_online_metagen,
      #A_naive_reality,
      #A_threshold
    )
  
  toPlot_Accuracy <- df_Accuracy %>% group_by(Model)
  GetAccuracy <- function(x){
    return(toPlot_Accuracy %>% filter(perceived_noise<x+0.05,perceived_noise>x-0.05) %>%
             group_by(Model) %>% summarize(Score=mean(Score))) %>% mutate(Fidelity=x)
  }
  Results <- map_df(seq(0,0.68,by=0.01),GetAccuracy)
  p1 <- Results %>% ggplot(aes(Fidelity,Score,color=Model))+geom_line()+
    theme_grey()+ xlim(0,0.5) + theme(aspect.ratio=1)
  
  ggsave("accuracy_vs_noise_plot.pdf", p1)
  
  #Differences plot
  toPlotDiff <- Results %>% spread(Model, Score) %>% mutate(diff = A_retrospective_metagen - A_lesioned_metagen)
  toPlotDiff <- toPlotDiff %>% mutate(winning = diff >= 0)
  p2 <- toPlotDiff %>% ggplot(aes(Fidelity, diff))+
    geom_line()+ geom_area(aes(fill = winning))+
    theme_grey()+ xlim(0,0.5) + theme(aspect.ratio=1)
  
  ggsave("differences_vs_noise_plot.pdf", p2)
  
}
###################################################################

scatterplot_learningV_noise <- function(data){
  data <- na.omit(data)
  data = data %>% filter(percept_number == max(percept_number))
  data = data %>% mutate(total_MSE = MSE_FA + MSE_M)
  
  data %>% ggplot(aes(x = perceived_noise, y = total_MSE)) +
    geom_point(alpha = 0.2) + geom_smooth()
  
  temp = lm(data$total_MSE ~ data$perceived_noise)
  summary(temp)
}
###################################################################

data <- data %>% mutate(percept_number = percept_number-1)


accuracy_plot(data)
mse_V_plot(data)

less_noisy_data = data %>% filter(perceived_noise <= 0.5)
noise_averaging_window_plot(less_noisy_data)

###################################################################
