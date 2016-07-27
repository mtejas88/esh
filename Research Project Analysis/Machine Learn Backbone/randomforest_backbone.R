  ##packages
  library(randomForest)
  library(caret)
  #library(tree)
  #library(party)
  #install.packages("party", 
  #                 repos=c("http://rstudio.org/_packages", "http://cran.rstudio.com"))
  
  setwd("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Data Strategy/Machine Learn Clean")
  
  ##importing and merging 2015 verified files
  verified <- read.csv('verified_and_inferred_or_backbone.csv') # outcome
  cross <- unique(verified)
  
  ##creating 2015 verified variables
  cross <- cross[as.character(cross$backbone_conditions_met) %in% c('FALSE', 'TRUE'),]
  cross$backbone_conditions_met <- as.factor(cross$backbone_conditions_met)
  cross$backbone_conditions_met <- droplevels(cross$backbone_conditions_met)
  cross$rec_elig_cost <- as.numeric(cross$rec_elig_cost)
  cross$cost_per_circuit <- (cross$rec_elig_cost+(cross$one_time_eligible_cost/12))/cross$num_lines
  cross$cost_per_mbps <- cross$cost_per_circuit/cross$bandwidth_in_mbps
  cross <- cross[is.finite(cross$cost_per_circuit),]
  
  ###test and train on 2015 verified data
  data.size <- nrow(cross)
  train.size <- round(data.size *.8, 0)
  dev.size <- data.size - train.size
  train_vector <- sample(data.size, train.size)
  cross.train <- cross[train_vector,] 
  cross.test <- cross[-train_vector,]
  
  ##running classification
  backbone.forest.2016 <- randomForest(backbone_conditions_met ~ internet_conditions_met + upstream_conditions_met +
                                      +wan_conditions_met + isp_conditions_met +applicant_type+cost_per_circuit
                                      +connect_type
                                      +bandwidth_in_mbps+num_lines, data=cross.test, 
                                      importance=T, ntree=501)
  varImpPlot(backbone.forest.2016)
  backbone.forest.2016$importance
  
  ##accuracy measure
  predict.backbone.forest.2016 <- predict(backbone.forest.2016, cross.test)
  predict.prob.backbone.forest.2016 <- predict(backbone.forest.2016, cross.test, "prob")
  cross.test$predicted_category <- predict.backbone.forest.2016
  cross.test$probability <- predict.prob.backbone.forest.2016
  confusionMatrix(predict.backbone.forest.2016, reference = cross.test$backbone_conditions_met) #accuracy = 100% excluding train set
  
  ##IDing new backbone
  orig <- read.csv('orig_broadband_line_items.csv') # outcome
  orig <- unique(orig)
  
  orig$rec_elig_cost <- as.numeric(orig$rec_elig_cost)
  orig$cost_per_circuit <- (orig$rec_elig_cost+(orig$one_time_eligible_cost/12))/orig$num_lines
  orig$cost_per_mbps <- orig$cost_per_circuit/orig$bandwidth_in_mbps
  orig <- cross[is.finite(orig$cost_per_circuit),]
  orig <- orig[orig$connect_type != 'Data Plan/Air Card Service',]
  orig$connect_type <- droplevels(orig$connect_type)
  levels(orig$connect_type) <- levels(cross$connect_type)
  orig <- orig[orig$applicant_type %in% c('Consortium', 'District', 'OtherLocation', 'School'),]
  orig$applicant_type <- droplevels(orig$applicant_type)
  levels(orig$applicant_type) <- levels(cross$applicant_type)
  
  predict.backbone.forest.2016.all <- predict(backbone.forest.2016, orig)
  predict.prob.backbone.forest.2016.all <- predict(backbone.forest.2016, orig, "prob")
  orig$predicted_category <- predict.backbone.forest.2016.all
  orig$probability <- predict.prob.backbone.forest.2016.all
  confusionMatrix(predict.backbone.forest.2016.all, reference = orig$backbone_conditions_met) #accuracy = 100% including train set
  write.csv(orig, "backbone_predict_cross_all.csv", row.names = FALSE) #prediction for all verified line items
