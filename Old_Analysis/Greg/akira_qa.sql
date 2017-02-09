/*
Author: Greg Kurzhals
Created On Date: 05/23/2015
Last Modified Date: 7/26/2016 (Justine)
Name of QAing Analyst(s): N/A
Purpose: To verify that the line_items table is being populated in the manner anticipated by SAT and to surface any discrepancies

Methodology: The query recreates the fields in the "line_items" table using "raw" data imported from USAC.  For fields that require more than the direct
appropriation of "raw" values (e.g. ESH-created metadata fields like "consortium_shared" or "num_lines"), the query also compares whether the values
currently found in the line_items table correspond to the values calculated by the query, and returns the results of that comparison in a separate field.
*/

with raw_data as (
select frn_line_items.id as "id_query",
frn_line_items.line_item as "frn_complete_query",
frn_line_items.frn as "frn_query",
--RIGHT(frn_line_items.line_item, 3) as "frn_line_item_no_query",
frn_line_items.application_number as "application_number_query",

--although the name is different, I believe that this is the 2016 equivalent of USAC's application_type
basic_informations.applicant_type as "application_type_query",
basic_informations.billed_entity_number as "applicant_ben_query",
entity_bens.entity_id as "applicant_id_query",
entity_bens.entity_type as "applicant_type_query",
basic_informations.billed_entity_name as "applicant_name_query",

--could also potentially pull from "postal_cd" field in the basic_informations table
basic_informations.billed_entity_state as "applicant_postal_cd_query",
--frns.service_provider_number as "service_provider_id",
public.service_providers.id as "service_provider_id_query",
frns.service_provider_name as "service_provider_name_query",
frns.service_type as "service_type_query",
basic_informations.category_of_service as "service_category_query",
frn_line_items.function as "function_query",
frn_line_items.type_of_product as "connect_type_query",

case when 
        --placeholder for broadband=true (js update 7/26)
        frns.service_type='Data Transmission and/or Internet Access' 
        and frn_line_items.function not in ('Miscellaneous', 'Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
        'Patch Panels', 'Routers', 'Switches', 'UPS')
        
        then
            (case
                when function='Fiber' and type_of_product not in (
                'Dark Fiber IRU (No Special Construction)', 'Dark Fiber (No Special Construction)')
                then 'Lit Fiber'
                when (function='Fiber' and type_of_product in ('Dark Fiber IRU (No Special Construction)', 'Dark Fiber (No Special Construction)'))
                      or function = 'Fiber Maintenance & Operations'
                then 'Dark Fiber'
                when function='Wireless' and type_of_product='Microwave'
                then 'Fixed Wireless'
                when function='Copper' and type_of_product='Cable Modem'
                then 'Cable'
                when function='Copper' and type_of_product='Digital Subscriber Line (DSL)'
                then 'DSL'
                when function='Copper' and type_of_product='T-1'
                then 'T-1'
                when function='Copper' and type_of_product not in ('Cable Modem', 'Digital Subscriber Line (DSL)', 'T-1')
                then 'Other Copper'
                when function='Wireless' and type_of_product in ('Satellite Service', 'Wireless data service', 'Data plan for portable device')
                then 'Satellite/LTE'
                else 'Uncategorized' end
            )
        else 
          'Not Broadband'
        end as "connect_category_query",

frn_line_items.purpose as "purpose_query",

--'Remove field' as "wan_query",

case when frn_line_items.download_speed_units='Gbps'
then frn_line_items.download_speed::numeric*1000
else frn_line_items.download_speed::numeric
end as "bandwidth_in_mbps_query",
concat(frn_line_items.download_speed, ' ', frn_line_items.download_speed_units) as "bandwidth_in_original_units_query",

case when frn_line_items.upload_speed_units='Gbps'
then frn_line_items.upload_speed::numeric*1000
else frn_line_items.upload_speed::numeric
end as "upload_bandwidth_in_mbps_query",

case when 
    (frn_line_items.one_time_quantity != frn_line_items.monthly_quantity
    and frn_line_items.one_time_quantity::numeric>0)
    or frn_line_items.monthly_quantity='0' 
    then 'Unknown' 
  else frn_line_items.monthly_quantity end as "num_lines_query",
  
(frn_line_items.total_monthly_eligible_recurring_costs::numeric*
months_of_service::numeric) + total_eligible_one_time_costs::numeric as "total_cost_query",

pre_discount_extended_eligible_line_item_cost::numeric as "total_cost_test_query",

frn_line_items.total_eligible_one_time_costs::numeric as "one_time_elig_cost_query",

frn_line_items.total_monthly_eligible_recurring_costs::numeric as "rec_elig_cost_query",

--alternatively, frns.total_number_of_months_of_service
frn_line_items.months_of_service as "months_of_service_query",

frns.contract_expiry_date as "contract_end_date_query",

flag_table.num_open_flags as "num_open_flags",
flag_table.open_flags as "open_flag_labels_query",
tag_table.open_tags as "open_tag_labels_query",

--see "recipients" sub-query below
recipients.num_recipients as "num_recipients_query",

--'ESH-generated' as "erate_query",

--js update 7/26
case when frns.service_type='Data Transmission and/or Internet Access' 
and frn_line_items.function not in ('Miscellaneous', 'Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS')
then true else false end as "broadband_query"


--'ESH-generated' as "consortium_shared_query",


--conditions_met metadata fields - commented-out sections reflect additional logic that we may be building in once additional flags are implemented
/*case when frn_line_items.purpose='Internet access service that includes a connection from any applicant site directly to the Internet Service Provider'
OR
'assumed_internet'=any(open_flags)
OR 
(purpose='Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)'
and 'assumed_fiber'=any(open_flags))
then true 
else false 
end as "internet_conditions_met_query",

case when frn_line_items.purpose='Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately'
then true else false end as "upstream_conditions_met_query",

case when frn_line_items.purpose='Data Connection between two or more sites entirely within the applicant’s network'
or 'assumed_wan'=any(open_flags)
then true
else false end as "wan_conditions_met",

case when purpose='Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately'

then true
else false end as "wan_conditions_met_query",

case when 

(purpose='Data Connection between two or more sites entirely within the applicant’s network'
  and 
    (consortium_shared=true
    OR 
    'backbone'=any(open_flags)
    )
)
OR frn_line_items.purpose='Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities'
then true
else false end as "backbone_conditions_met_query",*/

--'ESH-generated' as "exclude_query"

--now in Akira table: upload_bandwidth_in_mbps, backbone_conditions_met, function

from fy2016.frn_line_items 

left join fy2016.basic_informations
on fy2016.frn_line_items.application_number=fy2016.basic_informations.application_number

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn

left join public.service_providers
on fy2016.frns.service_provider_name=public.service_providers.name

left join public.entity_bens
on fy2016.basic_informations.billed_entity_number=public.entity_bens.ben

left join lateral (
select line_item,
count(distinct "ben") as "num_recipients"

from fy2016.recipients_of_services 
GROUP BY line_item) recipients
on frn_line_items.line_item=recipients.line_item

left join lateral (
select flaggable_id,
array_agg(label) as "open_flags",
count(*) as "num_open_flags"

from fy2016.flags

where flaggable_type='LineItem'
and status='open'

GROUP BY flaggable_id
) flag_table
on frn_line_items.id=flag_table.flaggable_id

left join lateral (
select taggable_id,
array_agg(label) as "open_tags"

from fy2016.tags

where taggable_type='LineItem'
and deleted_at is null

GROUP BY taggable_id) tag_table
on frn_line_items.id=tag_table.taggable_id

ORDER BY frn_line_items.id),

