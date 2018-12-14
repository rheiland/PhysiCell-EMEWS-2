require(caret)
require(e1071)
require(stats)
require(randomForest)
library(data.table)

# https://cran.rstudio.com/web/packages/randomForestExplainer/vignettes/randomForestExplainer.html
install.packages("randomForestExplainer")
library(randomForestExplainer)

#df <- readRDS("./sdfs/df.Rds")
sdf <- readRDS("./sdfs/sdf_20.Rds")

sdf.ev_is <- which(sdf$ev)
sdf.unev_is <- which(!sdf$ev)

target_metric <- "fscore"
data_cols <- 1:6
n_tree <- 100

train_control <- trainControl(method="repeatedcv", number=5, repeats = 3, sampling = "up",
                              classProbs = T, summaryFunction = aprfSummary)

# Cross validate currently evaluated points
model <- train(x = sdf[sdf.ev_is,data_cols], y = make.names(factor(sdf$cl[sdf.ev_is])),
               trControl=train_control, tuneGrid = data.frame(mtry = 1:5),
               method="rf", ntree=n_tree, localImp = T,metric = target_metric)

min_depth_frame <- min_depth_distribution(model$finalModel)
plot_min_depth_distribution(min_depth_frame)

importance_frame <- measure_importance(model$finalModel)

# from here: https://stats.stackexchange.com/questions/21152/obtaining-knowledge-from-a-random-forest
plot(model$finalModel)
varImpPlot(model$finalModel)
importance(model$finalModel)

# > importance_frame
# variable mean_min_depth no_of_nodes accuracy_decrease gini_decrease no_of_trees times_a_root      p_value
# 1      user_parameters.immune_apoptosis_rate           0.82        1725        0.27581890     449.00330         100           50 1.000000e+00
# 2 user_parameters.immune_attachment_lifetime           4.95        2451        0.03812334      58.31367         100            0 5.063748e-01
# 3     user_parameters.immune_attachment_rate           1.38        2627        0.13773031     231.63017         100           28 6.095076e-05
# 4           user_parameters.immune_kill_rate           3.03        2538        0.09422737      96.72141         100            0 2.870954e-02
# 5      user_parameters.immune_migration_bias           1.90        2768        0.15525429     240.88790         100            7 2.909404e-12
# 6      user_parameters.oncoprotein_threshold           1.49        2599        0.16873992     261.55835         100           15 6.121445e-04



# Get the predictions with the get.p.sdf call, using iter 1 as a place holder, or actual iteration value
predictions_full <- get.p.sdf(sdf,1, data_cols = 1:6, n_tree = 100)
predictions <- predictions_full$p.sdf

#predictions <- df
colnames(predictions)
# Mapping the dimensions to the dXs
colnames(predictions) <- c("d1", "d6", "d3", "d5", "d4", "d2", "ev", "c", "iter", "prob")
# Possibly unneeded mapping, but is needed to run the code below
predictions$c[predictions$c=="X0"] <- '0'
predictions$c[predictions$c=="X1"] <- '1'
head(predictions)

#joziks.colors <- c('0'='green', '1'='black')
#a.color.scale <- scale_color_manual(name="c", values=joziks.colors)

dt_p <- as.data.table(predictions)
head(dt_p)
# Making it so that c == "1" is the higher probability and "0" is the lower (prob is just from 0.5-1.0)
dt_p[,fg := ifelse(c == "0",prob,1-prob)]

dt_input <- dt_p
# Making d5f, d6f column that's the factor version of d5, d6 for easy subsetting in the subsequent
dt_input <- dt_input[,d5f := as.factor(d5)]
dt_input <- dt_input[,d6f := as.factor(d6)]
dt_input[,unique(d5f)]


d5f_levels <- levels(dt_input$d5f)
length(d5f_levels)
d6f_levels <- levels(dt_input$d6f)
length(d6f_levels)

# Needed but not sure the '0' and '1' are as they are used below
fill.colors <- c('0'='darkorange1', '1'='dodgerblue3')

# Verify that fg spans 0.0-1.0
dt_input[d5f == d5f_levels[4] & d6f == d6f_levels[4], table(fg)]

#dt_input[d5f == d5f_levels[i] & d6f == d6f_levels[i]]

i <- 4
ggplot(dt_input[d5f == d5f_levels[i] & d6f == d6f_levels[i]], aes(x=d1, y=d2)) +
  coord_fixed(ratio = 1) +
  geom_raster(aes(fill=fg)) +
  scale_fill_gradient2(low = fill.colors[2], mid = "black", high = fill.colors[1], midpoint = 0.5) +
  geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '1' & ev == T], color = "yellow", size=0.8) +
  geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '0' & ev == T], color = "red", size=0.8) +
  facet_grid(d3 ~ d4) + #a.color.scale + 
  theme_bw() +
  theme(axis.title=element_blank(),
        axis.text=element_blank(),
        axis.ticks=element_blank(),
        legend.position="none",
        panel.background=element_blank(),
        panel.border=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.background = element_blank(),
        strip.text.x = element_blank(),
        strip.text.y = element_blank())


for (i in 1:length(d5f_levels)){
  p <- ggplot(dt_input[d5f == d5f_levels[i]], aes(x=d1, y=d2)) +
    coord_fixed(ratio = 1) +
    geom_raster(aes(fill=fg)) +
    scale_fill_gradient2(low = fill.colors[2], mid = "black", high = fill.colors[1], midpoint = 0.5) +
    geom_point(data=dt_input[d5f == d5f_levels[i] & c == '1' & ev == T], color = "yellow", size=0.8) +
    geom_point(data=dt_input[d5f == d5f_levels[i] & c == '0' & ev == T], color = "red", size=0.8) +
    facet_grid(d3 ~ d4) + #a.color.scale + 
    theme_bw() +
    theme(axis.title=element_blank(),
          axis.text=element_blank(),
          axis.ticks=element_blank(),
          legend.position="none",
          panel.background=element_blank(),
          panel.border=element_blank(),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.background=element_blank(),
          strip.background = element_blank(),
          strip.text.x = element_blank(),
          strip.text.y = element_blank())
  ggsave(plot = p, filename = paste0("plots/plot_wpoints_", i, ".png"), width = 10, height = 10)
}