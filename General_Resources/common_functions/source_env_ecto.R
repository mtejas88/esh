## ======================================
##
## SOURCE .ENV VARIABLES -- FUNCTION
## 
## ======================================

source_env_ecto <- function(path){

  load_dot_env(path)
  
  ## ECTO QA
  ## assign url for DB if available
  if (Sys.getenv("URL_ECTO_QA") != ""){
    assign("url_ecto_qa", Sys.getenv("URL_ECTO_QA"), envir=.GlobalEnv)
  }
  ## assign username for DB if available
  if (Sys.getenv("USER_ECTO_QA") != ""){
    assign("user_ecto_qa", Sys.getenv("USER_ECTO_QA"), envir=.GlobalEnv)
  }
  ## assign password for DB if available
  if (Sys.getenv("PASSWORD_ECTO_QA") != ""){
    assign("password_ecto_qa", Sys.getenv("PASSWORD_ECTO_QA"), envir=.GlobalEnv)
  }
}

