## ======================================
##
## SOURCE .ENV VARIABLES -- FUNCTION
## 
## ======================================

source_env <- function(path){

  load_dot_env(path)
  
  ## ONYX
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
  
  ## Pristine 2016
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
 
}

