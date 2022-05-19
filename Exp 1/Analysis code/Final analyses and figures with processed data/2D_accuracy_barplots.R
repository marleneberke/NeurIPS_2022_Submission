library(tidyverse)
library(boot)
source("~/Documents/03_Yale/Projects/001_Mask_RCNN/ORB_project3/Analysis/bootstrap_helper_funs.R")

setwd("/Users/marleneberke/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/retinanet/Final_Results/Full/")
num_training_videos = 50

online_0 = read_csv("shuffle_0_retinanet/similarity2D.csv")
online_1 = read_csv("shuffle_1_retinanet/similarity2D.csv")
online_2 = read_csv("shuffle_2_retinanet/similarity2D.csv")
online_3 = read_csv("shuffle_3_retinanet/similarity2D.csv")

merged1 = merge(online_0, online_1, by = c("video", "sim_NN_input"), suffixes = c(".0",".1"))
merged2 = merge(online_2, online_3, by = c("video", "sim_NN_input"), suffixes = c(".2",".3"))
merged = merge(merged1, merged2, by = c("video", "sim_NN_input"))

#just eyeball the variance
merged %>% group_by(video <= num_training_videos) %>% summarize(m.0 = mean(sim_online.0), m.1 = mean(sim_online.1), m.2 = mean(sim_online.2), m.3 = mean(sim_online.3))
merged %>% group_by(video <= num_training_videos) %>% summarize(m.0 = mean(sim_retrospective.0), m.1 = mean(sim_retrospective.1), m.2 = mean(sim_retrospective.2), m.3 = mean(sim_retrospective.3))


df <- merged %>% mutate(sim_online = (sim_online.0 + sim_online.1 + sim_online.2 + sim_online.3)/4,
                        sim_retro = (sim_retrospective.0 + sim_retrospective.1 + sim_retrospective.2 + sim_retrospective.3)/4,
                        sim_lesion = (sim_lesioned.0 + sim_lesioned.1 + sim_lesioned.2 + sim_lesioned.3)/4)

df <- df %>% select(video, sim_online, sim_retro, sim_lesion, sim_NN_input) %>%
  rename(sim_input = sim_NN_input)

df <- df %>% mutate(grouping = video > num_training_videos)

# View(df %>% filter(grouping == FALSE) %>% mutate(diff = sim_online - sim_input) %>%
#   arrange(diff))

temp <- df %>% group_by(grouping) %>%
  summarize(lower_online = get_ci(sim_online)[1],
            lower_retro = get_ci(sim_retro)[1],
            lower_lesion = get_ci(sim_lesion)[1],
            lower_input = get_ci(sim_input)[1],
            upper_online = get_ci(sim_online)[2],
            upper_retro = get_ci(sim_retro)[2],
            upper_lesion = get_ci(sim_lesion)[2],
            upper_input = get_ci(sim_input)[2],
            mean_online = mean(sim_online),
            mean_retro = mean(sim_retro),
            mean_lesion = mean(sim_lesion),
            mean_input = mean(sim_input))# %>%

first_half <- temp %>% filter(grouping==FALSE) %>% select(-grouping)
second_half <- temp %>% filter(grouping) %>% select(-grouping)

df1 <- first_half %>%
  pivot_longer(everything(),
               names_to = c(".value", "model"),
               names_pattern = "(.+)_(.+)"
  )

df2 <- second_half %>%
  pivot_longer(everything(),
               names_to = c(".value", "model"),
               names_pattern = "(.+)_(.+)"
  )


df1 <- df1 %>% mutate(group = "A")
df2 <- df2 %>% mutate(group = "B")
to_plot <- rbind(df1, df2)
to_save <- to_plot %>% select(model, mean, group)
write_csv(to_save, "summary_bb_accuracy.csv")

pd <- position_dodge(0.1)
ggplot(
  to_plot, 
  aes(x = group, y = mean, color = model)
) + 
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper), position = pd) +
  geom_point(position = pd) +
  ylim(0.0,1.0)

barplot <- ggplot(
  to_plot,
  aes(x = group, y = mean, color = model)
) + 
  geom_bar(stat = "identity", aes(x = group, y = mean, fill = model), position = "dodge") +
  ylim(0.0,1.0) + theme(aspect.ratio = 1)

barplot <- ggplot(
  to_plot,
  aes(x = group, y = mean, color = model)
) + 
  geom_bar(stat = "identity", aes(x = group, y = mean, fill = model), position = position_dodge()) +
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper), position = position_dodge(0.9)) +
  ylim(0.0,1.0) + theme(aspect.ratio = 1) + coord_cartesian(ylim=c(0.0,1.0))


barplot
ggsave("barplot.pdf")


#############################################################################
#Try to bootstrap over the difference between
#1) input and retro
#2) fitted and retro
#using paired data

#############################################################################
#helper functions for bootstrapping
compute_mean_difference <- function(data, indices){
  sampled_data = data[indices,]#select those rows
  differences <- sampled_data[,1] - sampled_data[,2]
  return(mean(differences))
}

