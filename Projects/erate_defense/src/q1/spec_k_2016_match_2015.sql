with bi_2016 as (
  select 
    application_number,
    category_of_service,
    null as form471_url
  
  from fy2016.current_basic_informations 
  UNION
  select
    application_number,
    category_of_service,
    form471_url
  from fy2016.basic_informations 
  where application_number not in (
    select distinct application_number
    from fy2016.current_basic_informations
  )
),

frns_16 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  fli.function,
  fli.type_of_product,
  fli.total_monthly_eligible_recurring_costs,
  fli.total_eligible_one_time_costs
  
  from fy2016.frns frn
  
  left join fy2016.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2016.current_frns
  )
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item,
  fli.function,
  fli.type_of_product,
  fli.total_monthly_eligible_recurring_costs,
  fli.total_eligible_one_time_costs
  
  from fy2016.current_frns frn
  
  left join fy2016.current_frn_line_items fli
  on frn.frn = fli.frn

),

--final denied FRNs, to match to 2015 line items
final_2016 as (

select distinct
  fr.application_number,
  fr.frn,
  fr.frn_status,
  fr.review_status,
  fr.ben,
  fr.funding_year,
  fr.fcdl_comment_for_frn,
  fr.fcdl_comment_for_application,
  fr.application_status,
  bi16.category_of_service as category_of_service,
  frns_16.fiber_sub_type as fiber_sub_type,
  frns_16.total_monthly_eligible_recurring_costs,
  frns_16.total_eligible_one_time_costs,
  case when frns_16.function = 'Fiber' and type_of_product not in ('Dark Fiber IRU (No Special Construction)',
                                                       'Dark Fiber (No Special Construction)')
        then 'Lit Fiber'
        
        when frns_16.function = 'Fiber' AND type_of_product in ('Dark Fiber IRU (No Special Construction)',
                                                    'Dark Fiber (No Special Construction)')
          OR
            frns_16.function = 'Fiber Maintenance & Operations'
         then 'Dark Fiber'
        
        when frns_16.function = 'Wireless' AND type_of_product = 'Microwave'
         then 'Fixed Wireless'
        
        when frns_16.function = 'Copper' AND type_of_product = 'Cable Modem'
         then 'Cable'
                     
        when frns_16.function = 'Copper' AND type_of_product = 'Digital Subscriber Line (DSL)'
         then 'DSL'
                     
        when frns_16.function = 'Copper' AND type_of_product = 'T-1'
         then 'T-1'
                     
        when frns_16.function = 'Copper' AND type_of_product not in ('Cable Modem',
                                                        'Digital Subscriber Line (DSL)',
                                                        'T-1')
         then 'Other Copper'
                     
        when frns_16.function = 'Wireless' AND type_of_product in ('Satellite Service',
                                                      'Wireless data service',
                                                      'Data plan for portable device')
         then 'Satellite/LTE'
                     
        when li.isp_conditions_met = true
         then 'ISP Only'
        
        when frns_16.function is null then 'Not Broadband'
        
        else
         'Uncategorized'
  end as connect_category,
  li.id,
  li.applicant_ben,
  case when li.isp_conditions_met then 'ISP'
  when li.upstream_conditions_met then 'Upstream'
  when li.internet_conditions_met then 'Internet'
  when li.wan_conditions_met then 'WAN'
  when li.backbone_conditions_met then 'Backbone'
  end as purpose_adj,
  li.num_lines,
  fr.applicant_state,
  fr.applicant_zip_code,
  fr.ben_applicant_type,
  fr.ben_urban_rural_status
  
  
from public.funding_requests_2016_and_later fr

left join bi_2016 bi16
on fr.application_number = bi16.application_number

left join frns_16
on fr.frn = frns_16.frn

left join public.esh_line_items li
on frns_16.line_item = li.frn_complete

where  bi16.category_of_service::numeric = 1
  and fr.frn_status='Denied'),
  
