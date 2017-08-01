select  		sd.campus_id,
				sd.postal_cd,
				sd.school_esh_ids,
				sd.district_esh_id,
				sd.num_schools,
				sd.num_students,
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

							and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))

										or	open_tag_labels	is	null)

							and consortium_shared = false

								then	bandwidth_in_mbps	*	allocation_lines

							else	0

						end)	as	com_info_bandwidth_cost,

				sum(case

							when	internet_conditions_met	=	TRUE

							and	(not(	'committed_information_rate'	=	any(open_tag_labels)

												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))

										or	open_tag_labels	is	null)

							and	num_open_flags	=	0

							and consortium_shared = false

								then	bandwidth_in_mbps	*	allocation_lines

							else	0

						end)	as	internet_bandwidth_cost,

				sum(case

							when	upstream_conditions_met	=	TRUE

							and	(not(	'committed_information_rate'	=	any(open_tag_labels)

												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))

										or	open_tag_labels	is	null)

							and	num_open_flags	=	0

							and consortium_shared = false

								then	bandwidth_in_mbps	*	allocation_lines

							else	0

						end)	as	upstream_bandwidth_cost,

				sum(case

							when	isp_conditions_met	=	TRUE

							and (not(	'committed_information_rate'	=	any(open_tag_labels)

												or 'exclude_for_cost_only_restricted'	=	any(open_tag_labels))

										or	open_tag_labels	is	null)

							and	num_open_flags	=	0

								then	bandwidth_in_mbps	*	allocation_lines

							else	0

						end)	as	isp_bandwidth_cost,

						sum(case

									when	(isp_conditions_met	=	TRUE

												or	internet_conditions_met	=	TRUE

												or	upstream_conditions_met	=	TRUE

												or	'committed_information_rate'	=	any(open_tag_labels))

									and	num_open_flags	=	0

									and (not(	'exclude_for_cost_only_restricted'	=	any(open_tag_labels))

										or	open_tag_labels	is	null)

									and consortium_shared = false

									and num_lines::numeric>0

										then	esh_rec_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)

																	/* case
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

										then	esh_rec_cost::numeric	/ school_info_by_li.num_students_served::numeric /* months_of_service )*/

									else	0

								end)	as	ia_monthly_cost_per_student_backbone_pieces,

						sum(case

									when	consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true)

									and	num_open_flags	=	0

									and school_info_by_li.num_students_served::numeric > 0

										then	esh_rec_cost::numeric	/ school_info_by_li.num_students_served::numeric /** months_of_service )*/

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
				when campus_id is null or campus_id = 'Unknown' or campus_id = '0'
					then address
				else campus_id
			end as campus_id,
			district_esh_id,
			district_include_in_universe_of_districts,
			array_agg(school_esh_id) as school_esh_ids,
			count(*) as num_schools,
			sum(case
					when num_students > 0
						then num_students
					else 0
				end) as num_students,
			case
				when sum(frl_percentage_denomenator) > 0
					then sum(frl_percentage_numerator)/sum(	 frl_percentage_denomenator)
			end as frl_percent

    from public.fy2017_schools_demog_matr
    group by 	1,2,3,4
 ) sd
left join public.fy2017_lines_to_school_by_line_item_matr as lsli
on 	sd.campus_id = lsli.campus_id


