## =========================================
##
## ** in the future can make python notebook **
## EXAMINE DATA: Visualize Ranking
## Looking into holistic cost/bw metric
##
## =========================================

## Clearing memory
rm(list=ls())

## MARK, THIS IS THE ONLY THING YOU SHOULD HAVE TO CHANGE
## user entered: $/student
## some suggested values, $3, $5, $10, $15, $20, $30
monthly.cost.threshold <- 5

## load packages (if not already in the environment)
packages.to.install <- c("scales", "plyr")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(scales)
library(plyr)

##**************************************************************************************************************************************************
## READ IN DATA

## districts deluxe
dd.2016 <- read.csv("data/raw/deluxe_districts_2016.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************
## SUBSET AND FORMAT DATA

## subset to clean districts
dd.2016 <- dd.2016[dd.2016$exclude_from_ia_analysis == FALSE,]

## apply logic for holistic cost metric
## total internet cost (IA + WAN) / number of students / bw per student (kbps)
dd.2016$monthly.total.cost.per.student <- (dd.2016$ia_monthly_cost_total + dd.2016$wan_monthly_cost_total) / dd.2016$num_students

##**************************************************************************************************************************************************
## visualize relationships: total_monthly_cost_per_student vs ia_bandwidth_per_student_kbps

## examine monthly total cost per student metric
## min and max:
min(dd.2016$monthly.total.cost.per.student, na.rm=T)
max(dd.2016$monthly.total.cost.per.student, na.rm=T)
## quantiles in intervals of 10:
quantile(dd.2016$monthly.total.cost.per.student, probs=seq(0,1,by=0.10))
## mean and median:
mean(dd.2016$monthly.total.cost.per.student, na.rm=T)
median(dd.2016$monthly.total.cost.per.student, na.rm=T)

## plot the distribution:
## *** taking out the outliers (66 districts)
hist.sub <- dd.2016[which(dd.2016$monthly.total.cost.per.student <= 100),]
pdf("figures/distribution_monthly_total_cost_per_student.pdf", height=5, width=6)
hist(hist.sub$monthly.total.cost.per.student,
     col=rgb(0,0,0,0.6), border=F, breaks=seq(0,100,by=2),
     main="Monthly Total Cost per Student", xlab="", ylab="")
## draw a line at the monthly cost threshold
abline(v=monthly.cost.threshold, lwd=1.5, col=rgb(1,0,0,0.6))
dev.off()

## how many districts fall below the cost threshold? (number of TRUEs)
table(dd.2016$monthly.total.cost.per.student <= monthly.cost.threshold)


## examine ia bandwidth per student (kbps) metric
## min and max:
min(dd.2016$ia_bandwidth_per_student_kbps, na.rm=T)
max(dd.2016$ia_bandwidth_per_student_kbps, na.rm=T)
## quantiles in intervals of 10:
quantile(dd.2016$ia_bandwidth_per_student_kbps, probs=seq(0,1,by=0.10))
## mean and median:
mean(dd.2016$ia_bandwidth_per_student_kbps, na.rm=T)
median(dd.2016$ia_bandwidth_per_student_kbps, na.rm=T)

## plot the distribution:
## *** taking out outliers (987 districts)
hist.sub <- dd.2016[which(dd.2016$ia_bandwidth_per_student_kbps <= 1500),]
pdf("figures/distribution_ia_bandwidth_per_student.pdf", height=5, width=6)
hist(hist.sub$ia_bandwidth_per_student_kbps,
     col=rgb(0,0,0,0.6), border=F, breaks=seq(0,1500,by=10),
     main="IA Bandwidth per Student (kbps)", xlab="", ylab="")
## mark 100 kbps, 500 kbps, and 1000 kbps
abline(v=100, lwd=1.5, col=rgb(1,0,0,0.6))
abline(v=500, lwd=1.5, col=rgb(1,0,0,0.6))
abline(v=1000, lwd=1.5, col=rgb(1,0,0,0.6))
dev.off()

## how many districts fall below the 3 thresholds? (number of TRUEs)
table(dd.2016$ia_bandwidth_per_student_kbps < 100)
table(dd.2016$ia_bandwidth_per_student_kbps < 500)
table(dd.2016$ia_bandwidth_per_student_kbps < 1000)

## subset variables
dd.2016.sub <- dd.2016[,c('esh_id', 'name', 'postal_cd', 'district_size', 'num_students', 'num_schools',
                          'ia_bandwidth_per_student_kbps', 'monthly.total.cost.per.student',
                          'ia_monthly_cost_total', 'wan_monthly_cost_total',
                          'ia_monthly_cost_per_mbps', 'ia_bw_mbps_total', 'meeting_knapsack_affordability_target')]

## assign the ranking groupings

dd.2016.sub$ranking <- ifelse(dd.2016.sub$ia_bandwidth_per_student_kbps < 100, 1,
                          ifelse(dd.2016.sub$ia_bandwidth_per_student_kbps < 1000 & dd.2016.sub$monthly.total.cost.per.student > monthly.cost.threshold, 2,
                             ifelse(dd.2016.sub$ia_bandwidth_per_student_kbps < 500 & dd.2016.sub$monthly.total.cost.per.student <= monthly.cost.threshold, 3,
                                ifelse(dd.2016.sub$ia_bandwidth_per_student_kbps >= 1000 & dd.2016.sub$monthly.total.cost.per.student > monthly.cost.threshold, 4, 5))))

##**************************************************************************************************************************************************
## plot the rankings

## separate out the schools with less than and greater than 1,000 students
dd.2016.sub.less.1000 <- dd.2016.sub[which(dd.2016.sub$num_students <= 1000),]
dd.2016.sub.greater.1000 <- dd.2016.sub[which(dd.2016.sub$num_students > 1000),]

## *** NOTE: we are subsetting the y-axis for all of these plots, so cutting out a few outliers that are getting > 10,000 kbps/student

## A) plot segmented by rankings, weighting the points by number of students
pdf("figures/total_cost_per_student_by_bw_per_student_weighted.pdf", height=5, width=10)
layout(matrix(c(1,2), nrow=1, ncol=2))
## plot schools less than or equal to 1,000 students
plot(dd.2016.sub.less.1000$monthly.total.cost.per.student, dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,200), cex=1/5*(sqrt(dd.2016.sub.less.1000$num_students)/pi),
     xlab="Total Monthly Cost/Student ($)", ylab="IA BW/Student (kbps)", main="<= 1,000 Students")
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
#abline(a=-750, b=110, col=rgb(0,0,1,0.7), lwd=2)

