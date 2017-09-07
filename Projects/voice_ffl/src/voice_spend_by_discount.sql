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

frns_2016 as (
  select *
  from fy2016.frns 
  where frn not in (
    select frn
    from fy2016.current_frns 
  )

  UNION

  select *
  from fy2016.current_frns 
  where frn_status not in ('Denied', 'Cancelled')
),

frn_line_items_2016 as (
  select *
  from fy2016.frn_line_items 
  where line_item not in (
    select line_item
    from fy2016.current_frn_line_items 
  )

  UNION

  select cfli.*
  from fy2016.current_frn_line_items cfli
  join fy2016.current_frns cfrns 
  on cfli.frn = cfrns.frn 
  where frn_status not in ('Denied', 'Cancelled')
),

frn_line_items_2015 as (
  select
    "FRN",
    "Total Cost",
    "Rec Elig Cost",
    "One-time Elig Cost",
    "Serv Type",
    a."Application Number",
    b.discount_rate,
    "FRN Line Item No"
  
  from public.fy2015_item21_services_and_costs a

  
  left join (
    --to get the discount rate in 2015, usac took just the rounded average of any recipient that had "Full/Part Count" not null
    --see examples here https://sltools.universalservice.org/portal-external/form471/view/external/
    select "Application Number",
      round(avg("Cat 1 Disc Rate"::numeric),0) as discount_rate
    
    from public.fy2015_discount_calculations
    
    where "Full/Part Count" is not null
    
    group by 1
  ) b
  on a."Application Number" = b."Application Number"
  
),

frns_2015 as (
  select
    "Application Number",
    "BEN"
  
  from public.fy2015_basic_information_and_certifications
  
)


select
  2017 as year,
  frns.discount_rate::numeric,
  count(distinct frns.ben) as num_applicants,
  count(fli.line_item) as num_line_items,
  count(distinct fli.application_number) as num_applications,
  sum(case
        when fli.total_eligible_recurring_costs::numeric > 0
          then fli.total_eligible_recurring_costs::numeric
        else fli.total_eligible_one_time_costs::numeric
      end) as pre_discount,
  sum(case
        when fli.total_eligible_recurring_costs::numeric > 0
          then fli.total_eligible_recurring_costs::numeric
        else fli.total_eligible_one_time_costs::numeric
      end * (frns.discount_rate::numeric / 100)) as erate_request
from frn_line_items_2017 fli
join frns_2017 frns
on fli.frn = frns.frn
where service_type = 'Voice'

group by 1,2

UNION

select
  2016 as year,
  frns.discount_rate::numeric,
  count(distinct frns.applicant_ben) as num_applicants,
  count(fli.line_item) as num_line_items,
  count(distinct fli.application_number) as num_applications,
  sum(case
        when fli.total_eligible_recurring_costs::numeric > 0
          then fli.total_eligible_recurring_costs::numeric
        else fli.total_eligible_one_time_costs::numeric
      end) as pre_discount,
  sum(case
        when fli.total_eligible_recurring_costs::numeric > 0
          then fli.total_eligible_recurring_costs::numeric
        else fli.total_eligible_one_time_costs::numeric
      end * (frns.discount_rate::numeric / 100)) as erate_request
from frn_line_items_2016 fli
join frns_2016 frns
on fli.frn = frns.frn
where service_type = 'Voice'

group by 1,2

UNION

select
  2015 as year,
  discount_rate,
  count(distinct frns."BEN") as num_applicants,
  count(fli."FRN Line Item No") as num_line_items,
  count(distinct fli."Application Number") as num_applications,
  sum(case
        when fli."One-time Elig Cost"::numeric = 0
          then fli."Total Cost"::numeric
        when fli."Rec Elig Cost"::numeric = 0
          then fli."One-time Elig Cost"
        else fli."Total Cost" - fli."One-time Elig Cost"
      end) as pre_discount,
  sum(case
        when fli."One-time Elig Cost"::numeric = 0
          then fli."Total Cost"::numeric
        when fli."Rec Elig Cost"::numeric = 0
          then fli."One-time Elig Cost"
        else fli."Total Cost" - fli."One-time Elig Cost"
      end * (discount_rate / 100)) as erate_request
  

from frn_line_items_2015 fli
join frns_2015 frns
on fli."Application Number" = frns."Application Number"
where "Serv Type" = 'Voice Service'

group by 1,2