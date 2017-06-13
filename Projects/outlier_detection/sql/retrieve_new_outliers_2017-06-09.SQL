SELECT
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
    o.end_dt is null;
