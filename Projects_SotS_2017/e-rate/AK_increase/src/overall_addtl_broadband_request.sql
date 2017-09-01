with frns_2017 as (
  select *
  from fy2017.frns 
  where frn not in (
    select frn
    from fy2017.current_frns 
  )

  UNION

  select *
  from fy2017.current_frns 
  where frn_status not in ('Denied', 'Cancelled')
),

frn_line_items_2017 as (
  select *
  from fy2017.frn_line_items 
  where line_item not in (
    select line_item
    from fy2017.current_frn_line_items 
  )

  UNION

  select cfli.*
  from fy2017.current_frn_line_items cfli
  join fy2017.current_frns cfrns 
  on cfli.frn = cfrns.frn 
  where frn_status not in ('Denied', 'Cancelled')
),

basic_informations_2017 as (
  select *
  from fy2017.basic_informations 
  where application_number not in (
    select application_number
    from fy2017.current_basic_informations 
  )

  UNION

  select cbi.*
  from fy2017.current_basic_informations cbi
  join fy2017.current_frns cfrns 
  on cbi.application_number = cfrns.application_number 
  where frn_status not in ('Denied', 'Cancelled')
)

select
  'services not received or excluded' as category,
  case
    when bi.applicant_type not ilike '%library%' and bi.billed_entity_name ilike '%library%'
      then 'Library System'
    else bi.applicant_type
  end as applicant_type,
  sum(case
        when fli.total_eligible_recurring_costs::numeric > 0
          then fli.total_eligible_recurring_costs::numeric
        else fli.total_eligible_one_time_costs::numeric
      end * (frns.discount_rate::numeric / 100)) as funding_commitment_request
from frn_line_items_2017 fli
join frns_2017 frns
on fli.frn = frns.frn
join basic_informations_2017 bi
on frns.application_number = bi.application_number
where fli.line_item not in (
  select distinct frn_complete
  from fy2017_services_received_matr sr
  join fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  join fy2017_esh_line_items_v li
  on sr.line_item_id = li.id
  where (recipient_include_in_universe_of_districts
  and district_type = 'Traditional')
  or inclusion_status = 'dqs_excluded'
)
and service_type != 'Voice'
and not(service_type ilike '%internal%')
and fiber_sub_type is null
and function not in ('Switches','Connectors/Couplers','Cabling','UPS',
                      'Cabinets','Patch Panels', 'Routers')
group by 2

UNION

select
  'services received but not fully' as category,
  sum(case
        when line_item_recurring_elig_cost > 0
          then line_item_recurring_elig_cost*months_of_service
        else line_item_one_time_cost
      end * 
        (case
          when quantity_of_line_items_received_by_district > line_item_total_num_lines::numeric
            then 0
          else (line_item_total_num_lines::numeric - quantity_of_line_items_received_by_district)
        end/line_item_total_num_lines::numeric) * 
          discount_rate_c1_matrix) as funding_commitment_request
from (
  select  line_item_id,
          line_item_total_num_lines,
          line_item_recurring_elig_cost,
          months_of_service,
          line_item_one_time_cost,
          discount_rate_c1_matrix,
          sum(quantity_of_line_items_received_by_district) as quantity_of_line_items_received_by_district
  from fy2017_services_received_matr sr
  join fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  where inclusion_status != 'dqs_excluded'
  and recipient_include_in_universe_of_districts
  and district_type = 'Traditional'
  and erate
  and broadband
  group by 1,2,3,4,5,6
) snr