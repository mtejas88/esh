delete from outliers 
    where ref_id not in(
    select out.ref_id
    from outliers out
    join temp_outlier_candidates temp_cand
    on out.ref_id = temp_cand.ref_id and
    out.use_case_name = temp_cand.use_case_name and
    out.outlier_use_case_params = temp_cand.outlier_use_case_params and
    out.outlier_test_case_params = temp_cand.outlier_test_case_params and
    out.value = temp_cand.value and
    out.R = temp_cand.R and
    out.lambda = temp_cand.lambda
    );
    
