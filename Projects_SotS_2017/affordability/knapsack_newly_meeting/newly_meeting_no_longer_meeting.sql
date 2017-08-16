select 
--dd.postal_cd,
--dd.locale,
dd.district_size,
sum(case
  when dd.meeting_knapsack_affordability_target = true and d.meeting_knapsack_affordability_target = false
  then 1
  else 0 end)
as new_knapsack,
sum(case
  when dd.meeting_knapsack_affordability_target = true and d.meeting_knapsack_affordability_target = false
  then 1
  else 0
  end)/count(dd.esh_id)::numeric
as percent_knapsack_of_population,
sum(case
  when dd.meeting_knapsack_affordability_target = true and d.meeting_knapsack_affordability_target = false
  then 1
  else 0 end)::numeric/
sum(case
  when d.meeting_knapsack_affordability_target = false
  then 1
  else 0 end)::numeric
as percent_knapsack_of_not_meeting_2016,
sum(case
  when dd.meeting_knapsack_affordability_target = false and d.meeting_knapsack_affordability_target = true
  then 1
  else 0
  end)
as no_longer_meeting_knapsack,
sum(case
  when d.meeting_knapsack_affordability_target = true 
  then 1
  end)
as meeting_knapsack_2016,
sum(case
  when dd.meeting_knapsack_affordability_target = true 
  then 1
  end)
as meeting_knapsack_2017,
count(dd.esh_id) as sample

from public.fy2017_districts_deluxe_matr dd
inner join public.fy2016_districts_deluxe_matr d
on d.esh_id = dd.esh_id

where 
-- 2017
dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.exclude_from_ia_analysis = false 
and dd.exclude_from_ia_cost_analysis = false

-- 2016
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'
and d.exclude_from_ia_analysis = false 
and d.exclude_from_ia_cost_analysis = false
-- and dd.postal_cd != 'DC' /*for division by zero error in postal_cd group by */

--group by dd.postal_cd
--group by dd.locale
group by dd.district_size