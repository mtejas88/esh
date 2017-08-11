select
  case
    when current_assumed_unscalable_campuses+current_known_unscalable_campuses > 0
    or hierarchy_ia_connect_category != 'Fiber'
      then 'non-fiber'
    when (case
            when ia_monthly_cost_total < 14*50 and ia_monthly_cost_total > 0
              then ia_monthly_cost_total/14
            else knapsack_bandwidth(ia_monthly_cost_total)
          end*1000/dd.num_students) >= 100
      then 'affordability'
    when meeting_2014_goal_oversub = true
      then 'concurrency'
    when ia_bw_mbps_total < 1000 and (1000000*dd.fiber_internet_upstream_lines)/num_students::numeric >= 100
      then 'upgrade fiber to 1G'
    when dd.postal_cd in ('AK', 'NE', 'TN', 'KY', 'FL', 'HI', 'SD')
      then 'no governor commitment'
    when procurement != 'District-procured'
      then 'state or regional network'
    when (upstream_bandwidth > 0 and isp_bandwidth > 0 and upstream_bandwidth != isp_bandwidth)
    and (((upstream_bandwidth+internet_bandwidth)*1000)/num_students::numeric >= 100 or ((isp_bandwidth+internet_bandwidth)*1000)/num_students::numeric >= 100)
      then 'mismatched ISP/upstream'
    when district_size in ('Large', 'Mega')
      then 'more internet bw needed per WAN' 
    else 'unknown'
  end as diagnosis,
  sum(dd.num_students::numeric) as num_students
from public.fy2017_districts_deluxe_matr dd
join public.fy2017_districts_aggregation_matr da
on dd.esh_id = da.district_esh_id
join public.states s
on dd.postal_cd = s.postal_cd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and exclude_from_ia_analysis= false
and meeting_2014_goal_no_oversub = false
group by 1