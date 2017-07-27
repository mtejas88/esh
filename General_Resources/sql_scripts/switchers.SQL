with sp_assignment_2015 as( select  recipient_sp_bw_rank.recipient_id as esh_id,

reporting_name,

recipient_sp_bw_rank.purpose_list as primary_sp_purpose,

recipient_sp_bw_rank.bandwidth as primary_sp_bandwidth,

recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total as primary_sp_percent_of_bandwidth

  from (

    select  *,

            row_number() over (partition by recipient_id order by bandwidth desc ) as bw_rank

    from (

      select  recipient_id,

              case

                when reporting_name = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                else reporting_name

              end as reporting_name,

              num_students,

              meeting_2014_goal_no_oversub,

              sum(bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric) as bandwidth,

              sum(case

                    when purpose = 'Transport'

                      then bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric

                    else 0

                  end) as upstream_bandwidth,
                
              array_agg(distinct purpose2 order by purpose2) as purpose_list

      from (select a.*, case when purpose='Transport' then 'Upstream' else purpose end as purpose2
      from public.fy2015_services_received_m a) sr

      join public.fy2015_districts_deluxe_m dd

      on sr.recipient_id = dd.esh_id

      where quantity_of_lines_received_by_district != 'Shared Circuit'
      and (internet_conditions_met=true or upstream_conditions_met=true)
      and consortium_shared=false
      and dirty_status ilike '%clean%'

      group by 1,2,3,4

    )recipient_sp_bw

  ) recipient_sp_bw_rank

  left join (

    select  recipient_id,

            sum(bandwidth) as bw_total

    from (

      select  recipient_id,

              case

                when reporting_name = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                else reporting_name

              end as reporting_name,

              num_students,

              meeting_2014_goal_no_oversub,

              sum(bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric) as bandwidth,

              sum(case

                    when purpose = 'Upstream'

                      then bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric

                    else 0

                  end) as upstream_bandwidth

      from public.fy2015_services_received_m sr

      join public.fy2015_districts_deluxe_m dd

      on sr.recipient_id = dd.esh_id

      where quantity_of_lines_received_by_district != 'Shared Circuit'
      and (internet_conditions_met=true or upstream_conditions_met=true)
      and consortium_shared=false
      and dirty_status ilike '%clean%'

      group by 1,2,3,4

    )recipient_sp_bw




    group by 1

  ) recipient_sp_bw_total

  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id

  where bw_rank = 1
  
  and recipient_sp_bw_total.bw_total > 0

  /*adding bw_total > 0 as the new staging db Rose has more 2017 data and a lot of rows have bw_total that are 0,
this prevents the creation of the materialized view due to division error of 0*/

  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5
),

d15 as (select c.*,
    case
      when mg.discount_rate_c1::numeric <= 25
      then ' 20-25%'
      when mg.discount_rate_c1 is not null 
      then to_char(discount_rate_c1::numeric,'99%')
      when c.frl_percent is null
      then null
      when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 20-25%'
      when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 20-25%'
      when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 40%'
      when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 70%'
      when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 80%'
      when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 80%'
      when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 90%'
      when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 90%'
      else 'error'
    end as discount_rate_c1,
    case 
      when mg.discount_rate_c2::numeric <= 25
      then ' 20-25%'
      when mg.discount_rate_c2 is not null 
      then to_char(discount_rate_c2::numeric,'99%')
      when c.frl_percent is null
      then null
      when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 20-25%'
      when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 20-25%'
      when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 40%'
      when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 50%'
      when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 60%'
      when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 70%'
      when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 80%'
      when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 80%'
      when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
      then ' 85%'
      when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
      then ' 85%'
      else 'error'
    end as discount_rate_c2,
    case 
        when mg.discount_rate_c1 is not null
        then mg.discount_rate_c1::numeric/100
        when c.frl_percent is null
        then null 
        when c.frl_percent < .1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .2
        when c.frl_percent < .1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .25
        when c.frl_percent < .2 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .4
        when c.frl_percent < .2 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .5
        when c.frl_percent < .35 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .6
        when c.frl_percent < .35 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .6
        when c.frl_percent < .50 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .6
        when c.frl_percent < .50 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .7
        when c.frl_percent < .75 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .8
        when c.frl_percent < .75 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .8
        when c.frl_percent <= 1 and (c.locale = 'Urban' or  c.locale = 'Suburban')
        then .9
        when c.frl_percent <= 1 and (c.locale = 'Small Town' or  c.locale = 'Rural')
        then .9
        else null
      end as discount_rate_c1_num, -- for calculations 
      sp.reporting_name as service_provider_assignment, sp.primary_sp_purpose, sp.primary_sp_bandwidth, sp.primary_sp_percent_of_bandwidth
    from public.fy2015_districts_deluxe_m c
    left join endpoint.fy2015_districts_deluxe mg
    on c.esh_id = mg.esh_id
    join sp_assignment_2015 sp
    on c.esh_id=sp.esh_id)

