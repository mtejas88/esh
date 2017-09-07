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
  
),

results_17 as (


select
  2017 as year,
  frns.ben as ben,
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

),

results_15 as (

select
  2015 as year,
  frns."BEN" as ben,
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

)

select r17.ben,
r17.num_line_items as num_line_items_17,
r15.num_line_items as num_line_items_15,
r17.num_applications as num_applications_17,
r15.num_applications as num_applications_15,
r17.pre_discount as pre_discount_17,
r15.pre_discount as pre_discount_15,
r17.erate_request as erate_request_17,
r15.erate_request as erate_request_15
from results_17 r17
join results_15 r15
on r17.ben = r15.ben