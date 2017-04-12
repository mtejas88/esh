## =========================================
##
## MUNGE DATA: Subset and Clean data
##
## =========================================

## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("lattice")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

require(lattice)

##**************************************************************************************************************************************************
## READ IN DATA

li.2016 <- read.csv("data/raw/line_items_2016.csv", as.is=T, header=T, stringsAsFactors=F)
li.2015 <- read.csv("data/raw/line_items_2015.csv", as.is=T, header=T, stringsAsFactors=F)

##**************************************************************************************************************************************************

## aggregate voice and internet costs for both 2015 and 2016
type.cost.2016 <- aggregate(li.2016$total_cost, by=list(li.2016$service_type), FUN=sum, na.rm=T)
names(type.cost.2016) <- c('service_type', 'total_cost_2016')
type.cost.2015 <- aggregate(li.2015$total_cost, by=list(li.2015$service_type), FUN=sum, na.rm=T)
names(type.cost.2015) <- c('service_type', 'total_cost_2015')

voice.cost.2015 <- type.cost.2015$total_cost_2015[type.cost.2015$service_type == 'Voice Service']
voice.cost.2016 <- type.cost.2016$total_cost_2016[type.cost.2016$service_type == 'Voice']
ia.cost.2015 <- sum(type.cost.2015$total_cost_2015[type.cost.2015$service_type == 'IA Only (no circuit)'],
                    type.cost.2015$total_cost_2015[type.cost.2015$service_type == 'Data Distribution'],
                    type.cost.2015$total_cost_2015[type.cost.2015$service_type == 'Digital Transmission Service']
                    #, type.cost.2015$total_cost_2015[type.cost.2015$service_type == 'Digital Transmission Service']
)
ia.cost.2016 <- type.cost.2016$total_cost_2016[type.cost.2016$service_type == 'Data Transmission and/or Internet Access']

## -175M
ia.cost.2016 - ia.cost.2015
## -40M
voice.cost.2016 - voice.cost.2015

## plot cost
dta.plot <- as.data.frame(matrix(NA, nrow=4, ncol=3))
names(dta.plot) <- c('cost', 'category', 'class')
dta.plot$cost <- c(ia.cost.2015, ia.cost.2016, voice.cost.2015, voice.cost.2016)
dta.plot$category <- c('ia', 'ia', 'voice', 'voice')
dta.plot$class <- c(2015, 2016, 2015, 2016)
dta.plot$class <- factor(dta.plot$class, levels = c(2015, 2016))
dta.plot$cost <- dta.plot$cost / 1000000000
## create plot
pdf("figures/voice_vs_ia_cost.pdf", height=4, width=5.5)
barchart(dta.plot$cost ~ dta.plot$category, groups=dta.plot$class, auto.key=TRUE,
         ylab='Total Cost \n(in billions)', ylim=c(0,3.1), main='Breakdown by Service Type')
dev.off()
