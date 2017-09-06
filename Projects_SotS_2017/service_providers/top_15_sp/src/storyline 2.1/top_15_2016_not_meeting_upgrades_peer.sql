with districts_notmeeting_2016_top15 as
(select distinct esh_id, service_provider_assignment,
meeting_2014_goal_no_oversub, num_students
from public.fy2016_districts_deluxe_matr del
where  exclude_from_ia_analysis=false
and include_in_universe_of_districts
and meeting_2014_goal_no_oversub=false
and service_provider_assignment in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
),

districts_2017 as (
  select *,
  case
    when district_size = 'Tiny'
      then 5
    when district_size = 'Small'
      then 4
    when district_size = 'Medium'
      then 3
    when district_size = 'Large'
      then 2
    when district_size = 'Mega'
      then 1
  end as district_size_number,
  left(ulocal,1)::int as locale_number
  from fy2017_districts_deluxe_matr
  where include_in_universe_of_districts
  and district_type = 'Traditional'
), 

scalable_ia_temp as (
  select 
    recipient_id,
    recipient_postal_cd,
    line_item_id as line_item_id_scalable_ia,
    bandwidth_in_mbps as bandwidth_in_mbps_scalable_ia,
    case
      when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total
      else monthly_circuit_cost_recurring
    end as monthly_circuit_cost_recurring_scalable_ia,
    case
      when monthly_circuit_cost_recurring = 0 then monthly_circuit_cost_total / bandwidth_in_mbps
      else monthly_circuit_cost_recurring / bandwidth_in_mbps
    end as ia_cost_per_mbps_scalable,
    connect_category as connect_category_scalable_ia,
    service_provider_name as service_provider_name_scalable_ia,
    reporting_name as reporting_name_scalable_ia,
    district_size_number,
    locale_number
  from public.fy2017_services_received_matr sr
  join districts_2017 dd
  on sr.recipient_id = dd.esh_id
  where recipient_include_in_universe_of_districts = TRUE
  and recipient_exclude_from_ia_analysis = FALSE
  and inclusion_status = 'clean_with_cost'
  and connect_category in ('Lit Fiber')
  and purpose in ('Internet', 'Upstream')
  and line_item_id not in ('739869', '806826', '812008', '863608')
  ),

districts_peer as (
  select dd.esh_id, 
 count( distinct(case when dd.ia_monthly_cost_total <= scalable_ia_temp.monthly_circuit_cost_recurring_scalable_ia
  and dd.ia_bw_mbps_total >= scalable_ia_temp.bandwidth_in_mbps_scalable_ia
  and dd.esh_id != scalable_ia_temp.recipient_id
   then line_item_id_scalable_ia end)) as peer_deals
  from districts_notmeeting_2016_top15 nm16
  join districts_2017 dd
on nm16.esh_id=dd.esh_id
  join scalable_ia_temp
--in the same state unless mega
  on  case
        when dd.district_size = 'Mega'
          then true
        else dd.postal_cd = scalable_ia_temp.recipient_postal_cd
      end
  and dd.district_size_number in (
    scalable_ia_temp.district_size_number-1,
    scalable_ia_temp.district_size_number, 
    scalable_ia_temp.district_size_number+1)
  and dd.locale_number in (
    scalable_ia_temp.locale_number-1,
    scalable_ia_temp.locale_number, 
    scalable_ia_temp.locale_number+1)
 where dd.exclude_from_ia_analysis= false
group by 1
  )


--Determine if upgraders got a deal as good as one of their peers
select  
dd.meeting_2014_goal_no_oversub,
case when peer_deals > 0 then true else false end as got_peer_deal,
count(distinct nm16.esh_id) as ndistricts,
sum(nm16.num_students) as nstudents
from districts_notmeeting_2016_top15 nm16
join districts_2017 dd
on nm16.esh_id=dd.esh_id
left join districts_peer 
on nm16.esh_id=districts_peer.esh_id
where dd.exclude_from_ia_analysis=false
group by 1,2 order by 1,2