consortium_shared as (

select *,
case when num_lines_query!='Unknown'
and broadband_query=true
and num_recipients_query/num_lines_query::numeric>=3.0
and applicant_type_query not in ('School', 'District')
then true else false end as "consortium_shared_query",

case when frn_query is not null then true else false end as "erate_query",

case when num_open_flags is null then 0
else num_open_flags end as "num_open_flags_query"

from raw_data),

query_table as (

select *,

case when 
(cs.purpose_query = 'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)' 
or (cs.purpose_query = 'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider' 
  and cs.consortium_shared_query = true))

--and not('assumed_fiber'=any(open_flags))
then true
else false
end as "isp_conditions_met_query",


--conditions_met metadata fields - commented-out sections reflect additional logic that we may be building in once additional flags are implemented
case when (cs.purpose_query='Internet access service that includes a connection from any applicant site directly to the Internet Service Provider' 
and cs.consortium_shared_query=false)
then true 
else false 
end as "internet_conditions_met_query",

case when cs.purpose_query='Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately'
then true else false end as "upstream_conditions_met_query",

case when (cs.purpose_query='Data Connection between two or more sites entirely within the applicant’s network'
   and cs.consortium_shared_query=false)
then true
else false end as "wan_conditions_met_query",

case when cs.purpose_query='Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities' 
or (cs.consortium_shared_query=true 
and cs.purpose_query='Data Connection between two or more sites entirely within the applicant’s network')
then true else false end as "backbone_conditions_met_query",

case when cs.consortium_shared_query=true
OR
cs.num_open_flags_query>0
then true else false end as "exclude_query"

from consortium_shared cs)

