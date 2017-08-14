with erate_money as (
  select 
    bi.postal_cd,
    round(sum(frns.funding_commitment_request::numeric)/1000000,1) as erate_money_no_voice_millions
  from fy2017.frns 
  join fy2017.basic_informations bi
  on frns.application_number = bi.application_number
  where bi.applicant_type in ('School', 'School District', 'Consortium')
  and bi.postal_cd not in ('AS', 'DC', 'GU', 'MP', 'PR', 'VI')
  and frns.service_type != 'Voice'
  group by 1
  order by 1
),

a as (select *,
  case
	when dd.locale = 'Town' or dd.locale = 'Rural'
	then 'R' 
	when dd.locale = 'Urban' or dd.locale = 'Suburban'
	then 'U'
	else null
end as locale_2

from public.fy2017_districts_deluxe_matr dd
where include_in_universe_of_districts = true 
and district_type = 'Traditional'
and locale is not null),

b as (select postal_cd,
locale_2,

  sum(case
    when fiber_target_status = 'Target'
    then 1 end)::numeric 
  as fiber_target_dist,
  sum(case
    when fiber_target_status = 'Target' or fiber_target_status = 'Not Target'
    then 1 end)::numeric
  as fiber_population,

  sum(case
    when fiber_target_status = 'Target'
    then 1 end)::numeric/sum(case
    when fiber_target_status = 'Target' or fiber_target_status = 'Not Target'
    then 1 end)::numeric
  as percent_fiber_for_extrap,

  (sum(case
    when fiber_target_status = 'Target'
    then 1 end)::numeric/sum(case
    when fiber_target_status = 'Target' or fiber_target_status = 'Not Target'
    then 1 end)::numeric)*count(esh_id)::numeric
  as extrapolated_fiber_target,

  sum(case
    when meeting_2014_goal_no_oversub = false and exclude_from_ia_analysis = false
    then 1 end)::numeric
  as districts_not_meeting_100k,

  sum(case
    when meeting_2014_goal_no_oversub = false and exclude_from_ia_analysis = false
    then num_students end)::numeric
  as students_not_meeting_100k,

  (sum(case
    when meeting_2014_goal_no_oversub = false and exclude_from_ia_analysis = false
    then num_students end)::numeric/sum(case
    when exclude_from_ia_analysis = false
    then num_students end)::numeric)*sum(num_students)::numeric
  as extrapolated_students_not_meeting,

  sum(case
    when exclude_from_ia_analysis = false
    then 1 end)::numeric
  as clean_districts,

  sum(case
    when exclude_from_ia_analysis = false and exclude_from_ia_cost_analysis = false
    then 1 end)::numeric
  as clean_for_cost_districts,

  (sum(case
    when meeting_2014_goal_no_oversub = false and exclude_from_ia_analysis = false
    then 1 end)::numeric/sum(case
    when exclude_from_ia_analysis = false
    then 1 end)::numeric)*count(esh_id)::numeric
  as extrapolated_not_100k_districts,

  sum(case
    when meeting_knapsack_affordability_target = false and exclude_from_ia_analysis = false and exclude_from_ia_cost_analysis = false
    then 1 end)::numeric
  as districts_not_meeting_knapsack,

  (sum(case
    when meeting_knapsack_affordability_target = false and exclude_from_ia_analysis = false and exclude_from_ia_cost_analysis = false
    then 1 end)::numeric/sum(case
    when exclude_from_ia_analysis = false and exclude_from_ia_cost_analysis = false
    then 1 end)::numeric)*count(esh_id)::numeric
  as extrapolated_not_knapsack_districts,

  sum(c2_postdiscount_remaining_17) as total_c2_postdiscount_remaining,
  count(esh_id) as total_districts

  from a

  group by postal_cd,
  locale_2),

c as (
  select postal_cd,
  sum(case
    when locale_2 = 'R'
    then fiber_target_dist
    else null
    end)/
  sum(fiber_target_dist) as percent_fiber_targets_regular,
  sum(case
    when locale_2 = 'R'
    then extrapolated_fiber_target
    else null
    end)/
  sum(extrapolated_fiber_target) as percent_fiber_targets_extrap,
  sum(case
    when locale_2 = 'R'
    then districts_not_meeting_100k
    else null
    end)/
  sum(districts_not_meeting_100k) as percent_districts_not_meeting_100k_regular,
  sum(case
    when locale_2 = 'R'
    then extrapolated_not_100k_districts
    else null
    end)/
  sum(extrapolated_not_100k_districts) as percent_districts_not_meeting_100k_extrap,

  sum(case
    when locale_2 = 'R'
    then students_not_meeting_100k
    else null
    end)/
  sum(students_not_meeting_100k) as percent_students_not_meeting_100k_regular,
  sum(case
    when locale_2 = 'R'
    then extrapolated_students_not_meeting
    else null
    end)/
  sum(extrapolated_students_not_meeting) as percent_students_not_meeting_100k_extrap,

  sum(case
    when locale_2 = 'R'
    then districts_not_meeting_knapsack 
    else null
    end)/
  sum(districts_not_meeting_knapsack) as percent_districts_not_meeting_knapsack_regular,

  sum(case
    when locale_2 = 'R'
    then extrapolated_not_knapsack_districts
    else null
    end)/
  sum(extrapolated_not_knapsack_districts) as percent_districts_not_meeting_knapsack_extrap,

  sum(case
    when locale_2 = 'R'
    then total_c2_postdiscount_remaining
    else null
    end)/
  sum(total_c2_postdiscount_remaining) as percent_districts_c2_funding

  from b

  group by postal_cd

  order by postal_cd
)

select *
from c
join erate_money
on c.postal_cd = erate_money.postal_cd