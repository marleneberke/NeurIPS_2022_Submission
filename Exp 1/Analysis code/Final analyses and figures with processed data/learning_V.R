library(tidyverse)

############################################################
#show learning V averaged across runs
'*' <- function(x, y)paste0(x,y)
NN = "faster_rcnn"
setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/"*NN*"/Final_Results/Full/")

ground_truth_V = read_delim("ground_truth_V.csv", delim='&')

online_0 = read_csv("shuffle_0_"*NN*"/online_V_processed.csv")
online_1 = read_csv("shuffle_1_"*NN*"/online_V_processed.csv")
online_2 = read_csv("shuffle_2_"*NN*"/online_V_processed.csv")
online_3 = read_csv("shuffle_3_"*NN*"/online_V_processed.csv")

merged1 = merge(online_0, online_1, by = c("order_run"), suffixes = c(".0",".1"))
merged2 = merge(online_2, online_3, by = c("order_run"), suffixes = c(".2",".3"))
merged = merge(merged1, merged2, by = c("order_run"))

df <- merged %>% mutate(MSE = (MSE.0 + MSE.1 + MSE.2 + MSE.3)/4,
                        upper = (upper_MSE.0 + upper_MSE.1 + upper_MSE.2 + upper_MSE.3)/4,
                        lower = (lower_MSE.0 + lower_MSE.1 + lower_MSE.2 + lower_MSE.3)/4)

df <- df %>% select(order_run, MSE, upper, lower)
write_csv(df, "V_summary.csv")

ggplot(
  df,
  aes(
    x = order_run,
    y = MSE,
    ymin = lower,
    ymax = upper,
  )
) + geom_line() + geom_ribbon(alpha = 0.5) +
  theme(aspect.ratio = 1)

############################################################

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/retinanet/Final_Results/Full/")
df_retinanet = read_csv("V_summary.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/faster_rcnn/Final_Results/Full/")
df_faster_rcnn = read_csv("V_summary.csv")

setwd("~/Documents/03_Yale/Projects/001_Mask_RCNN/scratch_work_07_16_21/05_09_22/detr/Final_Results/Full/")
df_detr = read_csv("V_summary.csv")

df_retinanet = df_retinanet %>% mutate(model = "retinanet")
df_faster_rcnn = df_faster_rcnn %>% mutate(model = "faster_rcnn")
df_detr = df_detr %>% mutate(model = "detr")

combined = rbind(df_retinanet, df_faster_rcnn, df_detr)

# faster_rcnn_mse_lesioned = 0.5272 #calculated by hand from ground_truth_V.csv
# retinanet_mse_lesioned = 0.47065
# detr_mse_lesioned = 2.3625

ggplot(
  combined,
  aes(
    x = order_run,
    y = MSE,
    ymin = lower,
    ymax = upper,
    fill = model,
    color = model
  )
) + geom_line() + geom_ribbon(alpha = 0.5) +
  theme(aspect.ratio = 1) + 
  scale_fill_manual(values=c("#003f5c", "#bc5090", "#ffa600")) +
  scale_color_manual(values=c("#003f5c", "#bc5090", "#ffa600"))

