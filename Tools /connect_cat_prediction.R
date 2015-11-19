###	Predicting Line Item Connect Category ###
#	Author: Carson Forter
#	Created On Date: 11/16/2015
#	Last Modified Date: 11/17/2015
#	Name of QAing Analyst: Still needs to be QAed

library(class)
library(caret)
library(randomForest)

li <- querydb("line_items.sql")  # raw line items, where exclude = false
orig.data <- read.csv("unmodified_usac_data.csv")  # old USAC data from GK

### Create data set for training model ###

# Inner join clean line items to old USAC data
connect.cat <- merge(li[, c(1,47)], orig.data, all.x=F, all.y=T, by.x="id", by.y="id")

# Create variables 
connect.cat$WAN.num <- ifelse(connect.cat$WAN == "Y", 1, 0)
connect.cat$down.speed.mbps <- connect.cat$Down.Speed1
connect.cat$down.speed.mbps[connect.cat$Down.Speed2 == "Gbps"] <- connect.cat$down.speed.mbps[connect.cat$Down.Speed2 == "Gbps"] * 1000
#connect.cat$down.speed.mbps <- log(connect.cat$down.speed.mbps)  # log did not improve model accuracy
#connect.cat$down.speed.mbps[connect.cat$down.speed.mbps==-Inf] <- NA

# Exclude territories
connect.cat <- subset(connect.cat, !(connect.cat$postal_cd %in% 
                                       c("PR", "DC", "GU", "MP", "VI", "WV", "AS", " ")))
connect.cat$postal_cd <- factor(connect.cat$postal_cd)

# Split data into train and test sets, only include subset of variable for prediction
data.size <- nrow(connect.cat)
train.size <- round(data.size *.8, 0)
train.vector <- sample(data.size, train.size)

# Models include downstream speed, total cost, number of lines,
# and whether it is WAN. Remove any records with NAs.
connect.cat.train <- connect.cat[train.vector, c(10,28,56,57,2)]
connect.cat.train <- connect.cat.train[complete.cases(connect.cat.train),]
connect.cat.test <- connect.cat[-train.vector,c(10,28,56,57,2)]
connect.cat.test <- connect.cat.test[complete.cases(connect.cat.test),]

### K Nearest Neighbors ###
# Accuracy ~ 65%
# Predicted variable is connect category
connect.model <- knn(connect.cat.train[,c(1:4)], connect.cat.test[,c(1:4)], 
                     cl=connect.cat.train[,5], k=10)

model.predictions <- as.character(connect.model)
predict.df <- cbind(model.predictions=model.predictions, actual.values=connect.cat.test[,5])
confusionMatrix(model.predictions, reference=connect.cat.test[,5])

### Random Forest ###
# Accuracy ~ 75%
connect.forest <- randomForest(as.factor(connect_category) ~ ., data=connect.cat.train[,c(1:5)], importance=T, ntrees=501)
connect.forest$importance  # shows importance of predictors
predict.forest <- predict(connect.forest, connect.cat.test[,c(1:4)])
confusionMatrix(predict.forest, reference=connect.cat.test[,5])

### Random Forest With Service and Connect Type ###
# Accuracy ~ 90%
# Includes same variables and previous models along with service type and connect type
connect.cat.train <- connect.cat[train.vector, c(10,28,56,57,26,35,2)]
connect.cat.train <- connect.cat.train[complete.cases(connect.cat.train),]
connect.cat.test <- connect.cat[-train.vector,c(10,28,56,57,26,35,2)]
connect.cat.test <- connect.cat.test[complete.cases(connect.cat.test),]

connect.forest <- randomForest(as.factor(connect_category) ~ ., data=connect.cat.train, importance=T, ntrees=501)

connect.forest$importance
predict.forest <- predict(connect.forest, connect.cat.test[,c(1:6)])
confusionMatrix(predict.forest, reference=connect.cat.test[,7])

### Find Correct Categories By Connect Type ###
table(li$connect_category, li$connect_type)
unique(connect.cat$Connect.Type)
unique(li$connect_type)

