select  		sd.campus_id,
				sd.postal_cd,
				sd.school_esh_ids,
				sd.district_esh_id,
				sd.num_schools,
				sd.num_students,
--ia bw/student pieces
				sum(case
							when	'committed_information_rate'	=	any(open_flags)
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth,
				sum(case
							when	isp_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_flags)) or	open_flags	is	null)
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps >= 25
								then	allocation_lines
							else	0
						end)	as	broadband_internet_upstream_lines,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_flags)) or	open_flags	is	null)
							and	number_of_dirty_line_item_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps < 25
								then	allocation_lines
							else	0
						end)	as	not_broadband_internet_upstream_lines,
--ia cost/mbps pieces
				sum(case
							when	'committed_information_rate'	=	any(open_flags)
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth_cost,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags)
										or 'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth_cost,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags)
										or 'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth_cost,
				sum(case
							when	isp_conditions_met	=	TRUE
							and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags)
										or 'committed_information_rate'	=	any(open_flags))
										or	open_flags	is	null)
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth_cost,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_flags))
									and	number_of_dirty_line_item_flags	=	0
							and	(not(	'exclude_for_cost_only'	=	any(open_flags))
										or	open_flags	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
									else	0
								end)	as	ia_monthly_cost_direct_to_district,
						sum(case
									when	'backbone' = any(open_flags)
									and	number_of_dirty_line_item_flags	=	0
									and school_info_by_li.num_students_served::numeric > 0
										then	esh_rec_cost::numeric	/ school_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_backbone_pieces,
						sum(case
									when	consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true)
									and	number_of_dirty_line_item_flags	=	0
									and school_info_by_li.num_students_served::numeric > 0
										then	esh_rec_cost::numeric	/ school_info_by_li.num_students_served::numeric
									else	0
								end)	as	ia_monthly_cost_per_student_shared_ia_pieces,
-- campus fiber percentage pieces
						sum(case
									when	wan_conditions_met = true
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as wan_lines,
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
						sum(case
									when	not(connect_category ilike '%fiber%')
									and isp_conditions_met = false
									and (not('backbone' = any(open_flags)) or open_flags is null)
									and	number_of_dirty_line_item_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as non_fiber_lines

from (
	select 	s.postal_cd,
			case
				when campus_id is null or campus_id = 'Unknown'
					then s.address
				else campus_id
			end as campus_id,
			s.district_esh_id,
			d.include_in_universe_of_districts as district_include_in_universe_of_districts,
			array_agg(s.esh_id) as school_esh_ids,
			count(*) as num_schools,
			sum(case
					when s.num_students='No data'
						then 0
					when s.num_students::numeric > 0
						then s.num_students::numeric
					else 0
				end) as num_students

    from public.schools s
    join public.districts_schools ds
	on s.esh_id = ds.school_id
    join public.districts d
	on s.district_esh_id = d.esh_id
    group by 	s.postal_cd,
				case
					when campus_id is null or campus_id = 'Unknown'
						then s.address
					else campus_id
				end,
				s.district_esh_id,
				d.include_in_universe_of_districts
 ) sd
left join public.fy2015_lines_to_school_by_line_item_m as lsli
on 	sd.campus_id = lsli.campus_id

left join	(
		select *,
				case
					when rec_elig_cost != 'No data'
						then 	case
									when rec_elig_cost::numeric > 0
										then rec_elig_cost::numeric
									else one_time_eligible_cost/  case
																	when orig_r_months_of_service = 0 or orig_r_months_of_service is null
																		then 12
																	else orig_r_months_of_service
																  end
								end
					else one_time_eligible_cost/ case
													when orig_r_months_of_service = 0 or orig_r_months_of_service is null
														then 12
													else orig_r_months_of_service
												 end

				end as esh_rec_cost

		from public.line_items
		where broadband = true
		and (not('canceled' = any(open_flags) or
		        'video_conferencing' = any(open_flags) or
		        'exclude' = any(open_flags))
	    		or open_flags is null)
)	li
on	lsli.line_item_id	=	li.id

left join (
	select	lsli.line_item_id,
			sum(s.num_students::numeric)	as	num_students_served

	from public.fy2015_lines_to_school_by_line_item_m	lsli

	join public.districts_schools	ds
	on lsli.campus_id	=	ds.campus_id

	join public.schools	s
	on ds.school_id	=	s.esh_id

	join public.line_items	li
	on lsli.line_item_id	=	li.id

	where	(li.consortium_shared=true
	or 'backbone' = any(open_flags))
	and broadband = true
	and s.num_students != 'No data'

	group by lsli.line_item_id
) school_info_by_li
on	school_info_by_li.line_item_id	=	lsli.line_item_id

where sd.postal_cd in ('DE', 'HI', 'RI')
and district_include_in_universe_of_districts
group by	sd.campus_id,
			sd.postal_cd,
			sd.school_esh_ids,
			sd.district_esh_id,
			sd.num_schools,
			sd.num_students

/*
Author: Justine Schott
Created On Date: 12/8/2016
Last Modified Date:
Name of QAing Analyst(s):
*/