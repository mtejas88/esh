/*
Author: Greg Kurzhals
Created On Date: 05/23/2015
Last Modified Date: 7/26/2016 (Justine)
Name of QAing Analyst(s): N/A
Purpose: To verify that the flags are being populated in the manner anticipated by SAT and to surface any discrepancies
Methodology: Each flag has its own subqueries, and all subqueries are aggregated in the end with a comparison field
*/

with li_recipients as (
          select li.id,
          li.applicant_id,
          li.num_lines,
          count(distinct allocations.recipient_id) as "num_recipients"
          
          from fy2016.line_items li
          
          left join fy2016.allocations
          on li.id=allocations.line_item_id

          left join fy2016.frn_line_items
          on li.frn_complete=frn_line_items.line_item

          left join fy2016.frns
          on fy2016.frn_line_items.frn=fy2016.frns.frn
          
          GROUP BY li.id, li.applicant_id, li.num_lines
),

fiber_maintenance_query as (

select li.id,
case when frn_line_items.function = 'Fiber Maintenance & Operations'
			and (li.isp_conditions_met = true or li.internet_conditions_met = true )
then true
else false
end as "fiber_maintenance"

from fy2016.line_items li
left join fy2016.frn_line_items
on li.id=frn_line_items.id

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn 

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

consortium_shared_query as (

select li_recipients.id,

--1) ratio of num_recipients to num_lines is at least 3:1
case when li_recipients.num_lines!='Unknown' 
and li_recipients.num_lines::numeric!=0 and li_recipients.num_recipients::numeric/li_recipients.num_lines::numeric>=3
  
  --2) applicant is not considered a district or a school within the ESH classification system
  and
    li_recipients.applicant_id not in (
    select esh_id
    from fy2016.districts
    where include_in_universe_of_districts=true)
    and li_recipients.applicant_id not in (
    select esh_id
    from fy2016.schools)
    
then true else false end as "consortium_shared"

from li_recipients),

flipped_speed_query as (

select line_items.id,
case when line_items.broadband=true
and 
  case when upload_speed_units='Gbps'
  then frn_line_items.upload_speed::numeric*1000 
  else frn_line_items.upload_speed::numeric end>
  line_items.bandwidth_in_mbps 
then true
else false
end as "flipped_speed",
line_items.bandwidth_in_mbps,
frn_line_items.download_speed,
frn_line_items.download_speed_units,
frn_line_items.upload_speed,
frn_line_items.upload_speed_units

from fy2016.line_items

left join fy2016.frn_line_items
on fy2016.line_items.id=fy2016.frn_line_items.id
),

