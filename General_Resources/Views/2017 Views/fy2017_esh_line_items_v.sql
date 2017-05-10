/*
Author: Jamie Barnes
Created On Date: 5/8/2017
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: View to mimic 2016 version of line items table for 2017 by adding back in columns we dropped from public.esh_line_items
Methodology: All aggregation done in temp tables prior to joining them into esh_line_items. Columns not from esh_line_items are indented one. 
Dependencies: public.esh_line_items, fy2017.frn_line_items, fy2017.basic_informations, 
	public.esh_service_providers, public.flags, public.tags, public.esh_allocations, public.entity_bens
*/


with f as (select
	flaggable_id,
	count(distinct label) as num_open_flags,
	array_agg(label) as open_flag_labels

	from public.flags 
	where status = 'open'
	and flaggable_type = 'LineItem'
	and funding_year = 2017

	group by flaggable_id
	),
t as (select
	taggable_id,
	count(distinct label) as num_open_tags,
	array_agg(label) as open_tag_labels

	from public.tags
	where deleted_at is null
	and taggable_type = 'LineItem'
	and funding_year = 2017

	group by taggable_id
	),
r as (select line_item_id,
	count(distinct recipient_ben) as num_recipients
	
	from public.esh_allocations

	group by line_item_id
	)

select 
eli.id,
eli.frn_complete,
	
	fli.frn,

eli.application_number,
	
	bi.applicant_type as application_type, /*USAC identifcation */

eli.applicant_ben,
	
	bi.billed_entity_name as applicant_name,
	eb.entity_type as applicant_type, /*ESH identification*/
	bi.postal_cd as applicant_postal_cd,

eli.service_provider_id,

	esp.service_provider_name,
	bi.category_of_service as service_category,

eli.base_line_item_id,
eli.funding_year,
eli.service_type,
eli.connect_type,
eli.purpose,
eli.function,
eli.bandwidth_in_mbps,
eli.upload_bandwidth_in_mbps,

	concat(fli.download_speed,' ',fli.download_speed_units) as bandwidth_in_original_units,

case
	when eli.num_lines = -1
	then 'Unknown'
	else eli.num_lines::char
end as num_lines,

eli.one_time_elig_cost,
eli.rec_elig_cost,
eli.months_of_service,
eli.contract_end_date,
eli.erate,
eli.exclude,
eli.connect_category,
eli.total_cost,
eli.consortium_shared,
eli.broadband,
eli.isp_conditions_met,
eli.upstream_conditions_met,
eli.internet_conditions_met,
eli.wan_conditions_met,
eli.backbone_conditions_met,
eli.created_at,
eli.updated_at,

	r.num_recipients,
/* intentionally putting open flag and tag arrays at the end 
since presence of nulls in these will offset column values in spreadsheets */
	f.num_open_flags,
	f.open_flag_labels,
	t.open_tag_labels

from public.esh_line_items eli

left join fy2017.frn_line_items fli 
on fli.line_item = eli.frn_complete

left join fy2017.basic_informations bi 
on bi.application_number =  eli.application_number

/*not sure if this is the table and what the column names will be*/
left join public.esh_service_providers esp 
on esp.service_provider_id = eli.service_provider_id

left join f
on f.flaggable_id = eli.id

left join t
on t.taggable_id = eli.id

left join r
on r.line_item_id = eli.id

left join public.entity_bens eb
on eb.ben = eli.applicant_ben

where eli.funding_year = 2017
/*not sure if service provider will be funding year specific*/
and esp.funding_year = 2017