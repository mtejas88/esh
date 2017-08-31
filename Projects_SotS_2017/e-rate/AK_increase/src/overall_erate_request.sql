with frns_2017 as (
  select *
  from fy2017.frns 
  where service_type != 'Voice'
  and frn not in (
    select frn
    from fy2017.current_frns 
    where service_type != 'Voice'  
  )

  UNION

  select *
  from fy2017.current_frns 
  where service_type != 'Voice'
  and frn_status not in ('Denied', 'Cancelled')
)

--remove one time where monthly
--remove excluded line items

select 
  'all' as category,
  sum(frns_2017.funding_commitment_request::numeric) as funding_commitment_request
from frns_2017

UNION

select
  'extra one time cost' as category,
  sum(case
        when fli.monthly_recurring_unit_eligible_costs::numeric > 0
          then fli.one_time_eligible_unit_costs::numeric*fli.one_time_quantity::numeric
        else 0
      end * (frns.discount_rate::numeric / 100)) as funding_commitment_request
from fy2017.frn_line_items fli
join fy2017.frns
on fli.frn = frns.frn

UNION

select
  'excluded' as category,
  sum(case
        when sr.line_item_district_monthly_cost_recurring > 0
          then sr.line_item_district_monthly_cost_recurring*sr.months_of_service
        else sr.line_item_district_one_time_cost
      end * (frns.discount_rate::numeric / 100)) as funding_commitment_request
from fy2017_services_received_matr sr
join fy2017_esh_line_items_v li
on sr.line_item_id = li.id
join fy2017.frn_line_items fli
on li.frn_complete = fli.line_item
join fy2017.frns
on fli.frn = frns.frn
where sr.inclusion_status = 'dqs_excluded'