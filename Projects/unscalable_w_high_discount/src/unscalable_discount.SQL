select 
  esh_id,
  district_size,
  locale,
  postal_cd,
  num_students,
  num_schools,
  num_campuses,
  meeting_knapsack_affordability_target,
  meeting_2014_goal_no_oversub,
  current_assumed_unscalable_campuses + current_known_unscalable_campuses as num_unscalable_campuses,
  num_schools * ((current_assumed_unscalable_campuses+current_known_unscalable_campuses)/num_campuses::numeric) as unscalable_schools,
  num_students * ((current_assumed_unscalable_campuses+current_known_unscalable_campuses)/num_campuses::numeric) as unscalable_students,
  
  case  when discount_rate_c1::numeric is not null then discount_rate_c1::numeric
              when locale in ('Urban', 'Suburban') then
                case  when frl_percent < .01 then .20
                      when frl_percent < .20 then .40
                      when frl_percent < .35 then .50
                      when frl_percent < .50 then .60
                      when frl_percent < .75 then .80
                      when frl_percent >= .75 then .90
                      else .70
                end
              else case when frl_percent < .01 then .25
                        when frl_percent < .20 then .50
                        when frl_percent < .35 then .60
                        when frl_percent < .50 then .70
                        when frl_percent < .75 then .80
                        when frl_percent >= .75 then .90
                        else .70
              end
  end as discount_rate_c1_matrix
  
from 
  public.fy2016_districts_deluxe_matr

where 
  include_in_universe_of_districts = true
  and district_type = 'Traditional'