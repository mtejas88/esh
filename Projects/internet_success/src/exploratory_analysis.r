## EXPLORATORY ANALYSIS

## clear memory
rm(list=ls())

## set working directory
setwd("~/GitHub/ficher/Projects/internet_success")

## read in data
tx_data <- read.csv("data/tx_data.csv", as.is=T, header=T, stringsAsFactors=F)

## libaries
library(ggplot2)
library(corrplot)

summary(tx_data)
head(tx_data)


## Corplot of some of the numeric variables
tx1 <- tx_data[,c("grad_percent_change","num_students","num_schools","frl_percent",
                  "total_bw_16","total_bw_15","student_teacher_ratio","percent_c2_budget_used")]
head(tx1)

cor.data <- cor(tx1)
print(corrplot(cor.data,method = 'color'))

## Scatterplot of data

a <- ggplot(data = tx_data, aes(x=percent_bw_per_student_change,y=grad_percent_change))

b <- a + geom_point(alpha=.25) + labs(title ='All TX Data', x = 'BW/student percent change', y = 'Graduation rate percent change')
print(b)
ggsave("all_tx_data_plot.png",width = 5, height = 5)

#c <- a + geom_point(alpha=.8,aes(size = num_students,color = num_students))
#print(c)
#d <- c + scale_color_gradient(low = 'blue', high = 'red')
#print(d)

## Try to look at random 100

random100 <- tx_data[sample(nrow(tx_data),100),]

random100plot <- (ggplot(data = random100, aes(x=percent_bw_per_student_change,y=grad_percent_change)) 
                  + geom_point(alpha=.4) 
                  + labs(title ='Random 100 Sample', x = 'BW/student percent change', y = 'Graduation rate percent change'))
print(random100plot)
ggsave("random100sampleplot.png",width = 5, height = 5)

## Remove outliers for main data points, for 2 & 3 standard dev from mean

## bw per student percent change 

stdv <- sd(tx_data$percent_bw_per_student_change)
mn <- mean(tx_data$percent_bw_per_student_change)

rm_outliers_2 <- tx_data[(tx_data$percent_bw_per_student_change > mn - 2 * stdv) & (tx_data$percent_bw_per_student_change < mn + 2 * stdv),]

rm_outliers_3 <- tx_data[(tx_data$percent_bw_per_student_change > mn - 3 * stdv) & (tx_data$percent_bw_per_student_change < mn + 3 * stdv),]

## graduation rate percent change

stdv <- sd(tx_data$grad_percent_change)
mn <- mean(tx_data$grad_percent_change)

rm_outliers_2 <- rm_outliers_2[(rm_outliers_2$grad_percent_change > mn - 2 * stdv) 
                               & (rm_outliers_2$grad_percent_change < mn + 2 * stdv),] 
                
rm_outliers_3 <-rm_outliers_3[(rm_outliers_3$grad_percent_change > mn - 3 * stdv) 
                              & (rm_outliers_3$grad_percent_change < mn + 3 * stdv),]
                
# Plot data set limited to 2 st dev
rm_outliers_plot_2 <- (ggplot(data = rm_outliers_2, aes(x=percent_bw_per_student_change,y=grad_percent_change)) 
                    + geom_point(alpha=.4) 
                    + labs(title ='Outliers removed (2 SD)', x = 'BW/student percent change', y = 'Graduation rate percent change')
                    )
print(rm_outliers_plot_2)
ggsave("2_st_dev_removed.png",width = 5, height = 5)


# Plot data set limited to 3 st dev
rm_outliers_plot_3 <- (ggplot(data = rm_outliers_3, aes(x=percent_bw_per_student_change,y=grad_percent_change)) 
                       + geom_point(alpha=.4)
                       + labs(title ='Outliers removed (3 SD)', x = 'BW/student percent change', y = 'Graduation rate percent change')
                       )
print(rm_outliers_plot_3)
ggsave("3_st_dev_removed.png",width = 5, height = 5)




## write out outlier removed data
write.csv(rm_outliers_2, "data/rm_outliers_2.csv", row.names = FALSE)
write.csv(rm_outliers_3, "data/rm_outliers_3.csv", row.names = FALSE)
