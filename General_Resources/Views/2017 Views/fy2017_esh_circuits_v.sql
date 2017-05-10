/*
Author: Jamie Barnes
Created On Date: 5/8/2017
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: View to mimic 2016 version of circuits table for 2017 by adding back in columns we dropped from public.esh_circuits
Methodology: All aggregation done in temp tables prior to joining them into esh_line_items. Columns not from esh_line_items are indented one.
Dependencies: public.esh_circuits, public.esh_line_items, public.esh_service_providers, public.flags, public.tags, public.esh_allocations
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
	where funding_year = 2017

	group by line_item_id
	)

select 
ec.id,
ec.line_item_id,
ec.funding_year,

	eli.service_provider_id,
	esp.service_provider_name,

ec.circuit_cost,
ec.connect_category,

	eli.connect_type,
	eli.function,
	eli.bandwidth_in_mbps,
	eli.upload_bandwidth_in_mbps,
	eli.months_of_service,

ec.broadband,
	
	eli.exclude,
	eli.erate,

ec.consortium_shared,
ec.isp_conditions_met,
ec.upstream_conditions_met,
ec.internet_conditions_met,
ec.wan_conditions_met,
ec.backbone_conditions_met,
	
	r.num_recipients,
/* intentionally putting open flag and tag arrays at the end 
since presence of nulls in these will offset column values in spreadsheets */
	f.num_open_flags,
	f.open_flag_labels,
	t.open_tag_labels

from public.esh_circuits ec

left join public.esh_line_items eli 
on eli.id = ec.line_item_id

/*not sure if this is the table and what the column names will be*/
left join public.esh_service_providers esp 
on esp.service_provider_id = eli.service_provider_id

left join f
on f.flaggable_id = eli.id

left join t
on t.taggable_id = eli.id

left join r
on r.line_item_id = eli.id

where ec.funding_year = 2017
and eli.funding_year = 2017