select id,
frn_complete,
frn,
application_number,

li.application_type,
qt.application_type_query,

case when li.application_type!=qt.application_type_query
then 'Different' else 'Same' end as "application_type_comparison",

li.applicant_ben,
qt.applicant_ben_query,
case when li.applicant_ben::varchar!=qt.applicant_ben_query
then 'Different' else 'Same' end as "applicant_ben_comparison",


li.applicant_id,
qt.applicant_id_query,
case when li.applicant_id!=qt.applicant_id_query
then 'Different' else 'Same' end as "applicant_id_comparison",

li.applicant_type,
qt.applicant_type_query,
case when li.applicant_type!=qt.applicant_type_query
then 'Different' else 'Same' end as "applicant_type_comparison",


li.applicant_name,
qt.applicant_name_query,
case when li.applicant_name!=qt.applicant_name_query
then 'Different' else 'Same' end as "applicant_name_comparison",

li.applicant_postal_cd,
qt.applicant_postal_cd_query,
case when li.applicant_postal_cd!=qt.applicant_postal_cd_query
then 'Different' else 'Same' end as "applicant_postal_cd_comparison",

li.service_provider_id,
qt.service_provider_id_query,
case when li.service_provider_id!=qt.service_provider_id_query
then 'Different' else 'Same' end as "service_provider_id_comparison",

li.service_provider_name,
qt.service_provider_name_query,
case when li.service_provider_name!=qt.service_provider_name_query
then 'Different' else 'Same' end as "service_provider_name_comparison",

li.service_type,
qt.service_type_query,
case when li.service_type!=qt.service_type_query
then 'Different' else 'Same' end as "service_type_comparison",

li.service_category,
qt.service_category_query,
case when li.service_category!=qt.service_category_query
then 'Different' else 'Same' end as "service_category_comparison",

li.function,
qt.function_query,
case when li.function!=qt.function_query
then 'Different' else 'Same' end as "function_comparison",

li.connect_type,
qt.connect_type_query,
case when li.connect_type!=qt.connect_type_query
then 'Different' else 'Same' end as "connect_type_comparison",

li.connect_category,
case
	when qt.isp_conditions_met_query = true
		then 'ISP only'
	else qt.connect_category_query
end as connect_category_query,
case when li.connect_category!=	case
									when qt.isp_conditions_met_query = true
										then 'ISP only'
									else qt.connect_category_query
								end
then 'Different' else 'Same' end as "connect_category_comparison",

li.purpose,
qt.purpose_query,
case when li.purpose!=qt.purpose_query
then 'Different' else 'Same' end as "purpose_comparison",

li.bandwidth_in_mbps,
qt.bandwidth_in_mbps_query,
case when li.bandwidth_in_mbps!=qt.bandwidth_in_mbps_query
then 'Different' else 'Same' end as "bandwidth_in_mbps_comparison",

