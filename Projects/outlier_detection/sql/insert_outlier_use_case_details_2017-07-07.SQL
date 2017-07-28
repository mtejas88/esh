insert into outlier_use_case_details (outlier_use_case_id,use_case_name,outlier_use_case_params,outlier_test_case_params,create_dt)
      values(5,'Monthly Cost per Mbps','"district_size"=>"Small", "district_state"=>"GA", "district_locale"=>"Town"','"outlier_id_type"=>"esh_id", "outlier_value_type"=>"ia_monthly_cost_per_mbps", "significance_level"=>"0.05"',current_timestamp);
