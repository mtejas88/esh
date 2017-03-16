## ======================================
##
## SOURCE .ENV VARIABLES -- FUNCTION
## 
## ======================================

source_env <- function(path){

  load_dot_env(path)
  url <- Sys.getenv("URL")
  user <- Sys.getenv("USER")
  password <- Sys.getenv("PASSWORD")
  google_drive_path <- Sys.getenv("GOOGLE_DRIVE")
  github_path <- Sys.getenv("GITHUB")
  
  assign("url", url, envir = .GlobalEnv)
  assign("user", user, envir = .GlobalEnv)
  assign("password", password, envir = .GlobalEnv)
  assign("google_drive_path", google_drive_path, envir = .GlobalEnv)
  assign("github_path", github_path, envir = .GlobalEnv)
}

