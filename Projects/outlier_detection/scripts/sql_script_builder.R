
load_candidate_details <- function(master_output,table_name){

script <-c()

if(table_name == "outlier_use_case_details"){

  script <- 
  "create temp table temp_outlier_use_case_detail_candidates 
    (
      use_case_name varchar(40),
      outlier_use_case_params hstore,
      outlier_test_case_params hstore);
  insert into temp_outlier_use_case_detail_candidates values "
  script_values <- paste("('",master_output$outlier_use_case_name,"','",master_output$outlier_use_case_parameters,"','",master_output$outlier_test_parameters,"'),",sep="",collapse="\n")
  script <- paste0(script,substr(script_values,1,nchar(script_values)-1),";")

  
}else if(table_name == "outliers"){
    
  script <- 
  "create temp table temp_outlier_candidates 
  (
  use_case_name varchar(40),
  outlier_use_case_params hstore,
  outlier_test_case_params hstore,
  ref_id varchar(50) NOT NULL,
  value varchar(255) NOT NULL,
  R  decimal NOT NULL,
  lambda decimal NOT NULL);

  insert into temp_outlier_candidates values "
  script_values <- paste("('",master_output$outlier_use_case_name,"','",
                         master_output$outlier_use_case_parameters,"','",
                         master_output$outlier_test_parameters,"','",
                         master_output$outlier_unique_id,"','",
                         master_output$outlier_value,"',",
                         master_output$R,",",
                         master_output$lam,"),",sep="",collapse="\n")
 
  script <- paste0(script,substr(script_values,1,nchar(script_values)-1),";")

}
return(script)
}  

find_new_cases <- function(table_name){
if(table_name =='outlier_use_case_details'){      
  script <- 
  "select 
  	ouc.outlier_use_case_id,
    temp_cand.* 
  from 
  	temp_outlier_use_case_detail_candidates temp_cand,
  	outlier_use_case_details oucd,
    outlier_use_cases ouc
  where
  	not (temp_cand.use_case_name = oucd.use_case_name and
  	temp_cand.outlier_use_case_params = oucd.outlier_use_case_params and
  	temp_cand.outlier_test_case_params =oucd.outlier_test_case_params) and
    ouc.outlier_use_case_name = temp_cand.use_case_name;"  
    
  }else if(table_name =='outliers'){      
    script <- 
    "SELECT
      o.outlier_id,
      cand.outlier_use_case_detail_id,
      CASE
        WHEN cand.outlier_use_case_detail_id not in (select outlier_use_case_detail_id from outliers)
          THEN 'insert'
        WHEN cand.outlier_use_case_detail_id = o.outlier_use_case_detail_id and
          cand.ref_id = o.ref_id and 
          cand.value = o.value and
          cand.lambda = o.lambda 
        THEN 'ignore'
      ELSE
        'update'
      END AS outlier_action,
      cand.ref_id,
      cand.value,
      cand.r,
      cand.lambda
    from 
      (select
      *
      from
      temp_outlier_candidates toc,
      outlier_use_case_details oucd
      where
      toc.use_case_name = oucd.use_case_name and
      toc.outlier_use_case_params = oucd.outlier_use_case_params and
      toc.outlier_test_case_params =oucd.outlier_test_case_params) cand
    left join
      outliers o
        on cand.outlier_use_case_detail_id = o.outlier_use_case_detail_id
    where
      o.end_dt is null;"  
    
  } 
  
}










dml_builder <- function(values,script_type,postgres_table){


  syntax_stitcher <- function(script_content,script_begin,script_end){
    ##declare script variable 
    script <- c()  

    if (nrow(script_content)<=1){
      script <- paste0(script_begin,script_content[i,],script_end)
    }else{
      for(i in 1:nrow(script_content)){
          if (i==1){
            script <- paste0(script_begin,script_content[i,],",\n")
          }else if (i==nrow(script_content)) {
            script <- paste0(script,script_content[i,],script_end)
          } else {
            script <- paste0(script,script_content[i,],",\n")
          }
     
      }
    }  
    print(script)
    return(script) 
  }

  
  
    
  if(script_type == 'insert'){
    
    ## New Use Cases      
    if(postgres_table == 'outlier_use_cases'){  
  
        
      ## Script Beginning            
      script_begin <- "insert into outlier_use_cases (outlier_use_case_name,outlier_use_case_cd,create_dt)
      values "
        
      ## Script Ending            
      script_end <- ";"
  
      ## Script Content    
      updated_values <- unique(master_output[which(master_output$outlier_use_case_cd %in% values$outlier_use_case_cd),c("outlier_use_case_name","outlier_use_case_cd")])
  
      script_content <- data.frame("content"=paste0("('",updated_values$outlier_use_case_name,"','",updated_values$outlier_use_case_cd,"',current_timestamp)"))
    
    }else if(postgres_table == 'outlier_use_case_details'){
      ## Script Beginning            
      script_begin <- "insert into outlier_use_case_details (outlier_use_case_id,use_case_name,outlier_use_case_params,outlier_test_case_params,create_dt)
      values"
      
      ## Script Ending            
      script_end <- ";"
      
      ## Script Content    
      script_content <- data.frame("content"=paste0("(",values$outlier_use_case_id,",'",values$use_case_name,"','",values$outlier_use_case_params,"','",values$outlier_test_case_params,"',current_timestamp)"))
      
      
    }else if(postgres_table == 'outliers'){ 
      
      ## Script Beginning            
      script_begin <- "insert into outliers (outlier_use_case_detail_id,ref_id,value,r,lambda,create_dt)
      values "
      
      ## Script Ending            
      script_end <- ";"
      
      ## Script Content    
      updated_values <- values[which(values$outlier_action !="ignore"),]
      
      script_content <- data.frame("content"=paste0("(",updated_values$outlier_use_case_detail_id,",'",
                                                    updated_values$ref_id,"','",
                                                    updated_values$value,"',",
                                                    updated_values$r,",",
                                                    updated_values$lambda,",",
                                                    "current_timestamp)"))
      
      
    }
    
        
  }else if(script_type == 'update'){
    if(postgres_table == 'outliers'){ 
    
      ## Script Beginning            
      script_begin <- paste0("update outliers set end_dt = ","current_timestamp where outlier_id in (")

      
      ## Script Ending            
      script_end <- ");"
      
      ## Script Content    
      for(i in 1:nrow(values)){
        if (i==1){
          script <- paste0(script_begin,values[i,],",")
        }else if (i==nrow(script_content)) {
          script <- paste0(script,values[i,],",")
        } else {
          script <- paste0(script,script_content[i,],script_end)
        }
        
      }
  
      
      }
    return(script)
    }   
  final_script <- syntax_stitcher(script_content,script_begin,script_end)
  
  return(final_script)
  
}
  