get_ci_mean_difference <- function(data_column1, data_column2){
  #if there's an NaN, bootstrapping won't work 
  if (is.nan(data_column1[1]) || is.nan(data_column2[1])){
    return(c(NaN, NaN))
  }
  data = cbind(data_column1, data_column2)
  print(data)
  simulations <- boot(data, statistic=compute_mean_difference, R=10000)
  results <- boot.ci(simulations) #type doesn't seem to work
  lower <- results$percent[4]
  upper <- results$percent[5]
  return(c(lower, upper))
}
#############################################################################

temp2 <- df %>% group_by(grouping) %>%
  summarize(lower_RetroInput = get_ci_mean_difference(sim_retro, sim_input)[1],
            lower_RetroLesion = get_ci_mean_difference(sim_retro, sim_lesion)[1],
            upper_RetroInput = get_ci_mean_difference(sim_retro, sim_input)[2],
            upper_RetroLesion = get_ci_mean_difference(sim_retro, sim_lesion)[2],
            mean_RetroInput = mean(sim_retro - sim_input),
            mean_RetroLesion = mean(sim_retro - sim_lesion))

first_half2 <- temp2 %>% filter(grouping==FALSE) %>% select(-grouping)
second_half2 <- temp2 %>% filter(grouping) %>% select(-grouping)

df1_2 <- first_half2 %>%
  pivot_longer(everything(),
               names_to = c(".value", "model"),
               names_pattern = "(.+)_(.+)"
  )


df2_2 <- second_half2 %>%
  pivot_longer(everything(),
               names_to = c(".value", "model"),
               names_pattern = "(.+)_(.+)"
  )


df1_2 <- df1_2 %>% mutate(group = "A")
df2_2 <- df2_2 %>% mutate(group = "B")
to_plot_2 <- rbind(df1_2, df2_2)

pd <- position_dodge(0.1)
ggplot(
  to_plot_2, 
  aes(x = group, y = mean, color = model)
) + 
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper), position = pd) +
  geom_point(position = pd) + geom_hline(yintercept = 0) +
  ylim(-0.5,0.5) + theme(aspect.ratio = 1)

barplot <- ggplot(
  to_plot_2,
  aes(x = group, y = mean, color = model)
) + 
  geom_bar(stat = "identity", aes(x = group, y = mean, fill = model), position = position_dodge()) +
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper), position = position_dodge(0.9)) +
  ylim(-0.5, 0.5) + geom_hline(yintercept = 0) + theme(aspect.ratio = 1)

write_csv(to_plot_2, "bootstrapped_differences.csv")

ggsave("differences_barplot.pdf")

temp3 <- df %>% ungroup() %>% 
  summarize(lower_RetroInput = get_ci_mean_difference(sim_retro, sim_input)[1],
            lower_RetroFitted = get_ci_mean_difference(sim_retro, sim_fitted)[1],
            upper_RetroInput = get_ci_mean_difference(sim_retro, sim_input)[2],
            upper_RetroFitted = get_ci_mean_difference(sim_retro, sim_fitted)[2],
            mean_RetroInput = mean(sim_retro - sim_input),
            mean_RetroFitted = mean(sim_retro - sim_fitted))

df_3 <- temp3 %>%
  pivot_longer(everything(),
               names_to = c(".value", "model"),
               names_pattern = "(.+)_(.+)"
  )

ggplot(
  df_3, 
  aes(x = model, y = mean, color = model)
) + 
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper)) +
  geom_point() +
  ylim(-0.5,0.5)

#############################################################################
setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/detr/Final_Results/Full/")
df_detr = read_csv("bootstrapped_differences.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/faster_rcnn/Final_Results/Full/")
df_faster_rcnn = read_csv("bootstrapped_differences.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/retinanet/Final_Results/Full/")
df_retinanet = read_csv("bootstrapped_differences.csv")


df_retinanet = df_retinanet %>% mutate(NN = "retinanet")
df_faster_rcnn = df_faster_rcnn %>% mutate(NN = "faster_rcnn")
df_detr = df_detr %>% mutate(NN = "detr")

combined = rbind(df_retinanet, df_faster_rcnn, df_detr) %>% filter(group=="B")
combined$concatenated = paste(combined$NN, combined$model)

barplot <- ggplot(
  combined,
  aes(x = NN, y = mean)
) + 
  geom_bar(stat = "identity", aes(color = model), position = position_dodge()) +
  geom_errorbar(width = 0.1, aes(ymin = lower, ymax = upper, color = model), position = position_dodge(0.9)) +
  ylim(-0.5, 0.5) + geom_hline(yintercept = 0) + theme(aspect.ratio = 1) +
  scale_color_manual(values=c("#58508d", "#ff6361")) + scale_fill_manual(values=c("#58508d", "#ff6361"))

barplot #final barplot used in Figure 2 of NeurIPS 2022 submission
