#read in data
districts=read.csv("../data/raw/districts.csv", header=T, as.is=T)
districts_exp=read.csv("../data/raw/districts_exp.csv", header=T, as.is=T)

packages.to.install <- c("ggplot2","dplyr","shiny","reshape2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(ggplot2)
library(dplyr)
library(shiny)

theme_esh <- function(){
  theme(
    text = element_text(color="#666666", size=13),
    panel.grid.major = element_line(color = "light grey"),
    panel.grid.major.x = element_blank(),
    panel.background = element_rect(fill = "white")
  )
}

#filter out districts with $0 monthly cost
districts=districts %>% filter(ia_monthly_cost_per_mbps_17 > 0 & ia_monthly_cost_per_mbps_16 > 0 & ia_monthly_cost_per_mbps_15 > 0)
names(districts)=c("esh_id", "name","postal_cd","county","num_students","ia_monthly_cost_per_mbps_2017","bandwidth_per_student_kbps_2017", 
                   "ia_monthly_cost_per_mbps_2016","bandwidth_per_student_kbps_2016", "ia_monthly_cost_per_mbps_2015", "bandwidth_per_student_kbps_2015")

districts_exp=districts_exp %>% filter(ia_monthly_cost_per_mbps > 0 & ia_monthly_cost_per_mbps > 0)

#scatterplot of monthly IA cost per mbps vs. bw per student in 2017 - as is
p <- ggplot(districts, aes(x = bandwidth_per_student_kbps_17, y = ia_monthly_cost_per_mbps_17))

p + geom_point(color='#f09222') + 
  xlab("IA kbps/student")+
  ylab("IA $/mbps")+
  theme_esh()

#scatterplot of monthly IA cost per mbps vs. bw per student in 2017 - with log
p + geom_point(color='#f09222') + 
  scale_x_continuous(breaks=c(0,10,250,1000,5000,50000,250000), labels=c(0,10,250,1000,5000,50000,250000), trans="log2")+
  scale_y_continuous(breaks=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), labels=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), trans="log2")+
  xlab("IA kbps/student")+
  ylab("IA $/mbps")+
  theme_esh()

#correlation - weakly negative
cor(districts$ia_monthly_cost_per_mbps_2017,districts$bandwidth_per_student_kbps_2017)

#####incorporating year
districts_exp$year=as.character(districts_exp$year)
districts_exp$esh_id=as.character(districts_exp$esh_id)

q <- ggplot(districts_exp[districts_exp$esh_id %in% c('969116','969253','929598'),], aes(x = bandwidth_per_student_kbps, y = ia_monthly_cost_per_mbps,group=esh_id))
q +  geom_point(aes(color=year), size=2) +
  scale_color_manual(values=c('#d19328' ,'#fdb913', '#fcd56a'))+
  geom_line() +
  scale_x_continuous(breaks=c(0,10,250,1000,5000,50000,250000), labels=c(0,10,250,1000,5000,50000,250000), trans="log2")+
  scale_y_continuous(breaks=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), labels=c(0.001, 0.1, 0.5,2,8,30,100,300,1000,4000), trans="log2")+
  xlab("IA kbps/student")+
  ylab("IA $/mbps")+
  theme_esh()