li.bandwidth_in_original_units,
qt.bandwidth_in_original_units_query,
case when li.bandwidth_in_original_units!=qt.bandwidth_in_original_units_query
then 'Different' else 'Same' end as "bandwidth_in_original_units_comparison",

li.upload_bandwidth_in_mbps,
qt.upload_bandwidth_in_mbps_query,
case when li.upload_bandwidth_in_mbps!=qt.upload_bandwidth_in_mbps_query
then 'Different' else 'Same' end as "upload_bandwidth_in_mbps_comparison",

li.num_lines,
qt.num_lines_query,
case when li.num_lines!=qt.num_lines_query
then 'Different' else 'Same' end as "num_lines_comparison",

li.total_cost,
qt.total_cost_query,
case when li.total_cost!=qt.total_cost_query
then 'Different' else 'Same' end as "total_cost_comparison",

li.one_time_elig_cost,
qt.one_time_elig_cost_query,
case when li.one_time_elig_cost!=qt.one_time_elig_cost_query
then 'Different' else 'Same' end as "one_time_elig_cost_comparison",

li.rec_elig_cost,
qt.rec_elig_cost_query,
case when li.rec_elig_cost!=qt.rec_elig_cost_query
then 'Different' else 'Same' end as "rec_elig_cost_comparison",

li.months_of_service,
qt.months_of_service_query,
case when li.months_of_service!=qt.months_of_service_query::numeric
then 'Different' else 'Same' end as "months_of_service_comparison",

li.contract_end_date,
qt.contract_end_date_query,

li.num_open_flags,
qt.num_open_flags_query,
case when li.num_open_flags!=qt.num_open_flags_query
then 'Different' else 'Same' end as "num_open_flags_comparison",

li.open_flag_labels,
qt.open_flag_labels_query,

li.open_tag_labels,
qt.open_tag_labels_query,

li.num_recipients,
qt.num_recipients_query,
case when li.num_recipients!=qt.num_recipients_query
then 'Different' else 'Same' end as "num_recipients_comparison",

li.broadband,
qt.broadband_query,
case when li.broadband!=qt.broadband_query
then 'Different' else 'Same' end as "broadband_comparison",

li.consortium_shared,
qt.consortium_shared_query,
case when li.consortium_shared!=qt.consortium_shared_query
then 'Different' else 'Same' end as "consortium_shared_comparison",

li.erate,
qt.erate_query,
case when li.erate!=qt.erate_query
then 'Different' else 'Same' end as "erate_comparison",

li.isp_conditions_met,
qt.isp_conditions_met_query,
case when li.isp_conditions_met!=qt.isp_conditions_met_query
then 'Different' else 'Same' end as "isp_conditions_met_comparison",

li.internet_conditions_met,
qt.internet_conditions_met_query,
case when li.internet_conditions_met!=qt.internet_conditions_met_query
then 'Different' else 'Same' end as "internet_conditions_met_comparison",

li.upstream_conditions_met,
qt.upstream_conditions_met_query,
case when li.upstream_conditions_met!=qt.upstream_conditions_met_query
then 'Different' else 'Same' end as "upstream_conditions_met_comparison",

li.wan_conditions_met,
qt.wan_conditions_met_query,
case when li.wan_conditions_met!=qt.wan_conditions_met_query
then 'Different' else 'Same' end as "wan_conditions_met_comparison",

li.backbone_conditions_met,
qt.backbone_conditions_met_query,
case when li.backbone_conditions_met!=qt.backbone_conditions_met_query
then 'Different' else 'Same' end as "backbone_conditions_met_comparison",

li.exclude,
qt.exclude_query,
case when li.exclude!=qt.exclude_query
then 'Different' else 'Same' end as "exclude_comparison"

from fy2016.line_items li

join query_table qt
on li.frn_complete=qt.frn_complete_query

/*left join fy2016.frn_line_items fl
on li.frn_complete=fl.line_item*/



