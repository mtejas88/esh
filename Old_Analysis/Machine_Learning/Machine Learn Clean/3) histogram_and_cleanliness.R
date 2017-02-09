
setwd("C:/Users/Justine/Google Drive/ESH Main Share/Strategic Analysis Team/2016/Data Strategy/Machine Learn Clean")


orig_verif_predict_cross_all_2015 <- read.csv("orig_verif_predict_cross_all_2015.csv")

purpose <- "Internet"

for (purpose in c("Internet", "ISP", "WAN", "Upstream")){
  nam1 <- paste(purpose, 
                "_hist", 
                sep = "")
  nam2 <- paste("probability_purpose.", 
                purpose, 
                sep = "")
  assign(nam1,
         orig_verif_predict_cross_all_2015[orig_verif_predict_cross_all_2015$predicted_purpose == paste(purpose)
                                           ,nam2])
  
}

par(mfrow=c(2,2))
hist(Internet_hist, 
     main="Probability Values for Purpose - Internet",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(WAN_hist, 
     main="Probability Values for Purpose - WAN",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(ISP_hist, 
     main="Probability Values for Purpose - ISP",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(Upstream_hist, 
     main="Probability Values for Purpose - Upstream",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)

orig_verif_predict_cross_all_2015$predicted_cc <- gsub(" ",".",orig_verif_predict_cross_all_2015$predicted_cc)
orig_verif_predict_cross_all_2015$predicted_cc <- gsub("/",".",orig_verif_predict_cross_all_2015$predicted_cc)
connect_category <- "Cable...DSL"
names(orig_verif_predict_cross_all_2015) <- gsub(" ",".",names(orig_verif_predict_cross_all_2015))
names(orig_verif_predict_cross_all_2015) <- gsub("/",".",names(orig_verif_predict_cross_all_2015))


for (connect_category in c("Cable...DSL", "Copper", "Fiber", "Fixed.Wireless", "ISP.only")){
  nam1 <- paste(connect_category, 
                "_hist", 
                sep = "")
  nam2 <- paste("probability_cc.", 
                connect_category, 
                sep = "")
  assign(nam1,
         orig_verif_predict_cross_all_2015[orig_verif_predict_cross_all_2015$predicted_cc == paste(connect_category)
                                           ,nam2])
  
}

par(mfrow=c(3,2))
hist(Cable...DSL_hist, 
     main="Probability Values for Connect Cat - Cable/DSL",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(Fiber_hist, 
     main="Probability Values for Connect Cat - Fiber",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(Copper_hist, 
     main="Probability Values for Connect Cat - Copper",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(Fixed.Wireless_hist, 
     main="Probability Values for Connect Cat - Fixed Wireless",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
hist(ISP.only_hist, 
     main="Probability Values for Connect Cat - ISP only",
     xlab="Probability Values", 
     border="blue", 
     col="green",
     xlim=c(0,1),
     las=1, 
     breaks=20)
