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
--new fiber was built by a service provider
  and fiber_type != 'Self Provisioned'
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
--new fiber was built by a service provider
  and fiber_type != 'Self Provisioned'
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
		end as most_recent_spec_k
	from fy2017_districts_deluxe_matr dd
	left join spec_k_2016
	on dd.esh_id = spec_k_2016.recipient_id
	left join spec_k_2017
	on dd.esh_id = spec_k_2017.recipient_id
	where include_in_universe_of_districts
	and district_type = 'Traditional'
)

select
	case
		when dist_2017.locale in ('Rural', 'Town')
			then 'Rural'
		else 'Urban'
	end as locale_grouped,
	case
		when most_recent_spec_k is null
			then 'none'
		else most_recent_spec_k
	end as most_recent_spec_k,	
	count(*) as districts,
	sum(dist_2016.unscalable_campuses) as unscalable_campuses_2016
/*	dist_2017.*, dist_2016.unscalable_campuses as unscalable_campuses_2016, dist_2016.ia_bw_mbps_total as ia_bw_mbps_total_2016 */

from dist_2016
full outer join dist_2017
on dist_2016.esh_id = dist_2017.esh_id
where (dist_2017.fiber_target_status = 'Not Target' or dist_2017.fiber_target_status is null)
and dist_2016.fiber_target_status = 'Target'
and dist_2016.unscalable_campuses > 0
group by 1, 2


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
