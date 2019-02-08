library(data.table)
library(ggplot2)

df_100 <- readRDS("~/Documents/results/physicell/paper/df_100p.Rds")
df_10p <- readRDS("~/Documents/results/physicell/paper/df_10p.Rds")
df_1p <- readRDS("~/Documents/results/physicell/paper/df_1p.Rds")

colnames(df_100)


# 1      user_parameters.immune_apoptosis_rate           0.82        1725        0.27581890     449.00330         100           50 1.000000e+00
# 2 user_parameters.immune_attachment_lifetime           4.95        2451        0.03812334      58.31367         100            0 5.063748e-01
# 3     user_parameters.immune_attachment_rate           1.38        2627        0.13773031     231.63017         100           28 6.095076e-05
# 4           user_parameters.immune_kill_rate           3.03        2538        0.09422737      96.72141         100            0 2.870954e-02
# 5      user_parameters.immune_migration_bias           1.90        2768        0.15525429     240.88790         100            7 2.909404e-12
# 6      user_parameters.oncoprotein_threshold           1.49        2599        0.16873992     261.55835         100           15 6.121445e-04

head(ga_points)

rename_dims <- function(df) {
  colnames(df) <- c("d1", "d6", "d3", "d5", "d4", "d2", "ev", "c", "prob")
  # Possibly unneeded mapping, but is needed to run the code below
  df$c[df$c=="X0"] <- '0'
  df$c[df$c=="X1"] <- '1'
  
  df$cc <- '3'
  df$cc[which(df_10p$cl == 'X0')] <- '2'
  
  df$ccc <- '5'
  df$ccc[which(df_1p$cl == 'X0')] <- '4'
  
  return(df)
}

head(df_100)
head(df_d)

df_d <- rename_dims(df_100)
dt_input <- as.data.table(df_d)

# Making it so that c == "1" is the higher probability and "0" is the lower (prob is just from 0.5-1.0)
# dt_input[,fg := ifelse(c == "0",prob,1-prob)]

# Making d5f, d6f column that's the factor version of d5, d6 for easy subsetting in the subsequent
dt_input <- dt_input[,d5f := as.factor(d5)]
dt_input <- dt_input[,d6f := as.factor(d6)]

# read ga points
ga_points <- fread("~/Documents/results/physicell/paper/ga_points.csv")
colnames(ga_points) <-  c("d1", "d6", "d3", "d5", "d4", "d2")

# find closest d5f/d6f to ga d5/d6 and set ga d5f/d6f to that
d5v <- unique(as.numeric(dt_input$d5))
ga_points$d5f <- sapply(ga_points$d5,function(x) d5v[which.min(abs(x-d5v))])
ga_points <- ga_points[,d5f := as.factor(d5f)]

d6v <- unique(as.numeric(dt_input$d6))
ga_points$d6f <- sapply(ga_points$d6,function(x) d6v[which.min(abs(x-d6v))])
ga_points <- ga_points[,d6f := as.factor(d6f)]

# find closest in dt_input and reset d3 and d4 to that
d3v <- unique(dt_input$d3)
ga_points$d3 <- sapply(ga_points$d3,function(x) d3v[which.min(abs(x-d3v))])
d4v <- unique(dt_input$d4)
ga_points$d4 <- sapply(ga_points$d4,function(x) d4v[which.min(abs(x-d4v))])

d5f_levels <- levels(dt_input$d5f)
length(d5f_levels)
d6f_levels <- levels(dt_input$d6f)
length(d6f_levels)

# Needed but not sure the '0' and '1' are as they are used below
fill.colors <- c('0'=alpha('#fc8d59', 1), '1'=alpha('dodgerblue2', 1.0), 
                 '2'=alpha('#e34a33', 1), '3'=alpha('firebrick', 0), '4'=alpha('#b30000', 1.0), 
                 '5'=alpha('firebrick', 0))
fill.alpha <- c('0'=0.5, '1'=0, '2'=0, '3'=0, '4'=0, '5'=0)
# Verify that fg spans 0.0-1.0
# dt_input[d5f == d5f_levels[4] & d6f == d6f_levels[4], table(fg)]

i <- 8
j <- 8
#unique(dt_input[d5f == d5f_levels[i] & d6f == d6f_levels[i], c])

ggplot(dt_input[d5f == d5f_levels[i] & d6f == d6f_levels[j]], aes(x=d1, y=d2)) +
  geom_raster(aes(fill=c)) +
  geom_raster(aes(fill=cc)) +
  geom_raster(aes(fill=ccc)) +
  #scale_alpha_manual(values = fill.alpha) +
  scale_fill_manual(values = fill.colors) +
  geom_point(data=ga_points[d5f == d5f_levels[i] & d6f == d6f_levels[j]], color = "green", size=1) +
  #scale_fill_gradient2(low = fill.colors[2], mid = "black", high = fill.colors[1], midpoint = 0.5) +
  #geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '1' & ev == T], color = "yellow", size=0.8) +
  #geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '0' & ev == T], color = "red", size=0.8) +
  facet_grid(d3 ~ d4) + #a.color.scale + 
  theme_bw() +
  theme(aspect.ratio = 1) +
  theme(axis.title=element_blank(),
        axis.text.x  = element_text(size=8, colour = "black",angle=90),
        axis.text.y  = element_text(size=8, colour = "black"),
        # axis.text=element_blank(),
        axis.ticks=element_blank(),
        legend.position="none",
        panel.background=element_blank(),
        panel.border=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        strip.background = element_blank(),
        strip.text.x = element_text(size=8, colour = "blue"),
        strip.text.y = element_text(size=8, colour = "red"))


for (i in 1:length(d5f_levels)) {
  for (j in 1:length(d6f_levels)) {
    p <- ggplot(dt_input[d5f == d5f_levels[i] & d6f == d6f_levels[j]], aes(x=d1, y=d2)) +
      geom_raster(aes(fill=c)) +
      geom_raster(aes(fill=cc)) +
      geom_raster(aes(fill=ccc)) +
      #scale_alpha_manual(values = fill.alpha) +
      scale_fill_manual(values = fill.colors) +
      geom_point(data=ga_points[d5f == d5f_levels[i] & d6f == d6f_levels[j]], color = "green", size=3) +
      #scale_fill_gradient2(low = fill.colors[2], mid = "black", high = fill.colors[1], midpoint = 0.5) +
      #geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '1' & ev == T], color = "yellow", size=0.8) +
      #geom_point(data=dt_input[d5f == d5f_levels[i] &  d6f == d6f_levels[i] & c == '0' & ev == T], color = "red", size=0.8) +
      facet_grid(d3 ~ d4) + #a.color.scale + 
      theme_bw() +
      theme(aspect.ratio = 1) +
      theme(axis.title=element_blank(),
            axis.text.x  = element_text(size=8, colour = "black",angle=90),
            axis.text.y  = element_text(size=8, colour = "black"),
            # axis.text=element_blank(),
            axis.ticks=element_blank(),
            legend.position="none",
            panel.background=element_blank(),
            panel.border=element_blank(),
            panel.grid.major=element_blank(),
            panel.grid.minor=element_blank(),
            plot.background=element_blank(),
            strip.background = element_blank(),
            strip.text.x = element_text(size=8, colour = "blue"),
            strip.text.y = element_text(size=8, colour = "red"))
      ggsave(plot = p, filename = paste0("~/Documents/results/physicell/paper/plot_wpoints_", i, "_", j, ".png"), width = 10, height = 10)
  }
}





