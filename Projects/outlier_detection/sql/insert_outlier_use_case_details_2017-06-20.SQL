insert into outlier_use_case_details (outlier_use_case_id,use_case_name,outlier_use_case_params,outlier_test_case_params,create_dt)
      values(16,'Change in Total BW','"district_size"=>"Tiny", "district_state"=>"NY", "district_locale"=>"Rural"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"change_in_bw_tot", "significance_level"=>"0.05"',current_timestamp);
