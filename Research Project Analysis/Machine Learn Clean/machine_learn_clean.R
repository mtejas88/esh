library(class)
library(caret)
library(dplyr)
library(sqldf)
library(randomForest)
library(rfUtilities)
library(randomForestSRC)
.libPaths()
install.packages("randomForestSRC", 
  repos=c("http://rstudio.org/_packages", "http://cran.rstudio.com"))


setwd("C:/Users/Justine/Documents/GitHub/ficher/Research Project Analysis/Machine Learn Clean")
orig <- read.csv('orig_broadband_line_items.csv') # predictors
verified <- read.csv('verified_broadband_line_items.csv') # outcome


joined <- merge(orig, verified, by.x=c("frn","frn_line_item_no"), by.y=c("frn","frn_line_item_no"))

head(joined)
class(joined$rec_elig_cost.y)
joined$rec_elig_cost.y <- as.numeric(as.character(joined$rec_elig_cost.y))
joined <- joined[!is.na(joined$rec_elig_cost.y),]

mini_joined <- joined[,c(5,8,10,11,12,13,15,18,19,26,36,38)]
head(mini_joined)

nrow(orig)
nrow(verified)
nrow(joined)

### Validation Set ###
data.size <- nrow(mini_joined)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size

train_data <- mini_joined[1:train.size,]
head(train_data)
nrow(train_data)

##multivariate random forest###
bw_connect.mreg <- rfsrc(Multivar(bandwidth_in_mbps.y, connect_category.y) ~., data = train_data)
print(bw_connect.mreg, outcome.target = "bandwidth_in_mbps.y")
print(bw_connect.mreg, outcome.target = "connect_category.y")
plot(bw_connect.mreg, outcome.target = "bandwidth_in_mbps.y")
plot(bw_connect.mreg, outcome.target = "connect_category.y")

##singular random forest###
train_data.bw <- train_data[,c(1:11)]
train_data.connect <- train_data[,c(1:10,12)]

bw.reg <- rfsrc(bandwidth_in_mbps.y ~., data = train_data.bw)
connect.reg <- rfsrc(connect_category.y ~., data = train_data.connect)
print(bw.reg)
print(connect.reg)
plot(bw.reg)
plot(connect.reg)

##singular random forest, diff package###
bw.reg_rf <- randomForest(bandwidth_in_mbps.y ~ ., 
                               data=train_data.bw, importance=T, ntree=501)
connect.reg_rf <- randomForest(connect_category.y ~ ., 
                          data=train_data.connect, importance=T, ntree=501)
print(bw.reg_rf)
print(connect.reg_rf)
plot(bw.reg_rf)
plot(connect.reg_rf)

###example multivariate regression###

mtcars.mreg <- rfsrc(Multivar(mpg, cyl) ~., data = mtcars)
print(mtcars.mreg, outcome.target = "mpg")
print(mtcars.mreg, outcome.target = "cyl")
plot(mtcars.mreg, outcome.target = "mpg")
plot(mtcars.mreg, outcome.target = "cyl")

