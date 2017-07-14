
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
    
    master_output_uc=unique(master_output[,c("outlier_use_case_name","outlier_use_case_parameters","outlier_test_parameters")])
    script_values <- paste("('",(master_output_uc$outlier_use_case_name),"','",master_output_uc$outlier_use_case_parameters,"','",master_output_uc$outlier_test_parameters,"'),",sep="",collapse="\n")
    
    script <- paste0(script,substr(script_values,1,nchar(script_values)-1),";")
    
    print("Script Created")
   # print(script)
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
      "select distinct
      ouc.outlier_use_case_id,
      temp_cand.*
      from
      temp_outlier_use_case_detail_candidates temp_cand
      inner join outlier_use_cases ouc
      on temp_cand.use_case_name = ouc.outlier_use_case_name 
      where
      not exists
      (select
      1
      from
      outlier_use_case_details oucd
      inner join outlier_use_cases ouc
      on oucd.use_case_name = ouc.outlier_use_case_name 
      where
      temp_cand.use_case_name = oucd.use_case_name and
      temp_cand.outlier_use_case_params = oucd.outlier_use_case_params and
      temp_cand.outlier_test_case_params =oucd.outlier_test_case_params
      );
      "  
  }else if(table_name =='outliers'){       
    
    script <- 
      "SELECT
    o.outlier_id,
    cand.outlier_use_case_detail_id,
    CASE
    WHEN NOT EXISTS 
    (select 
    1
    from 
    outliers o2
    where 
    cand.outlier_use_case_detail_id = o2.outlier_use_case_detail_id and
    cand.ref_id = o2.ref_id)  
    THEN 'insert'
    WHEN  (cand.outlier_use_case_detail_id = o.outlier_use_case_detail_id and
    cand.ref_id = o.ref_id) 
    and
    (cand.value != o.value or
    cand.lambda != o.lambda)
    THEN 'update'
    WHEN cand.outlier_use_case_detail_id = o.outlier_use_case_detail_id and
    cand.ref_id = o.ref_id and 
    cand.value = o.value and
    cand.lambda = o.lambda 
    THEN 'ignore'
    ELSE
    'unknown'
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
    on (cand.outlier_use_case_detail_id = o.outlier_use_case_detail_id and
    cand.ref_id = o.ref_id)
    where
    o.end_dt is null;"  
    
  } 
  
  return(script)  
}

