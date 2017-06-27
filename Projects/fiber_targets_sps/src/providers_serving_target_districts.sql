with sp_nonfib_noncab as (
	select distinct sr.reporting_name, dd.esh_id
	from fy2016_districts_deluxe_matr dd
	join fy2016_services_received_matr sr
	on dd.esh_id = sr.recipient_id
	where dd.include_in_universe_of_districts_all_charters
	and dd.fiber_target_status = 'Target'
	and sr.inclusion_status != 'dqs_excluded'
	and sr.purpose not in ('ISP', 'Backbone', 'Not broadband')
	and sr.connect_category not ilike '%fiber%'
	and sr.connect_category not ilike '%cable%'
),
sp_cable as (
	select distinct sr.reporting_name, dd.esh_id
	from fy2016_districts_deluxe_matr dd
	join fy2016_services_received_matr sr
	on dd.esh_id = sr.recipient_id
	where dd.include_in_universe_of_districts_all_charters
	and dd.fiber_target_status = 'Target'
	and sr.inclusion_status != 'dqs_excluded'
	and sr.purpose not in ('ISP', 'Backbone', 'Not broadband')
	and sr.connect_category ilike '%cable%'
),
sp_fiber as (
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
						when service = 'nonfiber'
							then esh_id
					end) as fiber_target_districts_served_nonfiber_noncable,
	count(distinct 	case
						when service = 'cable'
							then esh_id
					end) as fiber_target_districts_served_cable, 
	count(distinct 	case
						when service = 'fiber'
							then esh_id
					end) as fiber_target_districts_served_fiber
from (
	select *, 'nonfiber' as service
	from sp_nonfib_noncab

	UNION

	select *, 'cable' as service
	from sp_cable
	where esh_id not in (
		select distinct esh_id
		from sp_nonfib_noncab	
	)

	UNION

	select *, 'fiber' as service
	from sp_fiber
	where esh_id not in (
		select distinct esh_id
		from (
			select distinct esh_id
			from sp_nonfib_noncab
			UNION
			select distinct esh_id
			from sp_cable
		) sp_nonfib	
	)
) sps_wanted
group by 1
order by 2,3,4,5 desc