select
2016 as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.num_students, 
dd.num_schools::numeric,
dd.num_campuses,
dd.locale,
dd.district_size,
dd.frl_percent,
dd.exclude_from_ia_analysis,
dd.exclude_from_ia_cost_analysis,
case
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .05
  then '<5%'
  when dd.frl_percent <=.74
  then '5-74%'
  else '75%+'
end as frl_percent_grouping,

-- General E-rate/Broadband Info
case
  when dd.discount_rate_c1_matrix <= .25
  then ' 20-25%'
  else to_char(dd.discount_rate_c1_matrix*100,'99%')
end as discount_rate_c1,
case
  when dd.discount_rate_c2 <= .25
  then ' 20-25%'
  when dd.discount_rate_c2 is not null 
  then to_char(dd.discount_rate_c2*100,'99%')
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .1 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 20-25%'
  when dd.frl_percent < .1 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 20-25%'
  when dd.frl_percent < .2 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 40%'
  when dd.frl_percent < .2 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Urban' or dd.locale = 'Suburban')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 70%'
  when dd.frl_percent < .75 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 80%'
  when dd.frl_percent < .75 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 80%'
  else ' 85%'
end as discount_rate_c2,
org_structure,
case 
  when dd.exclude_from_ia_analysis = false
  then dd.ia_procurement_type
  else null
end as ia_procurement_type,
case
  when dd.postal_cd in ('AZ','CA','CO','FL','IL','KS','MA','MD','MN','MO','MT','NC','NH','NJ','NM','NV','NY','OH','OK','TX','VA','WA','WI','WY','AK','AL','CT','NE','OR')
  then 'Engaged'
  else 'Non Engaged'
end as state_engagement,
case when dd.needs_wifi=true then 'Insuff. Wi-Fi'
when dd.needs_wifi=false then 'Suff. Wi-Fi' else 'Unknown' 
end as wifi_need,
dd.fiber_target_status,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal,
case
  when d.exclude_from_analysis = true
  then null
  when d.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal_16,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_1m_goal,
case when dd.exclude_from_ia_analysis = false then dd.ia_bw_mbps_total end as ia_bw_mbps_total,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_total end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then true
  when dd.exclude_from_ia_analysis = false and d.exclude_from_analysis = false and 
  (dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false) or (dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = true)
  then false
  else null
end as upgrade_indicator,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target,
case 
  when ddd.fiber_target_status = 'Not Target' and dd.fiber_target_status = 'Target' 
  then 1
  else null
end as cohort_16_to_17_fiber,
case
  when ddd.exclude_from_ia_analysis = false and dd.exclude_from_ia_analysis = false and ddd.meeting_2014_goal_no_oversub = true and dd.meeting_2014_goal_no_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity,
dd.service_provider_assignment as dominant_sp,
dd.primary_sp_bandwidth,
dd.primary_sp_percent_of_bandwidth,

