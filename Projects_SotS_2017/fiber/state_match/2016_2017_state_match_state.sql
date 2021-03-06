with a as (

		/* 2017 FRNs, excluding ones that have been updated/are in current view*/
		select 2017 as year,
		f.frn_status,
		f.frn,
		f.match_amount,
		f.postal_cd

		from fy2017.frns f

		inner join public.fy2017_esh_line_items_v eli
		on eli.frn = f.frn

		left join public.fy2017_services_received_matr sr
		on eli.id = sr.line_item_id

		left join public.fy2017_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		and f.frn not in (select frn from fy2017.current_frns)

		and (
		/* frn either includes at least one line item that is received by districts in our population*/
		 (dd.include_in_universe_of_districts = true and dd.district_type = 'Traditional')

		 or 

		/* frn filed by school or district in our population */ 
		 eli.applicant_ben in (select eb.ben
							from public.fy2017_district_lookup_matr dl

							inner join public.entity_bens eb
							on eb.entity_id = dl.esh_id::numeric

							inner join public.fy2017_districts_deluxe_matr dd
							on dl.district_esh_id = dd.esh_id

							where dd.include_in_universe_of_districts = true
							and dd.district_type = 'Traditional')
		 	)

		group by f.frn,
		f.match_amount,
		f.frn_status,
		f.postal_cd


	union 

		/* 2017 FRNs that have been updated/are in current view and are approved*/
		select 2017 as year,
		f.frn_status,
		f.frn,
		f.match_amount,
		f.postal_cd

		from fy2017.current_frns f

		inner join public.fy2017_esh_line_items_v eli
		on eli.frn = f.frn

		left join public.fy2017_services_received_matr sr
		on eli.id = sr.line_item_id

		left join public.fy2017_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		and (
		/* frn either includes at least one line item that is received by districts in our population*/
		 (dd.include_in_universe_of_districts = true and dd.district_type = 'Traditional')

		 or 

		/* frn filed by school or district in our population */ 
		 eli.applicant_ben in (select eb.ben
							from public.fy2017_district_lookup_matr dl

							inner join public.entity_bens eb
							on eb.entity_id = dl.esh_id::numeric

							inner join public.fy2017_districts_deluxe_matr dd
							on dl.district_esh_id = dd.esh_id

							where dd.include_in_universe_of_districts = true
							and dd.district_type = 'Traditional')
		 	)

		group by f.frn,
		f.match_amount,
		f.frn_status,
		f.postal_cd

	union 

		/* 2016 FRNs, excluding ones that have been updated/are in current view*/
		select 2016 as year,
		f.frn_status,
		f.frn,
		f.match_amount,
		f.postal_cd

		from fy2016.frns f

		inner join fy2016.line_items eli
		on eli.frn = f.frn

		left join public.fy2016_services_received_matr sr
		on eli.id = sr.line_item_id

		left join public.fy2016_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		and f.frn not in (select frn from fy2016.current_frns)

		and (
		/* frn either includes at least one line item that is received by districts in our population*/
		 (dd.include_in_universe_of_districts = true and dd.district_type = 'Traditional')

		 or 

		/* frn filed by school or district in our population */ 
		 eli.applicant_ben in (select eb.ben
							from public.fy2016_district_lookup_matr dl

							inner join public.entity_bens eb
							on eb.entity_id = dl.esh_id::numeric

							inner join public.fy2016_districts_deluxe_matr dd
							on dl.district_esh_id = dd.esh_id

							where dd.include_in_universe_of_districts = true
							and dd.district_type = 'Traditional')
		 	)
		
		group by f.frn,
		f.match_amount,
		f.frn_status,
		f.postal_cd

	union 

		/* 2016 FRNs that have been updated/are in current view and are approved*/
		select 2016 as year,
		f.frn_status,
		f.frn,
		f.match_amount,
		f.postal_cd
		
		from fy2016.current_frns  f

		inner join fy2016.line_items eli
		on eli.frn = f.frn

		left join public.fy2016_services_received_matr sr
		on eli.id = sr.line_item_id

		left join public.fy2016_districts_deluxe_matr dd
		on dd.esh_id::numeric = sr.applicant_id

		where match_amount::numeric > 0

		and (
		/* frn either includes at least one line item that is received by districts in our population*/
		 (dd.include_in_universe_of_districts = true and dd.district_type = 'Traditional')

		 or 

		/* frn filed by school or district in our population */ 
		 eli.applicant_ben in (select eb.ben
							from public.fy2016_district_lookup_matr dl

							inner join public.entity_bens eb
							on eb.entity_id = dl.esh_id::numeric

							inner join public.fy2016_districts_deluxe_matr dd
							on dl.district_esh_id = dd.esh_id

							where dd.include_in_universe_of_districts = true
							and dd.district_type = 'Traditional')
		 	)
		

		group by f.frn,
		f.match_amount,
		f.frn_status,
		f.postal_cd)

select 
postal_cd,
sum(match_amount::numeric)

from a 
where frn_status not in ('Cancelled', 'Denied')

group by 1