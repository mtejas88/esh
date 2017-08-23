## Clearing memory
rm(list=ls())

## load packages (if not already in the environment)
packages.to.install <- c("DBI", "rJava", "RJDBC", "dotenv","dplyr","ggplot2","reshape2")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}
library(DBI)
library(rJava)
library(RJDBC)
library(dotenv)
library(dplyr)
library(ggplot2)
library(reshape2)
options(java.parameters = "-Xmx4g" )


source_env_Frozen <- function(path){
  load_dot_env(path)
  ## assign url for DB if available
  if (Sys.getenv("F_URL") != ""){
    assign("f_url", Sys.getenv("F_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("F_USER") != ""){
    assign("f_user", Sys.getenv("F_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("F_PASSWORD") != ""){
    assign("f_password", Sys.getenv("F_PASSWORD"), envir=.GlobalEnv)
  }
}
source_env_Frozen("~/.env")

## QUERY THE DB

## load PostgreSQL Driver
pgsql <- JDBC("org.postgresql.Driver", "../../../../General_Resources/postgres_driver/postgresql-9.4.1212.jre7.jar", "`")

## connect to the database
con <- dbConnect(pgsql, url=f_url, user=f_user, password=f_password)

## query function
querydb <- function(query_name){
  query <- readChar(query_name, file.info(query_name)$size)
  data <- dbGetQuery(con, query)
  return(data)
}

dta <- querydb("queries/bw_per_student_all.sql")
dbDisconnect(con)

#making format compatible
logical <- c("meeting_2014_goal_no_oversub")
dta[, logical] <- sapply(dta[, logical], function(x) ifelse(x == "t", 'true', ifelse(x =="f", 'false', x)))

meeting = dta %>% filter(meeting_2014_goal_no_oversub=="true") %>% select(-meeting_2014_goal_no_oversub)

#get bw per student distribution along steps of 2%
meeting_dist=as.data.frame(
  sapply(split(
    meeting$ia_bandwidth_per_student_kbps, meeting$year), 
    function(x) quantile(x, probs=seq(0,.98,.02))
    )
)

data=melt(as.matrix(meeting_dist))
names(data)=c("percentile","year","ia_bandwidth_per_student_kbps")
data$percentile=gsub("%","",data$percentile)
data$percentile=as.numeric(data$percentile)

#first plot
d2015=data %>% filter(year=="2015")
d2016=data %>% filter(year=="2016")
d2017=data %>% filter(year=="2017")

p=ggplot(NULL,aes(x=percentile,y=ia_bandwidth_per_student_kbps)) + 
geom_bar(aes(fill = "2015"),data=d2015,stat = "identity", alpha=.5) +
geom_bar(aes(fill = "2016"),data=d2016,stat = "identity", alpha=.3) +
geom_bar(aes(fill = "2017"),data=d2017,stat = "identity", alpha=.15) + 
xlab("Percentile") + ylab("Bandwidth per Student (kbps)") +
ggtitle("Bandwidth per Student (kbps) Distribution") +
scale_fill_manual("Year",values =c("#d19328", "#fdb913","#fcd56a")) +
scale_y_continuous(breaks=c(100,500, 1000,2000,4000,6000))+
theme_bw()

p

