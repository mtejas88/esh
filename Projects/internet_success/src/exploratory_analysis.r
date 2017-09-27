## EXPLORATORY ANALYSIS

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
tx_data <- read.csv("data/tx_data.csv", as.is=T, header=T, stringsAsFactors=F)

## libaries
library(ggplot2)

summary(tx_data)

tx1 <- tx_data[,c("grad_percent_change","num_students","num_schools","num_campuses","frl_percent","total_bw_16","total_bw_15")]
cor.data <- cor(tx1)
print(corrplot(cor.data,method = 'color'))



a <- ggplot(data = tx_data, aes(x=percent_bw_per_student_change,y=grad_percent_change))

b <- a + geom_point(alpha=.8)
print(b)

c <- a + geom_point(alpha=.8,aes(size = num_students,color = num_students))
print(c)

c + scale_color_gradient(low = 'blue', high = 'red')


