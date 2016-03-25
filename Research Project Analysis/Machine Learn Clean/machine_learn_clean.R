library(class)
library(caret)
library(dplyr)
install.packages('sqldf')
library(sqldf)
library(randomForest)
install.packages('rfUtilities')
library(rfUtilities)
install.packages('randomForestSRC')
library(randomForestSRC)

### Relevant to Justine set up.  

# .libPaths()
# install.packages("randomForestSRC", 
# repos=c("http://rstudio.org/_packages", "http://cran.rstudio.com"))
# setwd("C:/Users/Justine/Documents/GitHub/ficher/Research Project Analysis/Machine Learn Clean")
### continue ###

setwd("~/Desktop/ESH/ficher/Research Project Analysis/Machine Learn Clean")

orig <- read.csv('orig_broadband_line_items.csv') # predictors
verified <- read.csv('verified_broadband_line_items.csv') # outcome

nrow(verified)
nrow(orig)


#Inner join of both tables. 
joined <- merge(orig, verified, by.x=c("frn","frn_line_item_no"), by.y=c("frn","frn_line_item_no"))

# Transform rec_elig_cost to numeric. 
class(joined$rec_elig_cost.y)
joined$rec_elig_cost.y <- as.numeric(as.character(joined$rec_elig_cost.y))
joined <- joined[!is.na(joined$rec_elig_cost.y),]

View(joined)

bandwidth 
cost 
purpose



# Make smaller joined table by col name. 
mini_joined <- joined[,c("applicant_type.x","applicant_postal_cd.x","purpose.x","wan.x","bandwidth_in_mbps.x","connect_type.x","num_lines.x",
                         "total_cost.x","service_provider_name.x","contract_end_date.x","bandwidth_in_mbps.y","connect_category.y", "line_item_id.x")]

# Checking that the data looks okay once joined.
head(mini_joined)
nrow(orig)
nrow(verified)
nrow(joined)
nrow(mini_joined)

### Validation Set ###
data.size <- nrow(mini_joined)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size
training_id_integers <- sample(data.size, train.size)


# Works which is great, might introduce unexpected biases though. Could be better to random sample as an optmization. ( Maybe line items from the lowest 80%
# line_item_id's in our data size are associated with a particular states. We'd want to make it random to get a fair training set across a lot of different states)

train_data <- mini_joined[training_id_integers,]

head(train_data)
nrow(train_data)

test_data <- mini_joined[-training_id_integers,]

head(test_data)
nrow(test_data)


##multivariate random forest###
# bw_connect.mreg <- rfsrc(Multivar(bandwidth_in_mbps.y, connect_category.y) ~., data = train_data, nsplit = 10)
# print(bw_connect.mreg, outcome.target = "bandwidth_in_mbps.y")
# print(bw_connect.mreg, outcome.target = "connect_category.y")
# plot(bw_connect.mreg, outcome.target = "bandwidth_in_mbps.y", partial = TRUE, nvar=1)
# plot(bw_connect.mreg, outcome.target = "connect_category.y", partial = TRUE, nvar=1)

# plot.variable(bw_connect.mreg)

# bw_connect.mpred <- predict(bw_connect.mreg, dev_data, outcome="test")
# print(bw_connect.mpred)
# plot(bw_connect.mpred)


##Singular random forest###

# Removing Nil Values. Checking col in the dataframe for nils, 
# and seeing if the answer false for every row.

# Removing NAs in bandwidth_in_mbps
unique(is.na(train_data$bandwidth_in_mbps.x))
train_data <- train_data[!is.na(train_data$bandwidth_in_mbps.x),]
unique(is.na(test_data$bandwidth_in_mbps.x))
test_data <- test_data[!is.na(test_data$bandwidth_in_mbps.x),]


# Removing NAs in connect category
unique(is.na(train_data$connect_category.y))
train_data <- train_data[!is.na(train_data$connect_category.y),]
unique(is.na(test_data$connect_category.y))
test_data <- test_data[!is.na(test_data$connect_category.y),]

# Removing NAs in purpose
unique(is.na(train_data$purpose.x))
train_data <- train_data[!is.na(train_data$purpose.x),]
unique(is.na(test_data$purpose.x))
test_data <- test_data[!is.na(test_data$purpose.x),]

# Removing NAs in total cost. 
unique(is.na(train_data$total_cost.x))
train_data <- train_data[!is.na(train_data$total_cost.x),]
unique(is.na(test_data$total_cost.x))
test_data <- test_data[!is.na(test_data$total_cost.x),]


      
connect.forest <- randomForest(as.factor(connect_category.y) ~ bandwidth_in_mbps.x + purpose.x 
                               + total_cost.x, data=train_data, importance=T, ntree=501)