frns_15 as (
select 
  c."Application Number" as application_number,
  c."FRN" as frn,
  concat(c."FRN", '-', c."FRN Line Item No") as frn_complete,
  c."Serv Type" as service_type,
  c."Serv/Conn Subtype" as type_of_product,
  null as function,
  c."Purpose" as purpose,
  c."IC/BMIC Make" as make,
  c."IC/BMIC Model" as model,
  null as other_manufacture,
  null as basic_firewall_protection,
  null as is_installation_included_in_price,
  c."Unit" as unit,
  c."C1 # of Lines" as monthly_quantity,
  null as one_time_quantity,
  c."Rec Elig Cost" as total_monthly_eligible_recurring_costs,
  c."Total Cost" - c."One-time Elig Cost" as total_eligible_recurring_costs,
  c."One-time Elig Cost" as total_eligible_one_time_costs,
  c."Lease/Purch" as lease_or_non_purchase_agreement,
  f."Serv Descrip" as narrative
from public.fy2015_item21_services_and_costs c
left join public.fy2015_funding_request_key_informations f
on c."FRN" = f."FRN"
where c."FRN" not in (
  select distinct "FRN"
  from fy2015.current_funding_request_key_informations
)
union
select 
  c."Application Number" as application_number,
  c."FRN" as frn,
  concat(c."FRN", '-', c."FRN Line Item No") as frn_complete,
  c."FRN Service Type" as service_type,
  c."Serv/Conn Subtype" as type_of_product,
  null as function,
  c."Purpose" as purpose,
  c."IC/BMIC Make" as make,
  c."IC/BMIC Model" as model,
  null as other_manufacture,
  null as basic_firewall_protection,
  null as is_installation_included_in_price,
  c."Unit" as unit,
  c."C1 # of Lines" as monthly_quantity,
  null as one_time_quantity,
  c."Rec Elig Cost" as total_monthly_eligible_recurring_costs,
  c."Total Cost" - c."One-time Elig Cost" as total_eligible_recurring_costs,
  c."One-time Elig Cost" as total_eligible_one_time_costs,
  c."Lease/Purch" as lease_or_non_purchase_agreement,
  f."Serv Descrip" as narrative
  
from fy2015.current_item21_services_and_costs c
left join fy2015.current_funding_request_key_informations f
on c."FRN" = f."FRN"),

final_2015 as (
select a.*, 
  ROW_NUMBER() OVER (PARTITION BY applicant_ben, purpose_adj, num_lines
  ORDER BY total_monthly_eligible_recurring_costs desc) as line_item_rank
from (
select distinct
  frns_15.frn,
  frns_15.total_monthly_eligible_recurring_costs,
  frns_15.total_eligible_one_time_costs,
  li.id,
  li.applicant_ben,
  case when li.isp_conditions_met then 'ISP'
  when li.upstream_conditions_met then 'Upstream'
  when li.internet_conditions_met then 'Internet'
  when li.wan_conditions_met then 'WAN'
  when li.backbone_conditions_met then 'Backbone'
  end as purpose_adj,
  li.num_lines

from frns_15

left join
public.esh_line_items li
on frns_15.frn_complete = li.frn_complete

left join 
public.line_items pli

on li.id = pli.id

where li.broadband=true
and li.funding_year=2015
and (not('exclude'=any(pli.open_flags)) or pli.open_flags is null)
) a
),

final_w_matches_2016 as (
select distinct final_2016.*,

case when final_2016.purpose_adj = final_2015.purpose_adj
and final_2016.applicant_ben = final_2015.applicant_ben
and final_2016.num_lines = final_2015.num_lines
and final_2016.line_item_rank = final_2015.line_item_rank
then 1 else 0 end as match,

case when final_2016.purpose_adj = final_2015.purpose_adj
and final_2016.applicant_ben = final_2015.applicant_ben
and final_2016.num_lines = final_2015.num_lines
and final_2016.line_item_rank = final_2015.line_item_rank
then final_2015.total_monthly_eligible_recurring_costs 
end as total_monthly_eligible_recurring_costs_15,

case when final_2016.purpose_adj = final_2015.purpose_adj
and final_2016.applicant_ben = final_2015.applicant_ben
and final_2016.num_lines = final_2015.num_lines
and final_2016.line_item_rank = final_2015.line_item_rank
then final_2015.total_eligible_one_time_costs 
end as total_eligible_one_time_costs_15

from (select f.*, 
ROW_NUMBER() OVER (PARTITION BY f.id
ORDER BY total_eligible_one_time_costs desc) as line_item_rank
from final_2016 f
join public.tags t
on f.id=t.taggable_id
where fiber_sub_type = 'Special Construction'
and t.label = 'special_construction_tag'
) final_2016

left join final_2015 
on final_2016.purpose_adj = final_2015.purpose_adj
and final_2016.applicant_ben = final_2015.applicant_ben
and final_2016.num_lines = final_2015.num_lines
and final_2016.line_item_rank = final_2015.line_item_rank
)

select distinct f.* from final_w_matches_2016 f
--Desoto
--where application_number = '161012491'