## plot schools greater than 1,000 students
plot(dd.2016.sub.greater.1000$monthly.total.cost.per.student, dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,100), cex=1/20*(sqrt(dd.2016.sub.greater.1000$num_students)/pi),
     xlab="", ylab="", main="> 1,000 Students")
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
dev.off()


## B) plot segmented by rankings, unweighted points
pdf("figures/total_cost_per_student_by_bw_per_student_unweighted.pdf", height=5, width=10)
layout(matrix(c(1,2), nrow=1, ncol=2))
## plot schools less than or equal to 1,000 students
plot(dd.2016.sub.less.1000$monthly.total.cost.per.student, dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,200),
     xlab="Total Monthly Cost/Student ($)", ylab="IA BW/Student (kbps)", main="<= 1,000 Students")
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
#abline(a=-750, b=110, col=rgb(0,0,1,0.7), lwd=2)

## plot schools greater than 1,000 students
plot(dd.2016.sub.greater.1000$monthly.total.cost.per.student, dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,100),
     xlab="", ylab="", main="> 1,000 Students")
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
dev.off()


## C) plot segmented by rankings, weighted and colored points
## generate colors
colors <- palette(rainbow(5))
pdf("figures/total_cost_per_student_by_bw_per_student_weighted_colored.pdf", height=5, width=10)
layout(matrix(c(1,2), nrow=1, ncol=2))
## plot schools less than or equal to 1,000 students
plot(dd.2016.sub.less.1000$monthly.total.cost.per.student, dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.0), ylim=c(0,10000), xlim=c(0,200),
     xlab="Total Monthly Cost/Student ($)", ylab="IA BW/Student (kbps)", main="<= 1,000 Students")
## plot points colored by category
for (i in 1:length(unique(dd.2016.sub.less.1000$ranking))){
  points(dd.2016.sub.less.1000$monthly.total.cost.per.student[dd.2016.sub.less.1000$ranking == i],
         dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps[dd.2016.sub.less.1000$ranking == i],
         pch=16, col=alpha(colors[i], 0.5), cex=1/20*(sqrt(dd.2016.sub.greater.1000$num_students)/pi))
}
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)


## plot schools greater than 1,000 students
plot(dd.2016.sub.greater.1000$monthly.total.cost.per.student, dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,100),
     xlab="", ylab="", main="> 1,000 Students")