update_no_longer_outliers <- function(reason){
if (reason == 'no longer found') {
    script <- 
    "with outlier_a as (select ref_id, case when use_case_name ='Cost per Circuit' then 'LineItem' else 'District' end as type
    from outliers out join outlier_use_case_details oucd on out.outlier_use_case_detail_id=oucd.outlier_use_case_detail_id),
    
    outlier_b as (select ref_id, case when use_case_name ='Cost per Circuit' then 'LineItem' else 'District' end as type
    from temp_outlier_candidates)

    update outliers set end_dt = current_timestamp 
    where ref_id in(
    select outlier_a.ref_id from outlier_a
    left join
    outlier_b on outlier_a.ref_id=outlier_b.ref_id and outlier_a.type=outlier_b.type
    where outlier_b.ref_id is null
    );
    "
  }else if (reason=='matches 2016'){
  script <-
    "WITH dd_2015 AS 
  (SELECT esh_id, total_ia_bw_mbps,
  CASE WHEN (monthly_ia_cost_per_mbps = 'Insufficient data' OR monthly_ia_cost_per_mbps = 'Infinity') THEN NULL ELSE monthly_ia_cost_per_mbps END AS monthly_ia_cost_per_mbps, exclude_from_analysis
  FROM public.fy2015_districts_deluxe_m),
  dd_2016 AS (SELECT * FROM public.fy2016_districts_deluxe_matr),
  
  dd_2016_final as(
  SELECT dd_2016.*,
  CASE WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
  THEN (dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps) END AS change_in_bw_tot,
  
  CASE WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
  AND (dd_2015.total_ia_bw_mbps=0) AND (dd_2016.ia_bw_mbps_total > 0) THEN 1
  WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE 
  AND (dd_2015.total_ia_bw_mbps=0) AND (dd_2016.ia_bw_mbps_total = 0) THEN 0
  WHEN dd_2015.exclude_from_analysis = FALSE AND dd_2016.exclude_from_ia_analysis = FALSE
  THEN (dd_2016.ia_bw_mbps_total - dd_2015.total_ia_bw_mbps)/dd_2015.total_ia_bw_mbps END AS change_in_bw_pct,
  
  CASE WHEN dd_2015.exclude_from_analysis = FALSE AND
  dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
  AND (dd_2015.monthly_ia_cost_per_mbps IS NOT null) THEN
  (dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float) 
  END AS change_in_cost_tot,
  
  CASE WHEN dd_2015.exclude_from_analysis = FALSE AND
  dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
  AND (dd_2015.monthly_ia_cost_per_mbps::float=0) AND (dd_2016.ia_monthly_cost_per_mbps > 0) THEN 1
  WHEN dd_2015.exclude_from_analysis = FALSE AND
  dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
  AND (dd_2015.monthly_ia_cost_per_mbps::float=0) AND (dd_2016.ia_monthly_cost_per_mbps = 0) THEN 0
  WHEN dd_2015.exclude_from_analysis = FALSE AND
  dd_2016.exclude_from_ia_analysis = FALSE AND dd_2016.exclude_from_ia_cost_analysis = FALSE 
  AND (dd_2015.monthly_ia_cost_per_mbps IS NOT null) THEN
  (dd_2016.ia_monthly_cost_per_mbps - dd_2015.monthly_ia_cost_per_mbps::float)/dd_2015.monthly_ia_cost_per_mbps::FLOAT 
  END AS change_in_cost_pct
  
  FROM dd_2016 LEFT JOIN dd_2015 ON dd_2016.esh_id::integer=dd_2015.esh_id::integer),
  
  sr_2016 as(SELECT *
  FROM public.fy2016_services_received_matr),
  
  final as(
  SELECT a.ref_id, value, ucd.use_case_name,
  CASE WHEN ucd.use_case_name = 'BW per Student' THEN ia_bandwidth_per_student_kbps
  WHEN ucd.use_case_name = 'Monthly Cost per Mbps' THEN ia_monthly_cost_per_mbps
  WHEN ucd.use_case_name = 'Change in Total BW' THEN change_in_bw_tot
  WHEN ucd.use_case_name = '% Change in BW' THEN change_in_bw_pct
  WHEN ucd.use_case_name = 'Change in Total Monthly Cost' THEN change_in_cost_tot
  WHEN ucd.use_case_name = '% Change in Monthly Cost' THEN change_in_cost_pct
  END AS value_2016,
  ARRAY_AGG(label) AS tags
  FROM public.outliers a 
  JOIN outlier_use_case_details ucd ON a.outlier_use_case_detail_id=ucd.outlier_use_case_detail_id
  JOIN dd_2016_final dd ON a.ref_id::NUMERIC=dd.esh_id::NUMERIC
  LEFT JOIN (SELECT * FROM public.tags WHERE funding_year = 2016 AND taggable_type='District') t 
  ON a.ref_id::NUMERIC = t.taggable_id::NUMERIC 
  WHERE ucd.use_case_name != 'Cost per Circuit'
  GROUP BY 1,2,3,4
  UNION
  SELECT a.ref_id, value, ucd.use_case_name,
  sr.line_item_recurring_elig_cost::NUMERIC / sr.line_item_total_num_lines::NUMERIC AS value_2016,
  NULL AS tags
  FROM public.outliers a 
  JOIN outlier_use_case_details ucd ON a.outlier_use_case_detail_id=ucd.outlier_use_case_detail_id
  LEFT JOIN public.cross_year_line_item_matches cm
  ON a.ref_id::NUMERIC=cm.new_id::NUMERIC
  LEFT JOIN sr_2016 sr ON cm.old_id::NUMERIC=sr.line_item_id::NUMERIC
  WHERE ucd.use_case_name = 'Cost per Circuit'),
  
  UPDATE public.outliers a
  SET end_dt = CURRENT_TIMESTAMP 
  FROM final f
  WHERE a.ref_id = f.ref_id
  AND a.value=f.value
  AND f.value = f.value_2016;"
  }else if (reason=='cost exclude'){
    script <- 
    "with sr_2016 as(SELECT *
    FROM public.fy2016_services_received_matr),

    change_cost_exclude AS(
    SELECT ref_id, a.outlier_use_case_detail_id, ucd.use_case_name
    FROM public.outliers a
    JOIN outlier_use_case_details ucd ON a.outlier_use_case_detail_id=ucd.outlier_use_case_detail_id 
    JOIN sr_2016 sr ON a.ref_id::NUMERIC=sr.recipient_id::NUMERIC
    WHERE 
    'exclude_for_cost_only_unknown' = ANY(open_tags) 
    AND ucd.use_case_name ILIKE '%Change%'
    AND ucd.use_case_name ILIKE '%Cost%')

    UPDATE public.outliers a
    SET end_dt = CURRENT_TIMESTAMP 
    FROM change_cost_exclude c
    WHERE a.ref_id = c.ref_id
    AND a.outlier_use_case_detail_id=c.outlier_use_case_detail_id;
    "
  }
    return(script)  
}

