## ============================================================
##
## SOURCE .ENV VARIABLES for ROSE Staging DB credentials
## Assumes you have assigned them in your .env as notated below
## 
## ============================================================

source_env_Staging <- function(path){
  
  load_dot_env(path)
  
  ## assign url for DB if available
  if (Sys.getenv("S_URL") != ""){
    assign("s_url", Sys.getenv("S_URL"), envir=.GlobalEnv)
  }
  
  ## assign username for DB if available
  if (Sys.getenv("S_USER") != ""){
    assign("s_user", Sys.getenv("S_USER"), envir=.GlobalEnv)
  }
  
  ## assign password for DB if available
  if (Sys.getenv("S_PASSWORD") != ""){
    assign("s_password", Sys.getenv("S_PASSWORD"), envir=.GlobalEnv)
  }
}

