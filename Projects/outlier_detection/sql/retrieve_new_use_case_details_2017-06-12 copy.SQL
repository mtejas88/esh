select distinct
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
      where
      temp_cand.use_case_name = oucd.use_case_name and
      temp_cand.outlier_use_case_params = oucd.outlier_use_case_params and
      temp_cand.outlier_test_case_params =oucd.outlier_test_case_params
      );
