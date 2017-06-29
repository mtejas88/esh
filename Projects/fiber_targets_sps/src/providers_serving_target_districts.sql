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
	case
		when reporting_name = 'Ace Telephone Assoc'
			then 'Ace Telephone Co'
		when reporting_name = 'Alpoha Enterprised'
			then 'Alpha Enterprises'
		when reporting_name = 'Cablevision'
			then 'Altice USA'
		when reporting_name = 'Araphaoe Tele Co'
			then 'Arapahoe Tele Co'
		when reporting_name = 'Alascom, Inc.'
			then 'AT&T'
		when reporting_name = 'Cable One, Inc'
			then 'Cable One, Inc.'
		when reporting_name in ('Charter', 'Charter Advanced Services (VT) LLC', 'Charter Cable')
			then 'Charter'
		when reporting_name = 'FairPoint'
			then 'Fairpoint'
		when reporting_name in ('Frontier', 'Frontier Communications Online and Long Distance, Inc.', 'Frontier North, Inc.')
			then 'Frontier'
		when reporting_name = 'Fusion Technologies, LLC'
			then 'Fusion'
		when reporting_name = 'GovNet'
			then 'GovNET Inc.'
		when reporting_name = 'Illimois Central'
			then 'Illinois Central'
		when reporting_name = 'MCC Telephony'
			then 'Mediacom'
		when reporting_name = 'OneNet USA'
			then 'OneNet'
		when reporting_name = 'Range'
			then 'Range Tele'
		when reporting_name in ('Ameilia Telephone Co', 'Asotin Tele', 'TDS Metrocom')
			then 'TDS Telecom'
		when reporting_name in ('Time Warner', 'Time Warner Cable Business LLC')
			then 'Time Warner Cable'
		when reporting_name = 'Valley Telcom'
			then 'Valley Telecom'
		else reporting_name
	end as reporting_name, 
	case
		when reporting_name in (
			'3 Rivers Tele Coop',	'Ace Telephone Assoc',	'Ace Telephone Co',	'Agate Mutual',	'Alaska Telephone Co',	'Alpine',
			'Blackfoot',	'Blue Ridge',	'Calaveras',	'Consolidated Telco',	'Craw-Kan Tele',	'Custer Tele',
			'Fidelity',	'Gila River',	'Golden Belt Tele',	'Golden West',	'Grand River',	'Green Hills', 'Hamilton Tele',
			'Hinton Tele',	'Hood Canal',	'Hopi Telecommunications',	'Hutchinson Tele',	'InterBel Telephone',	'Interstate Telecomm',
			'Mid-Rivers Tele',	'Midstate Comm',	'Mutual Telephone',	'NEMONT COMM',	'North Texas Tele',	'Northeast Nebraska Telephone Company',
			'Pierce Telephone',	'Pinnacles Telephone',	'Pioneer Telephone',	'Range',	'Range Tele',	'Reservation Tele',
			'Sierra Tel',	'Sioux Valley',	'Southern Montana',	'Table Top Tele',	'Taylor Tele Coop',	'Terril',
			'Venture Comm Coop',	'Vermont Tele Co',	'W River Telecomm',	'Whidbey Tele Co',	'Woodhull Comm',	
			'Ameilia Telephone Co',	'Andrew Tele Co',	'Araphaoe Tele Co',	'Arrowhead Comm Co',	'Asotin Tele',	'Baraga Tele Co',
			'Dalton Tele',	'Dickey Rural',	'DRS Technical',	'Dubois Tele',	'Eagle Telephone System, Inc.',	'Fenton Coop',
			'Hager Telecomm',	'Happy Valley',	'Harrisonville',	'Haviland',	'Heart of Iowa Communications Cooperative',	'Hiawatha Tele',
			'Le-Ru Telephone',	'Leaco Rural',	'Lincoln Telephone Company, Inc.',	'LR Communications',	'Mabel Coop',	'Mercury',
			'Northern Tele Coop',	'Northwest Comm',	'Oregon-Idaho Utilities, Inc.',	'Paul bunyan',	'Peoples Comm',	'Phillips County',
			'River Valley',	'Riviera Tele',	'Royal Tele Co',	'S&T Tele Coop',	'Salina-Spavinaw',	'Santel Comm',
			'Tri County',	'Triangle Tele',	'UTELCO, LLC',	'Valley Telcom',	'Valley Telecom',	'Van Buren Tele Co'
		)
			then true
		else false
	end as rural_telco,
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
group by 1,2
order by 3 desc,4 desc,5 desc,6 desc