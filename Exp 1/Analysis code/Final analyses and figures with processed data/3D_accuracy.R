library(tidyverse)
library(boot)
source("XXX")

setwd("XXX")

# num_training_videos = 50
# 
# online_0 = read_csv("shuffle_0_detr/similarity3D.csv")
# online_1 = read_csv("shuffle_1_detr/similarity3D.csv")
# online_2 = read_csv("shuffle_2_detr/similarity3D.csv")
# online_3 = read_csv("shuffle_3_detr/similarity3D.csv")
# 
# merged1 = merge(online_0, online_1, by = c("video"), suffixes = c(".0",".1"))
# merged2 = merge(online_2, online_3, by = c("video"), suffixes = c(".2",".3"))
# merged = merge(merged1, merged2, by = c("video"))
# 
# df <- merged %>% mutate(sim_online = (Jacc_sim_online.0 + Jacc_sim_online.1 + Jacc_sim_online.2 + Jacc_sim_online.3)/4,
#                         sim_retro = (Jacc_sim_retrospective.0 + Jacc_sim_retrospective.1 + Jacc_sim_retrospective.2 + Jacc_sim_retrospective.3)/4,
#                         dist_online = (avg_dist_online.0 + avg_dist_online.1 + avg_dist_online.2 + avg_dist_online.3)/4,
#                         dist_retro = (avg_dist_retro.0 + avg_dist_retro.1 + avg_dist_retro.2 + avg_dist_retro.3)/4,)
# df <- df %>% mutate(grouping = video > num_training_videos)
# 
# temp <- df %>% group_by(grouping) %>%
#   summarize(mean_sim_online = mean(sim_online, na.rm = TRUE),
#             lower_sim_online = get_ci(sim_online)[1],
#             upper_sim_online = get_ci(sim_online)[2],
#             mean_sim_retro = mean(sim_retro, na.rm = TRUE),
#             lower_sim_retro = get_ci(sim_retro)[1],
#             upper_sim_retro = get_ci(sim_retro)[2],
#             mean_dist_online = mean(dist_online, na.rm = TRUE),
#             lower_dist_online = get_ci(dist_online)[1],
#             upper_dist_online = get_ci(dist_online)[2],
#             mean_dist_retro = mean(dist_retro, na.rm = TRUE),
#             lower_dist_retro = get_ci(dist_retro)[1],
#             upper_dist_retro = get_ci(dist_retro)[2],)
# 
# first_half <- temp %>% filter(grouping==FALSE) %>% select(-grouping)
# second_half <- temp %>% filter(grouping) %>% select(-grouping)
# 
# df1 <- first_half %>%
#   pivot_longer(everything(),
#                names_to = c(".value", "model"),
#                names_pattern = "(.+)_(.+)"
#   )
# 
# df2 <- second_half %>%
#   pivot_longer(everything(),
#                names_to = c(".value", "model"),
#                names_pattern = "(.+)_(.+)"
#   )
# 
# 
# df1 <- df1 %>% mutate(group = "A")
# df2 <- df2 %>% mutate(group = "B")
# to_plot <- rbind(df1, df2)
# to_save <- to_plot %>% select(model, mean_sim, mean_dist, group)
# write_csv(to_save, "summary3D.csv")
###################################################################
#just 3D accuracy
setwd("XXX")

num_training_videos = 50

online_0 = read_csv("shuffle_0_detr/similarity3D.csv")
online_1 = read_csv("shuffle_1_detr/similarity3D.csv")
online_2 = read_csv("shuffle_2_detr/similarity3D.csv")
online_3 = read_csv("shuffle_3_detr/similarity3D.csv")

merged1 = merge(online_0, online_1, by = c("video"), suffixes = c(".0",".1"))
merged2 = merge(online_2, online_3, by = c("video"), suffixes = c(".2",".3"))
merged = merge(merged1, merged2, by = c("video"))

df <- merged %>% mutate(sim_online = (Jacc_sim_online.0 + Jacc_sim_online.1 + Jacc_sim_online.2 + Jacc_sim_online.3)/4,
                        sim_retro = (Jacc_sim_retrospective.0 + Jacc_sim_retrospective.1 + Jacc_sim_retrospective.2 + Jacc_sim_retrospective.3)/4,
                        sim_lesioned = (Jacc_sim_lesioned.0 + Jacc_sim_lesioned.1 + Jacc_sim_lesioned.2 + Jacc_sim_lesioned.3)/4)
df <- df %>% mutate(grouping = video > num_training_videos)

temp <- df %>% group_by(grouping) %>%
  summarize(mean_sim_online = mean(sim_online, na.rm = TRUE),
            lower_sim_online = get_ci(sim_online)[1],
            upper_sim_online = get_ci(sim_online)[2],
            mean_sim_retro = mean(sim_retro, na.rm = TRUE),
            lower_sim_retro = get_ci(sim_retro)[1],
            upper_sim_retro = get_ci(sim_retro)[2],
            mean_sim_lesioned = mean(sim_lesioned, na.rm = TRUE),
            lower_sim_lesioned = get_ci(sim_lesioned)[1],
            upper_sim_lesioned = get_ci(sim_lesioned)[2])

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
to_save <- to_plot %>% select(model, mean_sim, group)
write_csv(to_save, "summary3D.csv")

###################################################################
setwd("XXX")
detr_0 = read_csv("summary3D.csv")
setwd("XXX")
retinanet_0 = read_csv("summary3D.csv")
setwd("XXX")
faster_0 = read_csv("summary3D.csv")

detr_0 = detr_0 %>% mutate(NN = "detr")
retinanet_0 = retinanet_0 %>% mutate(NN = "retinanet")
faster_0 = faster_0 %>% mutate(NN = "faster")

df <- rbind(detr_0, retinanet_0, faster_0)
to_plot <- df %>% group_by(model, group) %>% 
  summarize(overall_mean_sim = mean(mean_sim),
            overall_mean_dist = mean(mean_dist))

ggplot(
  to_plot, 
  aes(x = group, y = overall_mean_sim, color = model)) + 
  geom_bar(stat = "identity", aes(x = group, y = overall_mean_sim, fill = model), position = "dodge") +
  ylim(0.0,1.0) + theme(aspect.ratio = 1)

ggplot(
  to_plot, 
  aes(x = group, y = overall_mean_dist, color = model)) + 
  geom_bar(stat = "identity", aes(x = group, y = overall_mean_dist, fill = model), position = "dodge") +
  ylim(0.0,1.0) + theme(aspect.ratio = 1)
