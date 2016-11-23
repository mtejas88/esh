select  		dd.esh_id as district_esh_id,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_flags))
									and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and rec_elig_cost != 'No data'
									and consortium_shared = false
									and num_lines::numeric>0
										then	rec_elig_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
									else	0
								end)	as	ia_monthly_cost_direct_to_district,
						sum(case
									when	'backbone' = any(open_flags)
									and	number_of_dirty_line_item_flags	=	0
									and rec_elig_cost != 'No data'
									and district_info_by_li.num_students_served::numeric > 0
										then	rec_elig_cost::numeric	/ district_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_backbone_pieces,
						sum(case
									when	consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true)
									and rec_elig_cost != 'No data'
									and	number_of_dirty_line_item_flags	=	0
									and district_info_by_li.num_students_served::numeric > 0
										then	rec_elig_cost::numeric	/ district_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_shared_ia_pieces,
						d15.num_students,
						d15.exclude_from_analysis,
						sum(case
									when	connect_category ilike '%fiber%'
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_lines,
						sum(case
									when	connect_category = 'Fixed Wireless'
									and connect_type != 'Satellite Service'
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fixed_wireless_lines,
						sum(case
									when	connect_type = 'Cable Modem'
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as cable_lines,
						sum(case
									when	(connect_category = 'Copper'
											or connect_type = 'Digital Subscriber Line (DSL)')
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as copper_dsl_lines,
						sum(case
									when	connect_type in ('Satellite Service', 'Data Plan/Air Card Service')
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as satellite_lte_lines,
						d15.num_campuses,
						sum(case
									when isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as lines_w_dirty


from	public.fy2016_districts_demog_matr dd
left join public.districts d15
on dd.esh_id = d15.esh_id::varchar
left join public.lines_to_district_by_line_item_2015_m	ldli
on 	dd.esh_id = ldli.district_esh_id::varchar
left join	(
		select *
		from public.line_items
		where broadband = true
		and (not('canceled' = any(open_flags) or
		        'video_conferencing' = any(open_flags) or
		        'exclude' = any(open_flags))
	    		or open_flags is null)
)	li
on	ldli.line_item_id	=	li.id
left join (
		select	ldli.line_item_id,
						sum(d.num_students::numeric)	as	num_students_served

		from public.lines_to_district_by_line_item_2015_m	ldli

		join public.districts	d
		on ldli.district_esh_id	=	d.esh_id

		join public.line_items	li
		on ldli.line_item_id	=	li.id

		where	(li.consortium_shared=true
		or 'backbone' = any(open_flags))
		and broadband = true
		and d.num_students != 'No data'

		group	by	ldli.line_item_id
) district_info_by_li
on	district_info_by_li.line_item_id	=	ldli.line_item_id
where dd.include_in_universe_of_districts
and d15.include_in_universe_of_districts

group by	  	dd.esh_id,
				d15.num_students,
				d15.exclude_from_analysis,
				d15.num_campuses


/*
Author: Justine Schott
Created On Date: 10/18/2016
Last Modified Date:
Name of QAing Analyst(s):
Purpose: For comparing across years
Methodology: Utilizing line items and 2016 districts universe
*/

--ia cost pieces
/*				sum(case
							when	'committed_information_rate'	=	any(open_flags)
							and	number_of_dirty_line_item_flags	=	0
							and (not(	'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and rec_elig_cost != 'No data'
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth_cost,
				sum(case
							when	internet_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_flags)
												or 'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and rec_elig_cost != 'No data'
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth_cost,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_flags)
												or 'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and rec_elig_cost != 'No data'
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth_cost,
				sum(case
							when	isp_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_flags)
												or 'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and rec_elig_cost != 'No data'
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth_cost,*/