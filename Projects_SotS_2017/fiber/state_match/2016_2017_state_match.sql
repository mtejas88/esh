with a as (

		/* 2017 FRNs, excluding ones that have been updated/are in current view*/
		select 2017 as year,
		f.frn_status,
		f.frn,
		f.match_amount

		from fy2017.frns f

		inner join public.fy2017_esh_line_items_v eli
		on eli.frn = f.frn

		inner join public.fy2017_services_received_matr sr
		on eli.id = sr.line_item_id

		inner join public.fy2017_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		/* frn includes at least one line item that is not excluded*/
		and sr.inclusion_status != 'dqs_excluded'
		/* frn includes at least one line item that is received by districts in our population*/
		and dd.include_in_universe_of_districts = true
		and dd.district_type = 'Traditional'

		and f.frn not in (select frn from fy2017.current_frns)

		group by f.frn,
		f.match_amount,
		f.frn_status


	union 

		/* 2017 FRNs that have been updated/are in current view and are approved*/
		select 2017 as year,
		f.frn_status,
		f.frn,
		f.match_amount

		from fy2017.current_frns f

		inner join public.fy2017_esh_line_items_v eli
		on eli.frn = f.frn

		inner join public.fy2017_services_received_matr sr
		on eli.id = sr.line_item_id

		inner join public.fy2017_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		/* frn includes at least one line item that is not excluded*/
		and sr.inclusion_status != 'dqs_excluded'
		/* frn includes at least one line item that is received by districts in our population*/
		and dd.include_in_universe_of_districts = true
		and dd.district_type = 'Traditional'

		group by f.frn,
		f.match_amount,
		f.frn_status

	union 

		/* 2016 FRNs, excluding ones that have been updated/are in current view*/
		select 2016 as year,
		f.frn_status,
		f.frn,
		f.match_amount

		from fy2016.frns f

		inner join fy2016.line_items eli
		on eli.frn = f.frn

		inner join public.fy2016_services_received_matr sr
		on eli.id = sr.line_item_id

		inner join public.fy2016_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		/* frn includes at least one line item that is not excluded*/
		and sr.inclusion_status != 'dqs_excluded'
		/* frn includes at least one line item that is received by districts in our population*/
		and dd.include_in_universe_of_districts = true
		and dd.district_type = 'Traditional'

		and f.frn not in (select frn from fy2016.current_frns)
		
		group by f.frn,
		f.match_amount,
		f.frn_status

	union 

		/* 2017 FRNs that have been updated/are in current view and are approved*/
		select 2016 as year,
		f.frn_status,
		f.frn,
		f.match_amount
		
		from fy2016.current_frns  f

		inner join fy2016.line_items eli
		on eli.frn = f.frn

		inner join public.fy2016_services_received_matr sr
		on eli.id = sr.line_item_id

		inner join public.fy2016_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		/* frn includes at least one line item that is not excluded*/
		and sr.inclusion_status != 'dqs_excluded'
		/* frn includes at least one line item that is received by districts in our population*/
		and dd.include_in_universe_of_districts = true
		and dd.district_type = 'Traditional'
		

		group by f.frn,
		f.match_amount,
		f.frn_status)


select year,
frn_status,
sum(match_amount::numeric)

from a 

group by year, frn_status