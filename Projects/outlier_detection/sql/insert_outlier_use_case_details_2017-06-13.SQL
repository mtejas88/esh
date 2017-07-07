insert into outlier_use_case_details (outlier_use_case_id,use_case_name,outlier_use_case_params,outlier_test_case_params,create_dt)
      values(20,'BW per Student','"district_size"=>"Medium", "district_locale"=>"Town"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"ia_bandwidth_per_student_kbps", "significance_level"=>"0.05"',current_timestamp),
(16,'Change in Total BW','"district_size"=>"Medium", "district_locale"=>"Town"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"change_in_bw_tot", "significance_level"=>"0.05"',current_timestamp);
