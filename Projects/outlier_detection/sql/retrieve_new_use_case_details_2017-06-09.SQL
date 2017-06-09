select 
    ouc.outlier_use_case_id,
    temp_cand.* 
    from 
    temp_outlier_use_case_detail_candidates temp_cand,
    outlier_use_case_details oucd,
    outlier_use_cases ouc
    where
    not 
    (temp_cand.use_case_name = oucd.use_case_name and
    temp_cand.outlier_use_case_params = oucd.outlier_use_case_params and
    temp_cand.outlier_test_case_params =oucd.outlier_test_case_params
    )				
    union
    select distinct
    ouc.outlier_use_case_id,
    temp_cand.*
    from
    temp_outlier_use_case_detail_candidates temp_cand,
    outlier_use_cases ouc
    where
    (not exists 
    (select 
    1
    from 
    outlier_use_case_details oucd2
    where 
    temp_cand.use_case_name = oucd2.use_case_name)) and
    ouc.outlier_use_case_name = temp_cand.use_case_name;
