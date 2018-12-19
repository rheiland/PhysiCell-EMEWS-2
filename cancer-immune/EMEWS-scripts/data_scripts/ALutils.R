require(caret)
require(e1071)
require(stats)
require(randomForest)

get_accuracy_precision_recall_fscore <- function(confusion,positive){
  p_i = which(colnames(confusion) == positive)
  
  total <- sum(confusion)
  tp <- confusion[p_i,p_i]
  tn <- confusion[-p_i,-p_i]
  fp <- confusion[p_i,-p_i]
  fn <- confusion[-p_i,p_i]
  
  accuracy <- (tp + tn) / total
  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  f1_score <- 2 * precision * recall / (precision + recall)
  list(accuracy = accuracy, precision = precision, recall = recall, fscore = f1_score)
}

# summary statistics
aprfSummary <- function(data, lev = NULL, model = NULL){
  cf <- confusionMatrix(data[,"pred"], data[,"obs"])
  unlist(get_accuracy_precision_recall_fscore(as.matrix(cf),lev[2]))
}


get.p.sdf <- function(sdf, iter, target_metric = "fscore", data_cols = 1:2, n_tree = 20){
  sdf.ev_is <- which(sdf$ev)
  sdf.unev_is <- which(!sdf$ev)
  
  train_control <- trainControl(method="repeatedcv", number=10, repeats = 1, sampling = "up",
                                classProbs = T, summaryFunction = aprfSummary)
  
  # Cross validate currently evaluated points
  model <- train(x = sdf[sdf.ev_is,data_cols], y = make.names(factor(sdf$cl[sdf.ev_is])),
                 trControl=train_control, tuneGrid = data.frame(mtry = 3),
                 method="rf", ntree=n_tree, metric = target_metric)
  stat_names <- c("accuracy","precision","recall","fscore")
  stat_sd_names <- paste0(stat_names,"SD")
  
  cv_means <- c(iter = iter, model$results[stat_names])
  cv_sds <- c(iter = iter, model$results[stat_sd_names])
  
  pred <- predict(model,newdata = sdf[sdf.unev_is,data_cols], type = "raw")
  
  # record classification
  p_sdf = sdf
  p_sdf["iter"] <- iter
  
  p_sdf[sdf.unev_is,"cl"] <- as.character(pred)
  # record probability
  unev_prob <- predict(model,newdata = sdf[sdf.unev_is,data_cols], type = "prob")
  p_sdf[sdf.ev_is,"prob"] <- 1
  pred.c1_is <- which(pred == "X1")
  pred.c0_is <- which(pred == "X0")
  p_sdf[sdf.unev_is[pred.c0_is],"prob"] <- unev_prob[pred.c0_is,"X0"]
  p_sdf[sdf.unev_is[pred.c1_is],"prob"] <- unev_prob[pred.c1_is,"X1"]
  return(list(p.sdf=p_sdf, cv.means = cv_means, cv.sds = cv_sds))
}