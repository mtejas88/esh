with sp_nonfib as (
	select distinct sr.reporting_name, dd.esh_id
	from fy2016_districts_deluxe_matr dd
	join fy2016_services_received_matr sr
	on dd.esh_id = sr.recipient_id
	where dd.include_in_universe_of_districts_all_charters
	and dd.fiber_target_status = 'Target'
	and sr.inclusion_status != 'dqs_excluded'
	and sr.purpose not in ('ISP', 'Backbone', 'Not broadband')
	and sr.connect_category not ilike '%fiber%'
),
sp_fib as (
	select distinct sr.reporting_name, dd.esh_id
	from fy2016_districts_deluxe_matr dd
	join fy2016_services_received_matr sr
	on dd.esh_id = sr.recipient_id
	where dd.include_in_universe_of_districts_all_charters
	and dd.fiber_target_status = 'Target'
	and sr.inclusion_status != 'dqs_excluded'
	and sr.purpose not in ('ISP', 'Backbone', 'Not broadband')
	and sr.connect_category ilike '%fiber%'
)


select 
	reporting_name, 
	count(distinct esh_id) as fiber_target_districts_served,
	count(distinct 	case
						when nonfiber = true
							then esh_id
					end) as fiber_target_districts_served_nonfiber, 
	count(distinct 	case
						when nonfiber = false
							then esh_id
					end) as fiber_target_districts_served_fiber
from (
	select *, true as nonfiber
	from sp_nonfib

	UNION

	select *, false as nonfiber
	from sp_fib
	where esh_id not in (
		select distinct esh_id
		from sp_nonfib	
	)
) sps_wanted
group by 1
order by 2 desc