dml_builder <- function(values,script_type,postgres_table){
  
  #print(values)
  syntax_stitcher <- function(script_content,script_begin,script_end){
    ##declare script variable 
    script <- c()  
    
    if (nrow(script_content)<=1){
      script <- paste0(script_begin,script_content[1,],script_end)
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
    #print(script)
    return(script) 
  }
  
  syntax_stitcher_tableau <- function(script_begin,script_content){
    final_script_df=rbind(script_begin,script_content)
    end=data.frame("content"=sub('),', ');', final_script_df[nrow(final_script_df),]) )
    final_script_df=rbind(as.data.frame(final_script_df[(1:nrow(final_script_df) - 1),,drop=FALSE]),end)
    final_script_df[, 1] <- as.character(final_script_df[, 1])
    final_script=as.character(unlist(final_script_df, use.names=FALSE))
    final_script=noquote(final_script)
    final_script=paste(final_script,collapse=" ") 
    return(final_script)
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
      
    }else if(postgres_table == 'tableau_district'){                                                                                                                  
                                                                                                                                                             
      ## Script Beginning                                                                                                                                    
      script_begin <- data.frame("content"="insert into outlier_district_report_data (ref_id,value,outlier_use_case_name, outlier_flag,locale, district_size,state,id,create_dt) values ")
                                                                                                                                                             
      ## Script Content                                                                                     
      script_content <- data.frame("content"=paste0("('",values$outlier_unique_id,"',",                                                                   
                                                    values$outlier_value,",'",                                                                              
                                                    values$outlier_use_case_name,"',",                                                                       
                                                    values$outlier_flag,",'",                                                                                 
                                                    values$locale,"','",                                                                                        
                                                    values$district_size,"','",
                                                    values$state,"',",
                                                    values$id,",",
                                                    "current_timestamp),"))                                                                                     
    }else if(postgres_table == 'tableau_line_item'){                                                                                                          
      ## Script Beginning                                                                                                                                    
      script_begin <- data.frame("content"="insert into outlier_line_item_report_data (ref_id,value,outlier_use_case_name, outlier_flag,bandwidth_in_mbps,connect_category,purpose,id,create_dt) values ")
                                                                                                                                                    
      ## Script Content                                                                                     
      script_content <- data.frame("content"=paste0("('",values$outlier_unique_id,"',",                                                                   
                                                    values$outlier_value,",'",                                                                              
                                                    values$outlier_use_case_name,"',",                                                                       
                                                    values$outlier_flag,",'",                                                                                 
                                                    values$bandwidth_in_mbps,"','",                                                                                        
                                                    values$connect_category,"','",
                                                    values$purpose,"',",
                                                    values$id,",",
                                                    "current_timestamp),"))
    }  
    
    if (postgres_table == 'outlier_use_cases' | postgres_table=='outlier_use_case_details' | postgres_table=='outliers'){
    final_script <- syntax_stitcher(script_content,script_begin,script_end)}
    else if(postgres_table == 'tableau_line_item'){
      final_script=syntax_stitcher_tableau(script_begin,script_content)
    }else{ #districts table is too big to handle all inserts at once so split up
      n <- 1000
      x <- seq_along(script_content[,1])
      d1 <- split(script_content, ceiling(x/n))
      final_script_list <- list()
      for(i in 1:length(d1)){
        final_script_list[[i]]=syntax_stitcher_tableau(script_begin,d1[[i]])
        }
    }
  }else if(script_type == 'update'){
    if(postgres_table == 'outliers'){ 
      
      ## Script Beginning            
      script_begin <- paste0("update outliers set end_dt = ","current_timestamp where outlier_id in (")
      
      
      ## Script Ending            
      script_end <- ");"
      print("Length of values is")
      print(length(values)) 
      script=script_begin
      ## Script Content    
      for(i in 1:length(values)){
        print(unique(values[i]))
        if (i==length(values)) {
          script <- paste0(script,values[i],script_end)
        } else {
          script <- paste0(script,values[i],",")
        }
        
      }
      
      
      
    }else if(postgres_table == 'tableau_district'){
      ## Script                                                                                                                                     
      script <-paste0("delete from outlier_district_report_data where create_dt < current_timestamp;")  
    }else if(postgres_table == 'tableau_line_item'){
      ## Script                                                                                                                                     
      script <-paste0("delete from outlier_line_item_report_data where create_dt < current_timestamp;")
    }
    final_script <- script
  }   
  if(script_type == 'insert' & postgres_table == 'tableau_district'){
    return(final_script_list)
  }else{
    return(final_script)
  }
  
}
