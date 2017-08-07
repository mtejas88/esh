packages.to.install <- c("dotenv")
for (i in 1:length(packages.to.install)){
  if (!packages.to.install[i] %in% rownames(installed.packages())){
    install.packages(packages.to.install[i])
  }
}

library(dotenv)

## source environment variables
source_env("~/.env")

source("query_data_app.R")


options(repos=c(CRAN="https://cran.rstudio.com"))
rsconnect::setAccountInfo(name=rstudio_name,
                          token=rstudio_token,
                          secret=rstudio_secret)
rsconnect::deployApp(appName = "Cost_per_Mbps_vs_BW_per_Student","app/")