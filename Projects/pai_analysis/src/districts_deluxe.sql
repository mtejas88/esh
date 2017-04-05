select esh_id,
name,
locale,
district_size,
num_schools,
num_campuses,
num_students,
frl_percent,
discount_rate_c1,
discount_rate_c2,
postal_cd,
county,
exclude_from_ia_analysis,
exclude_from_ia_cost_analysis,
exclude_from_wan_analysis,
exclude_from_wan_cost_analysis,
exclude_from_current_fiber_analysis,
fiber_metric_status,
include_in_universe_of_districts,
ia_bandwidth_per_student_kbps,
ia_monthly_cost_per_mbps,
ia_bw_mbps_total,
ia_monthly_cost_total,
wan_monthly_cost_total,
meeting_knapsack_affordability_target,
current_known_scalable_campuses,
current_assumed_scalable_campuses,
current_known_unscalable_campuses,
current_assumed_unscalable_campuses,
num_teachers,
latitude,
longitude,
case  when discount_rate_c1 is not null then discount_rate_c1
      when locale in ('Urban', 'Suburban') then
        case  when frl_percent < .01 then .2
              when frl_percent < .20 then .4
              when frl_percent < .35 then .5
              when frl_percent < .50 then .6
              when frl_percent < .75 then .8
              when frl_percent >= .75 then .9
              else .7
        end
      else case when frl_percent < .01 then .25
                when frl_percent < .20 then .50
                when frl_percent < .35 then .60
                when frl_percent < .50 then .70
                when frl_percent < .75 then .80
                when frl_percent >= .75 then .9
                else .7
      end
end as adj_c1_discount_rate


from public.fy2016_districts_deluxe_matr 
where include_in_universe_of_districts = True
and district_type = 'Traditional'