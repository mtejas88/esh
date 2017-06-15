delete from outliers 
    where ref_id not in(
    select distinct out.ref_id
    from outliers out
    join outlier_use_case_details oucd 
    on out.outlier_use_case_detail_id = oucd.outlier_use_case_detail_id
    join temp_outlier_candidates temp_cand
    on out.ref_id = temp_cand.ref_id and
    out.value = temp_cand.value and
    out.R = temp_cand.R and
    out.lambda = temp_cand.lambda and 
    oucd.use_case_name = temp_cand.use_case_name and
    oucd.outlier_use_case_params = temp_cand.outlier_use_case_params and
    oucd.outlier_test_case_params = temp_cand.outlier_test_case_params 
    );
    