/*function_conn_type_mismatch_query as (

select li.id,
case when  
(frn_line_items.function='Fiber'
and frn_line_items.type_of_product not in (
'Dark Fiber (No Special Construction)'
'Dark Fiber IRU (No Special Construction)',
'OC-1',
'OC-3',
'OC-12',
'OC-24',
'OC-488',
'OC-192',
'OC-256',
'OC-768',
'Switched Multimegabit Data Service',
'OC-N (TDM Fiber)',
'Ethernet',
'MPLS'))

OR

(frn_line_items.function='Copper'
and frn_line_items.type_of_product not in (
'Ethernet',
'ATM',
'ISDN-BRI',
'Cable Modem',
'T-1',
'T-3',
--removed based on assumption that selection of 'T-4' and 'T-5' indicative of a potential data quality error?
'T-4',
'T-5',

'Digital Subscriber Line (DSL)',
'Fractional T-1',
'Frame Relay'))

OR

(frn_line_items.function='Wireless' 
and frn_line_items.type_of_product not in (
'Microwave',
'Satellite Service',
'Data plan for portable device',
'Wireless data service'))

OR (frn_line_items.function='Miscellaneous'
and frn_line_items.type_of_product in (
'DS-1',
'DS-3',
'DS-4',
'Dark Fiber (No Special Construction)',
'Dark Fiber IRU (No Special Construction)',
'OC-1',
'OC-3',
'OC-12',
'OC-24',
'OC-488',
'OC-192',
'OC-256',
'OC-768',
'Switched Multimegabit Data Service',
'OC-N (TDM Fiber)',
'Digital Subscribe Line (DSL)',
'Ethernet',
'MPLS',
'ATM',
'ISDN-BRI',
'Cable Modem',
'T-1',
'T-3',
'T-4',
'T-5',
'Digital Subscriber Line (DSL)',
'Fractional T-1',
'Frame Relay',
'Microwave',
'Satellite Service',
'Data plan for portable device',
'Wireless data service',
'Broadband Over Power Lines',
'Radio Loop'))
then true
else false
end as "function_conn_type_mismatch"

from fy2016.frn_line_items

left join fy2016.line_items li
on frn_line_items.line_item=li.frn_complete

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn 

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),
*/
not_bundled_ia_query as (
select li.id,
li.frn_complete,
case when 
--updated logic for internet_conditions_met
(frn_line_items.purpose = 'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider' 
and li.consortium_shared = false)
and li.num_lines!='Unknown'
and frn_line_items.type_of_product not in ('Data plan for portable device', 'Wireless data service')
and ((frn_line_items.type_of_product='T-1'
    and li.num_lines::numeric>= 6)
    OR (frn_line_items.type_of_product!='T-1'
    and li.num_lines::numeric>=3))
then true
else false
end as "not_bundled_ia"

from fy2016.line_items li
left join fy2016.frn_line_items
on li.id=frn_line_items.id

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn 

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

not_isp_query as (
select li.id,
li.frn_complete,
--updated logic for isp_conditions_met
case when 
(frn_line_items.purpose = 'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)' 
or ( frn_line_items.purpose = 'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider' 
  and li.consortium_shared = true ))
and
--flags any line item where num_lines>1
      (li.num_lines!='Unknown' and li.num_lines::numeric>1)

then true
else false
end as "not_isp"

from fy2016.line_items li
left join fy2016.frn_line_items
on li.id=frn_line_items.id

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn 

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

not_upstream_query as (
select li.id,
li.frn_complete,
case when 
li.purpose='Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately'

--flags anything with purpose specified as "upstream" that is not over fiber/fixed wireless
and (
      (
        frn_line_items.function in ('Copper', 'Other', 'Miscellaneous')
      OR
        frn_line_items.type_of_product in ('Satellite Service', 'Data plan for portable device', 'Wireless data service') 
      )
    OR
--flags any line item where num_lines>2
      (li.num_lines!='Unknown' and li.num_lines::numeric>2)
    )

then true
else false
end as "not_upstream"

from fy2016.line_items li
left join fy2016.frn_line_items
on li.id=frn_line_items.id

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn 

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

not_wan_query as (
select li.id,

--old wan_product flag
case when 
--updated wan_conditions_met_logic
  (frn_line_items.purpose='Data Connection between two or more sites entirely within the applicant’s network'
   and li.consortium_shared = false)
and 
  (
    frn_line_items.type_of_product in ('Cable Modem', 'Digital Subscriber Line (DSL)')
    OR 
    --asymmetrical bandwidth
    (case when frn_line_items.upload_speed_units='Gbps'
    then frn_line_items.upload_speed::numeric*1000 
    else frn_line_items.upload_speed::numeric end<
    case when frn_line_items.download_speed_units='Gbps'
    then frn_line_items.download_speed::numeric*1000 
    else frn_line_items.download_speed::numeric end))
    then true else false end as "not_wan"

from fy2016.frn_line_items

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn

left join fy2016.line_items li
on fy2016.frn_line_items.id=li.id

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

extreme_one_time_cost_query as (
select line_items.id,
line_items.frn,
case when frn_line_items.pre_discount_extended_eligible_line_item_cost::numeric>0
and
  --flags any line item where at least 10% of the total cost is represented by one-time costs
  (
    (frn_line_items.total_eligible_recurring_costs::numeric>0
    and frn_line_items.total_eligible_one_time_costs::numeric>=
    0.1*frn_line_items.pre_discount_extended_eligible_line_item_cost::numeric
    )
  --flags any line item where the only cost is represented by one-time cost
  OR
    (frn_line_items.total_eligible_recurring_costs::numeric=0
    and frn_line_items.total_eligible_one_time_costs::numeric>0
    )
  )
then true
else false
end as "extreme_one_time_cost"

from fy2016.frn_line_items

left join fy2016.line_items
on fy2016.line_items.id=fy2016.frn_line_items.id

left join fy2016.frns
on fy2016.line_items.frn=fy2016.frns.frn

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS')
),

product_bandwidth_query as (
select li.id,
case when 
        (--(
        frn_line_items.function='Fiber'
        --OR 'assumed_fiber'=any(open_flags))
        and 
        case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end<20)
    OR 
        (frn_line_items.function='Copper'
        and frn_line_items.type_of_product='Digital Subscriber Line (DSL)'
        and 
        case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>40)
    OR
        (frn_line_items.type_of_product='Fractional T-1'
        and
        case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>=1.5)
    OR 
        (frn_line_items.type_of_product='Cable Modem'
        and
        case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>150)
    
    OR 
        (frn_line_items.function='Copper'
        and frn_line_items.type_of_product not in ('Digital Subscriber Line (DSL)',
        'T-3',	 
        'T-4',	 
        'T-5',
        'Cable Modem')
        and 
        case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>25)
        
    OR (frn_line_items.function='Wireless'
    and frn_line_items.type_of_product='Microwave'
    and case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>200)
        
    OR (frn_line_items.function='Wireless'
    and frn_line_items.type_of_product='Satellite Service'
    and case when frn_line_items.download_speed_units='Gbps'
        then frn_line_items.download_speed::numeric*1000
        else frn_line_items.download_speed::numeric end>20)
    then true else false end as "product_bandwidth"

from fy2016.frn_line_items

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn

left join fy2016.line_items li
on fy2016.frn_line_items.id=li.id

--updated js 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

unknown_conn_type_query as (
select li.id,

case when frn_line_items.type_of_product in ('ATM',
    'ISDN-BRI',
    'T-4',
    'T-5',
    'Frame Relay',
    'Satellite Service',
    'Data plan for portable device',
    'Wireless data service',
    'Broadband Over Power Lines',
    'Radio Loop',
    'Other',
    'DS-1',
    'DS-3',
    'DS-4',
    'OC-256',
    'OC-768',
    'Fractional T-1')
     
then true else false end as "unknown_conn_type"

from fy2016.frn_line_items

left join fy2016.frns
on fy2016.frn_line_items.frn=fy2016.frns.frn

left join fy2016.line_items li
on fy2016.frn_line_items.id=li.id

--js updated 7/28
where frns.service_type='Data Transmission and/or Internet Access'
and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
),

unknown_quantity_query as (
select id,
          case
          	when num_lines::varchar = 'Unknown'
          	  then true
          	else
          	  false
          end as unknown_quantity
  from fy2016.line_items 
  where broadband = true
),

charter_service_query as (
select  line_items.id,
          case
          	when charter = true or district_type = '7 Charter Agency'
          	  then true
          	else
          	  false
          end as charter_service
  from fy2016.line_items 
  left join fy2016.schools
  on line_items.applicant_id = schools.esh_id
  left join fy2016.districts
  on line_items.applicant_id = districts.esh_id
  where broadband = true),
  
--allocations_mismatch
  
line_item_allocations as (
  select  ros.line_item,
          sum( case
                  when quantity is not null
                    then quantity::numeric
                    else 0
                end) as quantity_allocations,
          count(distinct case
                        when campus_id is not null
                          then campus_id
                      end) as campus_allocations,
          count(distinct ros.id) as entity_allocations
  from (
      select distinct line_item, quantity, ben, id
      from fy2016.recipients_of_services
  ) ros
  left join public.entity_bens eb
  on ros.ben = eb.ben
  left join public.districts_schools ds
  on eb.entity_id = ds.school_id
  group by ros.line_item
),
/*
line_item_allocations as (
  select  a.frn_complete,
          sum( case
                  when num_lines_to_allocate is not null
                    then num_lines_to_allocate::numeric
                    else 0
                end) as quantity_allocations,
          count(distinct case
                        when campus_id is null
                          then a.recipient_ben::varchar
                          else campus_id
                      end) as campus_allocations,
          count(*) as entity_allocations
  from fy2016.allocations a
  left join public.entity_bens eb
  on a.recipient_ben::varchar = eb.ben
  left join public.districts_schools ds
  on a.recipient_id = ds.school_id
  group by a.frn_complete
),
*/
allocations_mismatch_query as (

select  li.frn_complete, 
         case
           when wan_conditions_met = true and num_lines != 'Unknown'
           then 
              case when quantity_allocations = 0 
              and campus_allocations = 0
              and entity_allocations = 0
              then true
              when quantity_allocations = num_lines::numeric
              or quantity_allocations - 1 = num_lines::numeric
              or  (case
                    when quantity_allocations = 0
                      then false
                      else num_lines::numeric % quantity_allocations = 0
                    end)
              or campus_allocations = num_lines::numeric
              or campus_allocations - 1 = num_lines::numeric
              or  (case
                    when campus_allocations = 0
                      then false
                      else num_lines::numeric % campus_allocations = 0
                    end)
              or entity_allocations = num_lines::numeric
              or entity_allocations - 1 = num_lines::numeric
              or  (case
                 when entity_allocations = 0
                   then false
                   else num_lines::numeric % entity_allocations = 0
               end)
             then false
           else
             true
       end
       else false end as allocations_mismatch
              
from fy2016.line_items li
join line_item_allocations lia
on li.frn_complete = lia.line_item

--left join frn_line_items
--on li.frn_complete=frn_line_items.line_item

where li.broadband=true),
  
comparison as (

select li.id,

case when 'fiber_maintenance'=any(flag_table.open_flags)
then true else false end as "fiber_maintenance_staging",
fiber_maintenance_query.fiber_maintenance as "fiber_maintenance_query",

li.consortium_shared as "consortium_shared_staging",
consortium_shared_query.consortium_shared as "consortium_shared_query",

case when 'flipped_speed'=any(flag_table.open_flags)
then true else false end as "flipped_speed_staging",
flipped_speed_query.flipped_speed as "flipped_speed_query",

/*case when 'function_conn_type_mismatch'=any(li.open_flag_labels)
then true else false end as "function_conn_type_mismatch_staging",
function_conn_type_mismatch_query.function_conn_type_mismatch,
*/
case when 'not_bundled_ia'=any(flag_table.open_flags)
then true else false end as "not_bundled_ia_staging",
not_bundled_ia_query.not_bundled_ia as "not_bundled_ia_query",

case when 'not_isp'=any(flag_table.open_flags)
then true else false end as "not_isp_staging",
not_isp_query.not_isp as "not_isp_query",

case when 'not_upstream'=any(flag_table.open_flags)
then true else false end as "not_upstream_staging",
not_upstream_query.not_upstream as "not_upstream_query",

case when 'not_wan'=any(flag_table.open_flags)
then true else false end as "not_wan_staging",
not_wan_query.not_wan as "not_wan_query",

case when 'product_bandwidth'=any(flag_table.open_flags)
then true else false end as "product_bandwidth_staging",
product_bandwidth_query.product_bandwidth as "product_bandwidth_query",

case when 'unknown_conn_type'=any(flag_table.open_flags)
then true else false end as "unknown_conn_type_staging",
unknown_conn_type_query.unknown_conn_type as "unknown_conn_type_query",

case when 'unknown_quantity'=any(flag_table.open_flags)
then true else false end as "unknown_quantity_staging",
unknown_quantity_query.unknown_quantity as "unknown_quantity_query",

case when 'charter_service'=any(tag_table.open_tags)
then true else false end as "charter_service_staging",
charter_service_query.charter_service as "charter_service_query",

case when 'extreme_one_time_cost'=any(tag_table.open_tags)
then true else false end as "extreme_one_time_cost_staging",
extreme_one_time_cost_query.extreme_one_time_cost as "extreme_one_time_cost_query",

case when 'allocations_mismatch'=any(flag_table.open_flags)
then true else false end as "allocations_mismatch_staging",
allocations_mismatch_query.allocations_mismatch as "allocations_mismatch_query",

li.open_flag_labels,
flag_table.open_flags,
li.open_tag_labels,
tag_table.open_tags

from fy2016.line_items li

left join fiber_maintenance_query
on li.id=fiber_maintenance_query.id

left join consortium_shared_query
on li.id=consortium_shared_query.id

left join flipped_speed_query
on li.id=flipped_speed_query.id

/*left join function_conn_type_mismatch_query
on li.id=function_conn_type_mismatch_query.id
*/

left join not_bundled_ia_query
on li.id=not_bundled_ia_query.id

left join not_isp_query
on li.id=not_isp_query.id

left join not_upstream_query
on li.id=not_upstream_query.id

left join not_wan_query
on li.id=not_wan_query.id

left join product_bandwidth_query
on li.id=product_bandwidth_query.id

left join unknown_conn_type_query
on li.id=unknown_conn_type_query.id

left join unknown_quantity_query
on li.id=unknown_quantity_query.id

left join charter_service_query
on li.id=charter_service_query.id

left join extreme_one_time_cost_query
on li.id=extreme_one_time_cost_query.id

left join allocations_mismatch_query
on li.frn_complete=allocations_mismatch_query.frn_complete

left join lateral (
select flaggable_id,
array_agg(label) as "open_flags"

from fy2016.flags

where flaggable_type='LineItem'
and status='open'

GROUP BY flaggable_id
) flag_table
on li.id=flag_table.flaggable_id

left join lateral (
select taggable_id,
array_agg(label) as "open_tags"

from fy2016.tags

where taggable_type='LineItem'
and deleted_at is null

GROUP BY taggable_id) tag_table
on li.id=tag_table.taggable_id)

select id,
fiber_maintenance_staging,
fiber_maintenance_query,
case when fiber_maintenance_staging!=fiber_maintenance_query
then 'Different' else 'Same' end as "fiber_maintenance_comparison",

consortium_shared_staging,
consortium_shared_query,
case when consortium_shared_staging!=consortium_shared_query
then 'Different' else 'Same' end as "consortium_shared_comparison",

flipped_speed_staging,
flipped_speed_query,
case when flipped_speed_staging!=flipped_speed_query
then 'Different' else 'Same' end as "flipped_speed_comparison",

product_bandwidth_staging,
product_bandwidth_query,
case when product_bandwidth_staging!=product_bandwidth_query
then 'Different' else 'Same' end as "product_bandwidth_comparison",

not_bundled_ia_staging,
not_bundled_ia_query,
case when not_bundled_ia_staging!=not_bundled_ia_query 
then 'Different' else 'Same' end as "not_bundled_ia_comparison",

not_isp_staging,
not_isp_query,
case when not_isp_staging!=not_isp_query
then 'Different' else 'Same' end as "not_isp_comparison",

not_upstream_staging,
not_upstream_query,
case when not_upstream_staging!=not_upstream_query
then 'Different' else 'Same' end as "not_upstream_comparison",

not_wan_staging,
not_wan_query,
case when not_wan_staging!=not_wan_query
then 'Different' else 'Same' end as "not_wan_comparison",

unknown_conn_type_staging,
unknown_conn_type_query,
case when unknown_conn_type_staging!=unknown_conn_type_query
then 'Different' else 'Same' end as "unknown_conn_type_comparison",

unknown_quantity_staging,
unknown_quantity_query,
case when unknown_quantity_staging!=unknown_quantity_query
then 'Different' else 'Same' end as "unknown_quantity_comparison",

charter_service_staging,
charter_service_query,
case when charter_service_staging!=charter_service_query
then 'Different' else 'Same' end as "charter_service_comparison",

extreme_one_time_cost_staging,
extreme_one_time_cost_query,
case when extreme_one_time_cost_staging!=extreme_one_time_cost_query
then 'Different' else 'Same' end as "extreme_one_time_cost_comparison",

allocations_mismatch_staging,
allocations_mismatch_query,
case when allocations_mismatch_staging!=allocations_mismatch_query
then 'Different' else 'Same' end as "allocations_mismatch_comparison",

array_to_string(open_flag_labels, ',') as "open_flag_labels",
array_to_string(open_flags, ',') as "open_flags",
array_to_string(open_tag_labels, ',') as "open_tag_labels",
array_to_string(open_tags, ',') as "open_tags"

from comparison

--broadband line items only (updated 7/28 JS)
where comparison.id in (
        select line_items.id
        from fy2016.line_items
        
        left join fy2016.frn_line_items
        on line_items.frn_complete=frn_line_items.line_item
        
        left join fy2016.frns
        on line_items.frn=frns.frn

        where frns.service_type='Data Transmission and/or Internet Access'
          and frn_line_items.function not in ('Cabinets', 'Cabling', 'Conduit', 'Connectors/Couplers', 
          'Patch Panels', 'Routers', 'Switches', 'UPS', 'Miscellaneous')
        )
--LIMIT 1000




