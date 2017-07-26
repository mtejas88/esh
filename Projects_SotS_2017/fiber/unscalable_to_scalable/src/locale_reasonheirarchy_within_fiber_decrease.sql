with dist_2016 as (
	select *,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
		taggable_id is not null as manually_tagged_target 
	from fy2016_districts_deluxe_matr dd
	left join (
		select distinct taggable_id
		from fy2016.tags
		where label = 'fiber_target'
		and deleted_at is null
	) fiber_target
	on dd.esh_id = fiber_target.taggable_id::varchar
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

change_sps as (
	select sr17.recipient_id
	from (
		select recipient_id, array_agg(distinct reporting_name order by reporting_name) as reporting_names
		from fy2017_services_received_matr 
		where recipient_include_in_universe_of_districts
		and inclusion_status != 'dqs_excluded'
		group by 1
	) sr17
	left join (
		select recipient_id, array_agg(distinct reporting_name order by reporting_name) as reporting_names
		from fy2016_services_received_matr 
		where inclusion_status != 'dqs_excluded'
		group by 1
	) sr16
	on sr17.recipient_id = sr16.recipient_id
	where sr17.reporting_names != sr16.reporting_names
),

spec_k_2017 as (
  select distinct sr.recipient_id
  from fy2017.frns
  join (
    select *
    from public.fy2017_esh_line_items_v 
  ) li 
  on frns.frn = li.frn
  join public.fy2017_services_received_matr sr
  on li.id = sr.line_item_id
--new fiber was built  
  where fiber_sub_type = 'Special Construction'
),

spec_k_2016 as (
  select distinct sr.recipient_id
  from fy2016.frns
  join fy2016.line_items li 
  on frns.frn = li.frn
  join public.fy2016_services_received_matr sr
  on li.id = sr.line_item_id
--new fiber was built  
  where fiber_sub_type = 'Special Construction'
),

dist_2017 as (
	select dd.*,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
		case
			when spec_k_2017.recipient_id is not null
				then '2017'
			when spec_k_2016.recipient_id is not null
				then '2016'
			else 'none'
		end as most_recent_spec_k,
		case
			when change_sps.recipient_id is not null
				then true
			else false
		end as change_sps 
	from fy2017_districts_deluxe_matr dd
	left join change_sps 
	on dd.esh_id = change_sps.recipient_id
	left join spec_k_2016
	on dd.esh_id = spec_k_2016.recipient_id
	left join spec_k_2017
	on dd.esh_id = spec_k_2017.recipient_id
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

comparison as (
	select
		dist_2017.esh_id,
		dist_2017.locale,
		dist_2017.most_recent_spec_k,
		dist_2017.change_sps,
		dist_2016.fiber_target_status,
		case
			when dist_2017.ia_monthly_cost_total is null 
				then false
			when dist_2017.ia_monthly_cost_total + dist_2017.wan_monthly_cost_total > (dist_2016.ia_monthly_cost_total + dist_2016.wan_monthly_cost_total) * 1.1
				then true
			else false
		end as spent_10pct_more,	
		case
			when dist_2017.num_campuses is null 
				then dist_2016.num_campuses
			when dist_2016.num_campuses - dist_2017.num_campuses < 0 
				then 0
			else dist_2016.num_campuses - dist_2017.num_campuses
		end as lost_campuses,	
		dist_2016.unscalable_campuses as lost_unscalable_campuses
	from dist_2016
	full outer join dist_2017
	on dist_2016.esh_id = dist_2017.esh_id
	where (dist_2017.fiber_target_status = 'Not Target' or dist_2017.fiber_target_status is null)
	--and dist_2016.fiber_target_status = 'Target'
	and dist_2016.unscalable_campuses > 0
)


select
	case
		when fiber_target_status = 'Target'
			then true
		else false
	end as target_2016,
	case
		when locale in ('Rural', 'Town')
			then 'Rural'
		else 'Urban'
	end as locale_grouped,

	case
	  when esh_id is null
	  	then 'left universe'
	  when change_sps is null or change_sps
	  	then 'at least 1 sp change'
	  when spent_10pct_more
	  	then 'spent more $'
	  when most_recent_spec_k in ('2016', '2017')
	  	then 'fiber construction 2017 or 2016'
	  else 'unknown'
	end as reason_heirarchy,
	  	
	count(*) as districts,
	sum(lost_unscalable_campuses) as lost_unscalable_campuses,
	sum(case
			when lost_campuses > lost_unscalable_campuses
				then lost_unscalable_campuses
			else lost_campuses
		end) as lost_unscalable_campuses_due_to_lost_campuses,
	sum(case
			when lost_campuses > lost_unscalable_campuses
				then 0
			else lost_unscalable_campuses - lost_campuses
		end) as lost_unscalable_campuses_due_to_reason
/*	dist_2017.*, dist_2016.unscalable_campuses as unscalable_campuses_2016, dist_2016.ia_bw_mbps_total as ia_bw_mbps_total_2016 */

from comparison
group by 1, 2, 3


/*	
dist_2017.fiber_wan_lines > dist_2016.fiber_wan_lines or
		dist_2017.lt_1g_nonfiber_wan_lines < dist_2016.lt_1g_nonfiber_wan_lines as more_fiber_less_nonfiber_wan_lines,
	dist_2017.fiber_internet_upstream_lines > dist_2016.fiber_internet_upstream_lines as more_fiber_internet_lines,
		dist_2017.fixed_wireless_internet_upstream_lines + dist_2017.cable_internet_upstream_lines +
			dist_2017.copper_internet_upstream_lines + dist_2017.satellite_lte_internet_upstream_lines < 
				dist_2016.fixed_wireless_internet_upstream_lines + dist_2016.cable_internet_upstream_lines +
					dist_2016.copper_internet_upstream_lines + dist_2016.satellite_lte_internet_upstream_lines
					as less_nonfiber_internet_lines,
dist_2017.wan_monthly_cost_total + dist_2017.ia_monthly_cost_total > 
		(dist_2016.wan_monthly_cost_total + dist_2016.ia_monthly_cost_total) * 1.1 as more_money_spent_on_services,
	manually_tagged_target,
	dist_2017.num_campuses < dist_2016.num_campuses as less_campuses,

and dist_2017.exclude_from_ia_analysis = false

*/
