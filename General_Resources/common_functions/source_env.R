## ======================================
##
## SOURCE .ENV VARIABLES -- FUNCTION
## 
## ======================================

source_env <- function(path){

  load_dot_env(path)
  
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
  
  ## Frozen 2016
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
 
}

