library(tidyverse)
library(boot)
source("~/Documents/03_Yale/Projects/001_Mask_RCNN/ORB_project3/Analysis/bootstrap_helper_funs.R")

NN1 = "detr"
setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN1*"/Final_Results/Full/")
gt_v = read_delim("ground_truth_V.csv", "&")[1,2:11]
gt_v = matrix(unlist(gt_v), nrow = 5, byrow = TRUE)
v_0 = fromJSON(file = "shuffle_0_"*NN1*"/avg_v.json")
v_1 = fromJSON(file = "shuffle_1_"*NN1*"/avg_v.json")
v_2 = fromJSON(file = "shuffle_2_"*NN1*"/avg_v.json")
v_3 = fromJSON(file = "shuffle_3_"*NN1*"/avg_v.json")

average_vs <- function(v_0, v_1, v_2, v_3){
  v = matrix(NA, 5, 2)
  for (i in 1:5){
    for (j in 1:2){
      v[i,j] = (v_0$avg_v[[j]][i] + v_1$avg_v[[j]][i] + v_2$avg_v[[j]][i] + v_3$avg_v[[j]][i])/4
    }
  }
  return(v)
}

avg_v <- average_vs(v_0, v_1, v_2, v_3)
####################################################################
#Scatterplot version
avg_v = tibble(hall = avg_v[,1], miss = avg_v[,2])
gt_v = tibble(hall = gt_v[,1], miss = gt_v[,2])
avg_v = cbind(model = rep("avg_v", nrow(avg_v)), avg_v)
gt_v = cbind(model = rep("gt_v", nrow(gt_v)), gt_v)
temp = rbind(avg_v, gt_v) %>% pivot_longer(c(hall, miss))
avg_vs = temp %>% filter(model == "avg_v")
gt_vs = temp %>% filter(model == "gt_v")
to_plot = tibble(name = avg_vs$name, X = avg_vs$value, Y = gt_vs$value)
ggplot(to_plot, aes(x =  X, y = Y, color = name)) + 
  geom_point(alpha = 0.5) + ylim(c(0,1)) + xlim(c(0,1)) +
  theme(aspect.ratio = 1) + ylab("ground-truth") + xlab("inferred")
to_plot = to_plot %>% mutate(category = c(1,1,2,2,3,3,4,4,5,5))
write_csv(to_plot, "V_avg_gt.csv")
####################################################################
#Combine the NN results onto one scatterplot
setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/detr/Final_Results/Full/")
df_detr = read_csv("V_avg_gt.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/faster_rcnn/Final_Results/Full/")
df_faster_rcnn = read_csv("V_avg_gt.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/retinanet/Final_Results/Full/")
df_retinanet = read_csv("V_avg_gt.csv")

df_retinanet = df_retinanet %>% mutate(model = "retinanet")
df_faster_rcnn = df_faster_rcnn %>% mutate(model = "faster_rcnn")
df_detr = df_detr %>% mutate(model = "detr")
combined = rbind(df_retinanet, df_faster_rcnn, df_detr)

ggplot(combined, aes(x =  X, y = Y, shape = name, color = model)) + 
  geom_point(alpha = 0.5, size = 3) + ylim(c(0,1)) + xlim(c(0,1)) +
  theme(aspect.ratio = 1) + ylab("ground-truth") + xlab("inferred") +
  scale_color_manual(values=c("#003f5c", "#bc5090", "#ffa600"))

cor.test(combined$X, combined$Y)