left join



  ( SELECT

public.fy2017_esh_line_items_v.id,public.fy2017_esh_line_items_v.frn_complete,public.fy2017_esh_line_items_v.frn,public.fy2017_esh_line_items_v.application_number,public.fy2017_esh_line_items_v.application_type,
public.fy2017_esh_line_items_v.applicant_ben,public.fy2017_esh_line_items_v.applicant_name,public.fy2017_esh_line_items_v.applicant_postal_cd,public.fy2017_esh_line_items_v.service_provider_id,
/*public.fy2017_esh_line_items_v.name,*/public.fy2017_esh_line_items_v.service_type,public.fy2017_esh_line_items_v.service_category,public.fy2017_esh_line_items_v.connect_type,
public.fy2017_esh_line_items_v.connect_category,public.fy2017_esh_line_items_v.purpose,public.fy2017_esh_line_items_v.bandwidth_in_mbps,public.fy2017_esh_line_items_v.bandwidth_in_original_units,
public.fy2017_esh_line_items_v.num_lines,public.fy2017_esh_line_items_v.total_cost,public.fy2017_esh_line_items_v.one_time_elig_cost,public.fy2017_esh_line_items_v.rec_elig_cost,
public.fy2017_esh_line_items_v.months_of_service,public.fy2017_esh_line_items_v.contract_end_date,public.fy2017_esh_line_items_v.num_open_flags,public.fy2017_esh_line_items_v.open_flag_labels,
public.fy2017_esh_line_items_v.open_tag_labels,public.fy2017_esh_line_items_v.num_recipients,public.fy2017_esh_line_items_v.erate,public.fy2017_esh_line_items_v.broadband,
public.fy2017_esh_line_items_v.consortium_shared,public.fy2017_esh_line_items_v.isp_conditions_met,public.fy2017_esh_line_items_v.upstream_conditions_met,
public.fy2017_esh_line_items_v.internet_conditions_met,public.fy2017_esh_line_items_v.wan_conditions_met,/*public.fy2017_esh_line_items_v.exclude,*/public.fy2017_esh_line_items_v.upload_bandwidth_in_mbps,
public.fy2017_esh_line_items_v.backbone_conditions_met,public.fy2017_esh_line_items_v.function,


           eb.id as real_applicant_id,

           eb.type as real_applicant_type,

           CASE

               WHEN rec_elig_cost > 0 then rec_elig_cost

               ELSE one_time_elig_cost/ CASE

                                            WHEN months_of_service = 0

                                                 OR months_of_service is null then 12

                                            ELSE months_of_service

                                        END

           END AS esh_rec_cost,

           --adda.reporting_name
           spc.name as service_provider_name,

           frns.discount_rate::numeric/100 as discount_rate


   FROM public.fy2017_esh_line_items_v -- this is the view name


   left join (
   		select a.*
   		from salesforce.account a
   		join fy2017_districts_demog_matr dd 
   		on a.esh_id__c::varchar = dd.esh_id
   	) eb

   on eb.ben__c::varchar = public.fy2017_esh_line_items_v.applicant_ben::varchar

   left join fy2017.frns

   on fy2017_esh_line_items_v.frn = frns.frn

   left join(

    select distinct id, reporting_name, name

    from public.service_provider_categories  --using the same public table that we used in 2016

    ) spc

   on fy2017_esh_line_items_v.service_provider_id::varchar = spc.id::varchar --adding the view name*/

   WHERE broadband = true

     AND (not('canceled' = any(open_flag_labels)

              OR 'video_conferencing' = any(open_flag_labels)

              OR 'exclude' = any(open_flag_labels))

          OR open_flag_labels is null) ) li

on	lsli.line_item_id	=	li.id

left join (
--this allocates cost to all students, regardless of whether the district is in our universe or not
--you won't be able to reconcile with final table because the final table only includes those in our universe

		select	lsli.line_item_id,

						sum(s.num_students::numeric)	as	num_students_served




		from fy2017_lines_to_school_by_line_item_matr	lsli




		join fy2017_schools_demog_matr s

		on lsli.campus_id	=	s.campus_id




		join public.fy2017_esh_line_items_v li --using the view instead of the table instead

		on lsli.line_item_id	=	li.id



		where	(li.consortium_shared=true

		or backbone_conditions_met = true)

		and broadband = true




		group	by	lsli.line_item_id

) school_info_by_li

on	school_info_by_li.line_item_id	=	lsli.line_item_id
where sd.postal_cd in ('DE', 'HI', 'RI')
and district_include_in_universe_of_districts
group by	1,2,3,4,5,6,7




/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 7/12/2017 - js copied from fy2017_districts_aggregation_matr
Name of QAing Analyst(s):
Purpose: Districts' line item aggregation (bw, lines, cost of pieces contributing to metrics),
as well as school metric, flag/tag, and discount rate aggregation
Methodology: Utilizing other aggregation tables

*/