case when d.exclude_from_analysis=false then d.total_ia_bw_mbps::numeric end as ia_bw_mbps_total_16,
case when d.exclude_from_analysis=false then d.monthly_ia_cost_per_mbps::numeric end as ia_monthly_cost_per_mbps_16,
case when d.exclude_from_analysis=false then d.total_ia_monthly_cost::numeric end as ia_monthly_cost_total_16,
d.service_provider_assignment as dominant_sp_16,
case when sr15.earliest_contract_end_date < '2016-07-01' then 'Expiring' else 'Mid-Contract'
end as contract_expiring,
case when dd.primary_sp_purpose::varchar=d.primary_sp_purpose::varchar then 'Same' else 'Different' end as purpose_match, 
case when dd.service_provider_assignment=d.service_provider_assignment or ((d.service_provider_assignment=gsp.service_provider_2015
and dd.service_provider_assignment=gsp.service_provider_2016)
or (d.service_provider_assignment=ssp.service_provider_2015
and dd.service_provider_assignment=ssp.service_provider_2016
and dd.postal_cd=ssp.postal_cd)) then 'Did Not Switch' else 'Switched' end as switcher


from public.fy2016_districts_deluxe_matr dd
left join d15 d
on dd.esh_id::numeric = d.esh_id
left join public.fy2017_districts_deluxe_matr ddd
on ddd.esh_id::numeric = dd.esh_id::numeric
left join public.states s
on dd.postal_cd = s.postal_cd
join (select recipient_id, reporting_name, min(contract_end_date) as earliest_contract_end_date
from public.fy2015_services_received_m
group by 1,2) sr15
on dd.esh_id::numeric=sr15.recipient_id::numeric
and d.service_provider_assignment=sr15.reporting_name
left join  public.general_sp_not_switchers gsp
on d.service_provider_assignment=gsp.service_provider_2015
and dd.service_provider_assignment=gsp.service_provider_2016
left join public.state_specific_sp_not_switchers ssp
on d.service_provider_assignment=ssp.service_provider_2015
and dd.service_provider_assignment=ssp.service_provider_2016
and dd.postal_cd=ssp.postal_cd
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.service_provider_assignment is not null 
and d.service_provider_assignment is not null
and d.monthly_ia_cost_per_mbps not in ('Insufficient data','Infinity')

union

select
2017 as year,
dd.esh_id::numeric,
initcap(dd.name) as name,
dd.postal_cd,
dd.num_students, 
dd.num_schools::numeric,
dd.num_campuses,
dd.locale,
dd.district_size,
dd.frl_percent,
dd.exclude_from_ia_analysis,
dd.exclude_from_ia_cost_analysis,
case
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .05
  then '<5%'
  when dd.frl_percent <=.74
  then '5-74%'
  else '75%+'
end as frl_percent_grouping,

-- General E-rate/Broadband Info
case
  when dd.discount_rate_c1_matrix <= .25
  then ' 20-25%'
  else to_char(dd.discount_rate_c1_matrix*100,'99%')
end as discount_rate_c1,
case
  when dd.discount_rate_c2 <= .25
  then ' 20-25%'
  when dd.discount_rate_c2 is not null 
  then to_char(dd.discount_rate_c2*100,'99%')
  when dd.frl_percent is null
  then null
  when dd.frl_percent < .1 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 20-25%'
  when dd.frl_percent < .1 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 20-25%'
  when dd.frl_percent < .2 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 40%'
  when dd.frl_percent < .2 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Urban' or dd.locale = 'Suburban')
  then ' 50%'
  when dd.frl_percent < .35 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 60%'
  when dd.frl_percent < .50 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 70%'
  when dd.frl_percent < .75 and (dd.locale = 'Urban' or  dd.locale = 'Suburban')
  then ' 80%'
  when dd.frl_percent < .75 and (dd.locale = 'Town' or  dd.locale = 'Rural')
  then ' 80%'
  else ' 85%'