connect.forest$importance

varImpPlot(connect.forest)

predict.forest <- predict(connect.forest, test_data)
results <- data.frame(LineItemId = test_data$line_item_id.x, ConnectCategory = predict.forest)
View(results)


train_data.bw <- train_data[,c(1:11)]
train_data.connect <- train_data[,c(1:10,12)]
View(train_data.bw)
View(train_data.connect)


bw.reg <- rfsrc(bandwidth_in_mbps.y ~., data = train_data.bw, nsplit = 10)
connect.reg <- rfsrc(connect_category.y ~., data = train_data.connect, nsplit = 10)
print(bw.reg)
print(connect.reg)
plot(bw.reg)
plot(connect.reg)

bw.pred <- predict(bw.reg, dev_data, outcome="test")
connect.pred <- predict(connect.reg, dev_data, outcome="test")

connect.pred_2 <- predict(connect.reg, dev_data)

print(bw.pred)
print(connect.pred)
print(connect.pred_2)

plot(bw.pred)
plot(connect.pred)

#bw.predictions <- data.frame(cbind(bw.pred, dev_data[, 12]))

###example multivariate regression###

mtcars.mreg <- rfsrc(Multivar(mpg, cyl) ~., data = mtcars)
print(mtcars.mreg, outcome.target = "mpg")
print(mtcars.mreg, outcome.target = "cyl")
plot(mtcars.mreg, outcome.target = "mpg")

##singular random forest, diff package -- cant get to run!!###
table(train_data.bw$bandwidth_in_mbps.y)
table(train_data.connect$connect_category.y)

train_data.bw_rf <- na.omit(train_data.bw)
nrow(train_data.bw_rf)
nrow(train_data.bw)

train_data.connect_rf <- na.omit(train_data.connect)
#train_data.connect_rf$applicant_type.x <- as.character(train_data.connect_rf$applicant_type.x)
#train_data.connect_rf$applicant_postal_cd.x <- as.character(train_data.connect_rf$applicant_postal_cd.x)
#train_data.connect_rf$purpose.x <- as.character(train_data.connect_rf$purpose.x)
#train_data.connect_rf$wan.x <- as.character(train_data.connect_rf$wan.x)
#train_data.connect_rf$connect_type.x <- as.character(train_data.connect_rf$connect_type.x)
#train_data.connect_rf$contract_end_date.x <- as.character(train_data.connect_rf$contract_end_date.x)
#train_data.connect_rf$service_provider_name.x <- as.character(train_data.connect_rf$service_provider_name.x)
#train_data.connect_rf$connect_category.y <- as.character(train_data.connect_rf$connect_category.y)

head(train_data.connect_rf)

###error for 53 categories
#connect.reg_rf <- randomForest(connect_category.y ~ applicant_type.x + applicant_postal_cd.x + purpose.x
#                          +wan.x+bandwidth_in_mbps.x+connect_type.x +num_lines.x+total_cost.x
#                          +service_provider_name.x+contract_end_date.x, 
#                        data=train_data.connect_rf, importance=T, ntree=501)

connect.reg_rf <- randomForest(connect_category.y ~ bandwidth_in_mbps.x+connect_type.x, 
                         data=train_data.connect_rf, importance=T, ntree=501)

connect.reg_rf_2 <- randomForest(connect_category.y ~ total_cost.x+applicant_postal_cd.x+
                                   bandwidth_in_mbps.x+connect_type.x+ purpose.x+wan.x, 
                               data=train_data.connect_rf, importance=T, ntree=501)

str(train_data.connect_rf)
print(connect.reg_rf)
plot(connect.reg_rf)

print(connect.reg_rf_2)
plot(connect.reg_rf_2)

connect.reg_rf$importance

connect.pred_rf_2 <- predict(connect.reg_rf_2, dev_data)
##
nrow(dev_data[,1])
head(dev_data)

connect_predictions <- data.frame(cbind(connect.pred_rf_2, dev_data[,12]))
#bw_predictions$diff <- bw_predictions$V2 - bw_predictions$predict.forest
View(connect_predictions)
options(scipen=100)
#hist(bw_predictions$diff, col="dodgerblue", xlim=c(-5000,5000), breaks=30)
table(connect.pred_rf)
table(dev_data[,12])
confusionMatrix(predict.forest, reference=joined[-train_vector, 42])
connect.forest
colnames(joined)


plot(mtcars.mreg, outcome.target = "cyl")