## plot points colored by category
for (i in 1:length(unique(dd.2016.sub.greater.1000$ranking))){
  points(dd.2016.sub.greater.1000$monthly.total.cost.per.student[dd.2016.sub.greater.1000$ranking == i],
         dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps[dd.2016.sub.greater.1000$ranking == i],
         pch=16, col=alpha(colors[i], 0.5), cex=1/20*(sqrt(dd.2016.sub.greater.1000$num_students)/pi))
}
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.greater.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
dev.off()


## D) plot segmented by rankings, unweighted and colored points
## generate colors
colors <- palette(rainbow(5))
pdf("figures/total_cost_per_student_by_bw_per_student_unweighted_colored.pdf", height=5, width=10)
layout(matrix(c(1,2), nrow=1, ncol=2))
## plot schools less than or equal to 1,000 students
plot(dd.2016.sub.less.1000$monthly.total.cost.per.student, dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.0), ylim=c(0,10000), xlim=c(0,200),
     xlab="Total Monthly Cost/Student ($)", ylab="IA BW/Student (kbps)", main="<= 1,000 Students")
## plot points colored by category
for (i in 1:length(unique(dd.2016.sub.less.1000$ranking))){
  points(dd.2016.sub.less.1000$monthly.total.cost.per.student[dd.2016.sub.less.1000$ranking == i],
         dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps[dd.2016.sub.less.1000$ranking == i],
         pch=16, col=alpha(colors[i], 0.5))
}
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.less.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.less.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)


## plot schools greater than 1,000 students
plot(dd.2016.sub.greater.1000$monthly.total.cost.per.student, dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps,
     pch=16, col=rgb(0,0,0,0.5), ylim=c(0,10000), xlim=c(0,100),
     xlab="", ylab="", main="> 1,000 Students")
## plot points colored by category
for (i in 1:length(unique(dd.2016.sub.greater.1000$ranking))){
  points(dd.2016.sub.greater.1000$monthly.total.cost.per.student[dd.2016.sub.greater.1000$ranking == i],
         dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps[dd.2016.sub.greater.1000$ranking == i],
         pch=16, col=alpha(colors[i], 0.5))
}
## draw straight lines at kbps/student
abline(h=100, col=rgb(1,0,0,0.7), lwd=2)
segments(-10, 500, monthly.cost.threshold, 500, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 1000, max(dd.2016.sub.greater.1000$monthly.total.cost.per.student), 1000, col=rgb(1,0,0,0.7), lwd=2)
segments(monthly.cost.threshold, 100, monthly.cost.threshold, max(dd.2016.sub.greater.1000$ia_bandwidth_per_student_kbps), col=rgb(1,0,0,0.7), lwd=2)
dev.off()

##**************************************************************************************************************************************************
## create subsets across three groups
## generate histograms of number of students and schools in each category
## write them out to a csv

for (i in 1:5){
  print(paste("Ranking Group: ", i, sep=""))
  sub <- dd.2016.sub[which(dd.2016.sub$ranking == i),]
  print(paste("Number of Districts in Group: ", nrow(sub), sep=""))
  
  ## create histograms of number of students and schools in each ranking group
  ## *** the first plot takes out the top 10th percentile outliers of number of students
  hist.sub <- sub[which(sub$num_students < quantile(sub$num_students, probs=seq(0,1,0.10))[10]),]
  pdf(paste("figures/distribution_num_students_ranking_", i, ".pdf", sep=""), height=5, width=6)
  hist(hist.sub$num_students,
       col=rgb(0,0,0,0.6), border=F, breaks=seq(0, round_any(max(hist.sub$num_students, na.rm=T), 10, f=ceiling), by=10),
       main=paste("Number of Students, Ranking Group ", i, sep=""), xlab="", ylab="")
  dev.off()

  hist.sub <- sub
  pdf(paste("figures/distribution_num_schools_ranking_", i, ".pdf", sep=""), height=5, width=6)
  hist(hist.sub$num_schools,
       col=rgb(0,0,0,0.6), border=F, breaks=seq(0, round_any(max(hist.sub$num_schools, na.rm=T), 10, f=ceiling), by=2),
       main=paste("Number of Schools, Ranking Group ", i, sep=""), xlab="", ylab="")
  dev.off()  

  ## write out the datasets
  write.csv(sub, paste("data/interim/group_", i, ".csv", sep=''))
  assign(paste("sub", i, sep="."), sub)
}
