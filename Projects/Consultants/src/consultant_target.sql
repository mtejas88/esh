-- -----------------------------------------------------------------------------------------

-- This query is to pull all targets and potential targets for the E-rate consultant E-rate 360 Solutions
-- See ZenDesk Ticket #494

-- -----------------------------------------------------------------------------------------
select 
  distinct c.name as consultant_names,
  c.consultant_registration_number as consultant_num,
  d.esh_id,
  d.name,
  d.num_schools,
  d.num_students,
  d.postal_cd

from 
	public.fy2017_district_lookup_matr dl

left join public.entity_bens eb
	on dl.esh_id::numeric = eb.entity_id

left join public.fy2017_districts_deluxe_matr d
	on dl.district_esh_id = d.esh_id

join fy2017.consultants c
	on eb.ben = c.ben

join public.fy2017_esh_line_items_v li
	on c.application_number = li.application_number

where 
	d.include_in_universe_of_districts and
	exclude_from_ia_analysis = false and
	c.name like '%360%' and
	(d.fiber_target_status != ('Not Target')
	or
	d.bw_target_status != ('Not Target')
	or
	d.wifi_target_status != ('Not Target'))
