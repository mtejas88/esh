## ======================================
##
## SOURCE .ENV VARIABLES -- FUNCTION
## 
## ======================================

source_env <- function(path){

  load_dot_env(path)
  
  ## DIRECTORY PATHS
  ## assign google drive path if available
  if (Sys.getenv("GOOGLE_DRIVE") != ""){
    assign("google_drive_path", Sys.getenv("GOOGLE_DRIVE"), envir=.GlobalEnv)
  }
  ## assign ficher github path if available
  if (Sys.getenv("GITHUB") != ""){
    assign("github_path", Sys.getenv("GITHUB"), envir=.GlobalEnv)
  }
  ## assign Ecto path if available
  if (Sys.getenv("ECTO") != ""){
    assign("ecto_path", Sys.getenv("ECTO"), envir=.GlobalEnv)
  }
  
  ## ONYX (CURRENT DB)
  ## assign url for DB if available
  if (Sys.getenv("URL") != ""){
    assign("url", Sys.getenv("URL"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER") != ""){
    assign("user", Sys.getenv("USER"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD") != ""){
    assign("password", Sys.getenv("PASSWORD"), envir=.GlobalEnv)
  }
  
  ## ML Mass Update
  ## assign url for DB if available
  if (Sys.getenv("URL_ML_Mass_Update") != ""){
    assign("url_ml_mass_update", Sys.getenv("URL_ML_Mass_Update"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER_ML_Mass_Update") != ""){
    assign("user_ml_mass_update", Sys.getenv("USER_ML_Mass_Update"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD_ML_Mass_Update") != ""){
    assign("password_ml_mass_update", Sys.getenv("PASSWORD_ML_Mass_Update"), envir=.GlobalEnv)
  }
  
  ## PRISTINE 2016
  ## assign url for DB if available
  if (Sys.getenv("URL_PRIS2016") != ""){
    assign("url_pris2016", Sys.getenv("URL_PRIS2016"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER_PRIS2016") != ""){
    assign("user_pris2016", Sys.getenv("USER_PRIS2016"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD_PRIS2016") != ""){
    assign("password_pris2016", Sys.getenv("PASSWORD_PRIS2016"), envir=.GlobalEnv)
  }
 
  ## PRISTINE 2017
  ## assign url for DB if available
  if (Sys.getenv("URL_PRIS2017") != ""){
    assign("url_pris2017", Sys.getenv("URL_PRIS2017"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER_PRIS2017") != ""){
    assign("user_pris2017", Sys.getenv("USER_PRIS2017"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD_PRIS2017") != ""){
    assign("password_pris2017", Sys.getenv("PASSWORD_PRIS2017"), envir=.GlobalEnv)
  }
  
  ## FROZEN 2016 -- PINK
  ## assign url for DB if available
  if (Sys.getenv("URL_PINK") != ""){
    assign("url_pink", Sys.getenv("URL_PINK"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER_PINK") != ""){
    assign("user_pink", Sys.getenv("USER_PINK"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD_PINK") != ""){
    assign("password_pink", Sys.getenv("PASSWORD_PINK"), envir=.GlobalEnv)
  }
 
  ## SHINY CREDENTIALS (RSTUDIO)
  if (Sys.getenv("RSTUDIO_NAME") != ""){
    assign("rstudio_name", Sys.getenv("RSTUDIO_NAME"), envir=.GlobalEnv)
  }
  if (Sys.getenv("RSTUDIO_TOKEN") != ""){
    assign("rstudio_token", Sys.getenv("RSTUDIO_TOKEN"), envir=.GlobalEnv)
  }
  if (Sys.getenv("RSTUDIO_SECRET") != ""){
    assign("rstudio_secret", Sys.getenv("RSTUDIO_SECRET"), envir=.GlobalEnv)
  }
}