end as discount_rate_c2,
s.org_structure,
case
  when dd.exclude_from_ia_analysis = false 
  then dd.ia_procurement_type
  else null
end as ia_procurement_type,
case
  when dd.postal_cd in ('AZ','CA','CO','FL','IL','KS','MA','MD','MN','MO','MT','NC','NH','NJ','NM','NV','NY','OH','OK','TX','VA','WA','WI','WY','AK','AL','CT','NE','OR')
  then 'Engaged'
  else 'Non Engaged'
end as state_engagement,
case when dd.needs_wifi=true then 'Insuff. Wi-Fi'
when dd.needs_wifi=false then 'Suff. Wi-Fi' else 'Unknown' 
end as wifi_need,
dd.fiber_target_status,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal,
case
  when d.exclude_from_ia_analysis = true
  then null
  when d.meeting_2014_goal_no_oversub = true 
  then 1
  else 0
end as meeting_100k_goal_16,
case
  when dd.exclude_from_ia_analysis = true
  then null
  when dd.meeting_2018_goal_oversub = true
  then 1
  else 0
end as meeting_1m_goal,
case when dd.exclude_from_ia_analysis = false then dd.ia_bw_mbps_total end as ia_bw_mbps_total,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.ia_monthly_cost_total end as ia_monthly_cost_total,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then true
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and 
  (dd.meeting_2014_goal_no_oversub = false and d.meeting_2014_goal_no_oversub = false) or (dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = true)
  then false
  else null
end as upgrade_indicator,
case when dd.exclude_from_ia_analysis = false and dd.exclude_from_ia_cost_analysis = false then dd.meeting_knapsack_affordability_target end as meeting_knapsack_affordability_target,
case 
  when dd.fiber_target_status = 'Not Target' and d.fiber_target_status = 'Target' 
  then 1
  else null
end as cohort_16_to_17_fiber,
case
  when dd.exclude_from_ia_analysis = false and d.exclude_from_ia_analysis = false and dd.meeting_2014_goal_no_oversub = true and d.meeting_2014_goal_no_oversub = false
  then 1
  else null
end as cohort_16_to_17_connectivity,
dd.service_provider_assignment as dominant_sp,
dd.primary_sp_bandwidth,
dd.primary_sp_percent_of_bandwidth,

case when d.exclude_from_ia_analysis = false then d.ia_bw_mbps_total end as ia_bw_mbps_total_16,
case when d.exclude_from_ia_analysis = false and d.exclude_from_ia_cost_analysis = false then d.ia_monthly_cost_per_mbps end as ia_monthly_cost_per_mbps_16,
case when d.exclude_from_ia_analysis = false and d.exclude_from_ia_cost_analysis = false then d.ia_monthly_cost_total end as ia_monthly_cost_total_16,
d.service_provider_assignment as dominant_sp_16,
case when sr16.earliest_contract_end_date < '2017-07-01' then 'Expiring' else 'Mid-Contract'
end as contract_expiring,
case when dd.primary_sp_purpose=d.primary_sp_purpose then 'Same' else 'Different' end as purpose_match, 
case when dd.service_provider_assignment!=d.service_provider_assignment then 'Switched' else 'Did Not Switch' end as switcher


from public.fy2017_districts_deluxe_matr dd
left join public.fy2016_districts_deluxe_matr d
on dd.esh_id::numeric = d.esh_id::numeric
left join public.states s
on dd.postal_cd = s.postal_cd
join (select recipient_id, reporting_name, min(contract_end_date) as earliest_contract_end_date
from public.fy2016_services_received_matr
group by 1,2) sr16
on dd.esh_id::numeric=sr16.recipient_id::numeric
and d.service_provider_assignment=sr16.reporting_name
where dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'
and dd.service_provider_assignment is not null 
and d.service_provider_assignment is not null
