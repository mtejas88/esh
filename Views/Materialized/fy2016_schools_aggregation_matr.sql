select  		sd.campus_id,
				sd.postal_cd,
				sd.school_esh_ids, 
				sd.district_esh_id,
				sd.num_schools,
        		sd.frl_percent,
--ia bw/student pieces
				sum(case
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth,
				sum(case
							when	internet_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth,
				sum(case
							when	isp_conditions_met	=	TRUE
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps >= 25
								then	allocation_lines
							else	0
						end)	as	broadband_internet_upstream_lines,
				sum(case
							when	(upstream_conditions_met	=	TRUE or internet_conditions_met = TRUE)
							and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
							and bandwidth_in_mbps < 25
								then	allocation_lines
							else	0
						end)	as	not_broadband_internet_upstream_lines,
--ia cost/mbps pieces
				sum(case
							when	'committed_information_rate'	=	any(open_tag_labels)
							and	num_open_flags	=	0
							and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels)
										or 'exclude_for_cost_only_free'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	com_info_bandwidth_cost,
				sum(case
							when	internet_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_free'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	internet_bandwidth_cost,
				sum(case
							when	upstream_conditions_met	=	TRUE
							and	(not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_free'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	upstream_bandwidth_cost,
				sum(case
							when	isp_conditions_met	=	TRUE
							and (not(	'committed_information_rate'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_free'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
							and	num_open_flags	=	0
							and consortium_shared = false
								then	bandwidth_in_mbps	*	allocation_lines
							else	0
						end)	as	isp_bandwidth_cost,
						sum(case
									when	(isp_conditions_met	=	TRUE
												or	internet_conditions_met	=	TRUE
												or	upstream_conditions_met	=	TRUE
												or	'committed_information_rate'	=	any(open_tag_labels))
									and	num_open_flags	=	0
									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels)
												or 'exclude_for_cost_only_free'	=	any(open_tag_labels))
										or	open_tag_labels	is	null)
									and consortium_shared = false
									and num_lines::numeric>0
										then	rec_elig_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)
																	/*/ case
																		when months_of_service = 0 or months_of_service is null
																			then 12
																		else months_of_service
																	  end*/
									else	0
								end)	as	ia_monthly_cost_direct_to_district,
						sum(case
									when	backbone_conditions_met = true
									and	num_open_flags	=	0
									and school_info_by_li.num_students_served::numeric > 0
										then	rec_elig_cost::numeric	/ school_info_by_li.num_students_served::numeric /** months_of_service )*/
									else	0
								end)	as	ia_monthly_cost_per_student_backbone_pieces,
						sum(case
									when	consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true)
									and	num_open_flags	=	0
									and school_info_by_li.num_students_served::numeric > 0
										then	rec_elig_cost::numeric	/ school_info_by_li.num_students_served::numeric /** months_of_service )*/
									else	0
								end)	as	ia_monthly_cost_per_student_shared_ia_pieces,
-- campus fiber percentage pieces
						sum(case
									when	wan_conditions_met = true
									and	(not('committed_information_rate'	=	any(open_tag_labels)) or	open_tag_labels	is	null)
									and	num_open_flags	=	0
									and consortium_shared = false
										then allocation_lines
									else	0
								end) as wan_lines,
						sum(case
									when	connect_category ilike '%fiber%'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fiber_lines,
						sum(case
									when	connect_category = 'Fixed Wireless'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as fixed_wireless_lines,
						sum(case
									when	connect_category = 'Cable'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as cable_lines,
						sum(case
									when	connect_category in ('Other Copper', 'T-1', 'DSL')
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as copper_dsl_lines,
						sum(case
									when	connect_category = 'Satellite/LTE'
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as satellite_lte_lines,
						sum(case
									when not(connect_category ilike '%fiber%')
									and isp_conditions_met = false
									and backbone_conditions_met = false
									and	num_open_flags	=	0
									and consortium_shared = false
										then	allocation_lines
									else	0
								end) as non_fiber_lines

from (
	select 	postal_cd,
			case
				when campus_id is null or campus_id = 'Unknown'
					then address
				else campus_id
			end as campus_id,
			district_esh_id,
			array_agg(school_esh_id) as school_esh_ids,
			count(*) as num_schools,
			case
				when sum(frl_percentage_denomenator) > 0
					then sum(frl_percentage_numerator)/sum(	 frl_percentage_denomenator)
			end as frl_percent

    from public.fy2016_schools_demog_matr 
    group by 	postal_cd,
				case
					when campus_id is null or campus_id = 'Unknown'
						then address
					else campus_id
				end,
				district_esh_id
 ) sd
left join public.fy2016_lines_to_school_by_line_item_matr as lsli
on 	sd.campus_id = lsli.campus_id

left join	(
	select *
	from fy2016.line_items 
	where broadband = true
	and (not('canceled' = any(open_flag_labels) or
	        'video_conferencing' = any(open_flag_labels) or
	        'exclude' = any(open_flag_labels)) or 
		open_flag_labels is null)

)	li
on	lsli.line_item_id	=	li.id

left join (

	select	lsli.line_item_id,
			sum(s.num_students::numeric) as	num_students_served
	from public.fy2016_lines_to_school_by_line_item_matr as	lsli
	join public.fy2016_schools_demog_matr s
	on lsli.campus_id	=	s.campus_id

	join fy2016.line_items	li
	on lsli.line_item_id	=	li.id

	where (li.consortium_shared=true or backbone_conditions_met = true)
	and broadband = true
	group	by	lsli.line_item_id

) school_info_by_li
on	school_info_by_li.line_item_id	=	lsli.line_item_id

where sd.postal_cd in ('DE', 'HI', 'RI')
group by	sd.campus_id,
			sd.postal_cd,
			sd.school_esh_ids, 
			sd.district_esh_id,
			sd.num_schools,
    		sd.frl_percent

/*
Author: Jess Seok
Created On Date: 11/21/2016
Last Modified Date: 
Name of QAing Analyst(s):Justine Schott
*/