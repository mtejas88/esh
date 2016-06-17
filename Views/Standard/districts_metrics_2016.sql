with district_info_by_li	as	(										
	select	ldli.line_item_id,										
	sum(d.num_students::numeric)	as	num_students_served									
												
	from	lines_to_district_by_line_item_2016	ldli									
												
	join	districts_demog_2016	d									
	on	ldli.district_esh_id	=	d.esh_id								
												
	join	fy2016.line_items	li									
	on	ldli.line_item_id	=	li.id								
												
	where	li.consortium_shared=true										
	OR	'backbone'=any(li.open_flags)										
												
	group	by	ldli.line_item_id									
),												
bandwidth_calc	as	(										
	select											
	district_esh_id,											
	sum(case											
	when	'committed_information_rate'	=	any(open_flags)								
	and	exclude	=	FALSE								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	com_info_bandwidth,									
	sum(case											
	when	internet_conditions_met	=	TRUE								
	and	(not('committed_information_rate'	=	any(open_flags))								
	and	exclude	=	FALSE								
	or	open_flags	is	null)								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	internet_bandwidth,									
	sum(case											
	when	upstream_conditions_met	=	TRUE								
	and	(not('committed_information_rate'	=	any(open_flags))								
	and	exclude	=	FALSE								
	or	open_flags	is	null)								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	upstream_bandwidth,									
	sum(case											
	when	isp_conditions_met	=	TRUE								
	and	(not('committed_information_rate'	=	any(open_flags))								
	and	exclude	=	FALSE								
	or	open_flags	is	null)								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	isp_bandwidth,									
	sum(case											
	when	'committed_information_rate'	=	any(open_flags)								
	and not('exclude_for_cost_only'	=	any(open_flags))									
	and	exclude	=	FALSE								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	com_info_bandwidth_cost,									
	sum(case											
	when	internet_conditions_met	=	TRUE								
	and	((not('committed_information_rate'	=	any(open_flags))								
	and not('exclude_for_cost_only'	=	any(open_flags)))									
	or	open_flags	is	null)								
	and	exclude	=	FALSE								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	internet_bandwidth_cost,									
	sum(case											
	when	upstream_conditions_met	=	TRUE								
	and	((not('committed_information_rate'	=	any(open_flags))								
	and not('exclude_for_cost_only'	=	any(open_flags)))									
	or	open_flags	is	null)								
	and	exclude	=	FALSE								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	upstream_bandwidth_cost,									
	sum(case											
	when	isp_conditions_met	=	TRUE								
	and	((not('committed_information_rate'	=	any(open_flags))								
	and not('exclude_for_cost_only'	=	any(open_flags)))									
	or	open_flags	is	null)								
	and	exclude	=	FALSE								
	then	bandwidth_in_mbps	*	allocation_lines								
	else	0										
	end)	as	isp_bandwidth_cost,									
	sum(case											
	when	(isp_conditions_met	=	TRUE								
	or	internet_conditions_met	=	TRUE								
	or	upstream_conditions_met	=	TRUE								
	or	'committed_information_rate'	=	any(open_flags))								
	and	(not('exclude_from_cost_only'	=	any(open_flags)) or open_flags is null)								
	and	exclude	=	FALSE								
	then	total_cost::numeric	*	(allocation_lines::numeric	/	num_lines::numeric)						
	else	0										
	end)	as	ia_cost_direct_to_district,									
	sum(case											
	when	((consortium_shared	=	TRUE	and	(internet_conditions_met	=	TRUE	or	isp_conditions_met	=	true))
	or	'backbone'=any(open_flags))										
	and	(not('charter_service'=any(open_flags))	or	open_flags	is	null)						
	and	(not('video_conferencing'=any(open_flags))	or	open_flags	is	null)						
	and	(not('exclude'=any(open_flags))	or	open_flags	is	null)						
	and	(not('exclude_for_cost_only'=any(open_flags))	or	open_flags	is	null)						
	then	total_cost::numeric	*	(d.num_students::numeric/district_info_by_li.num_students_served::numeric)								
	else	0										
	end)	as	ia_cost_backbone_pieces									
	from	lines_to_district_by_line_item_2016	ldli									
	join	fy2016.line_items	li									
	on	ldli.line_item_id	=	li.id								
	join	districts_demog_2016	d									
	on	ldli.district_esh_id	=	d.esh_id								
	left	join	district_info_by_li									
	on	district_info_by_li.line_item_id	=	ldli.line_item_id								
	group	by	district_esh_id									
)												
												
select	d.*,											
	com_info_bandwidth,											
	internet_bandwidth,											
	upstream_bandwidth,											
	isp_bandwidth,											
	case											
	when	com_info_bandwidth	>	0								
	then	com_info_bandwidth										
	when	upstream_bandwidth	=	0								
	then	isp_bandwidth										
	when	isp_bandwidth	=	0								
	then	upstream_bandwidth										
	when	upstream_bandwidth	>	isp_bandwidth								
	then	isp_bandwidth										
	else	upstream_bandwidth										
	end	+	internet_bandwidth	as	ia_bandwidth_calc,							
	case
		when num_students != 0
			then (case											
					when	com_info_bandwidth	>	0								
					then	com_info_bandwidth										
					when	upstream_bandwidth	=	0								
					then	isp_bandwidth										
					when	isp_bandwidth	=	0								
					then	upstream_bandwidth										
					when	upstream_bandwidth	>	isp_bandwidth								
					then	isp_bandwidth										
					else	upstream_bandwidth										
					end	+	internet_bandwidth)/num_students*1000
	end as ia_bandwidth_per_student,								
	ia_cost_direct_to_district,											
	ia_cost_backbone_pieces,											
  	com_info_bandwidth_cost,												
	internet_bandwidth_cost,											
	upstream_bandwidth_cost,											
	isp_bandwidth_cost,											
	case											
	  when (case											
          	when	com_info_bandwidth_cost	>	0								
          	then	com_info_bandwidth_cost										
          	when	upstream_bandwidth_cost	=	0								
          	then	isp_bandwidth_cost										
          	when	isp_bandwidth_cost	=	0								
          	then	upstream_bandwidth_cost										
          	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
          	then	isp_bandwidth_cost										
          	else	upstream_bandwidth_cost										
          	end	+	internet_bandwidth_cost) > 0									
	    then (ia_cost_direct_to_district	+	ia_cost_backbone_pieces)/(case									
                                                                    	when	com_info_bandwidth_cost	>	0								
                                                                    	then	com_info_bandwidth_cost										
                                                                    	when	upstream_bandwidth_cost	=	0								
                                                                    	then	isp_bandwidth_cost										
                                                                    	when	isp_bandwidth_cost	=	0								
                                                                    	then	upstream_bandwidth_cost										
                                                                    	when	upstream_bandwidth_cost	>	isp_bandwidth_cost								
                                                                    	then	isp_bandwidth_cost										
                                                                    	else	upstream_bandwidth_cost										
                                                                    end	+	internet_bandwidth_cost)					
  end as	ia_cost_per_mbps_calc											
												
from	districts_demog_2016											
left	join	bandwidth_calc										
on	districts_demog_2016.esh_id	=	bandwidth_calc.district_esh_id									
