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

nrow(orig)
nrow(verified)
nrow(joined)

### Validation Set ###
data.size <- nrow(joined)
train.size <- round(data.size *.8, 0)
dev.size <- data.size - train.size
train_vector <- sample(data.size, train.size)

##sample random forest###
mtcars.mreg <- rfsrc(Multivar(mpg, cyl) ~., data = mtcars)
print(mtcars.mreg, outcome.target = "mpg")
head(mtcars)
head(orig)
