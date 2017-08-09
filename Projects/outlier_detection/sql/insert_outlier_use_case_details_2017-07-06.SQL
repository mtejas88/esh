insert into outlier_use_case_details (outlier_use_case_id,use_case_name,outlier_use_case_params,outlier_test_case_params,create_dt)
      values(7,'BW per Student','"district_size"=>"Medium", "district_state"=>"MS", "district_locale"=>"Rural"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"ia_bandwidth_per_student_kbps", "significance_level"=>"0.05"',current_timestamp),
(6,'% Change in BW','"district_size"=>"Small", "district_state"=>"IN", "district_locale"=>"Rural"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"change_in_bw_pct", "significance_level"=>"0.05"',current_timestamp);
