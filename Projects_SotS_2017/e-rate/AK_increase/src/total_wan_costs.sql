with li_lookup as (
  select (dd.postal_cd = 'AK') as postal_cd_AK,
  line_item_id, 
  recipient_id,
  case 
    when purpose = 'WAN' 
      then 'WAN' 
    else 'Internet' 
  end as purpose_adj,
  line_item_district_mrc_unless_null
  
  from public.fy2017_services_received_matr sr
  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id
  
  where dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'
  and dd.exclude_from_ia_analysis = false
  and dd.exclude_from_ia_cost_analysis = false
  and inclusion_status != 'dqs_excluded'
  --and erate = true
  and broadband = true
  --and the district doesn't have any restricted cost line items
  and sr.recipient_id not in (
    select distinct recipient_id
    from public.fy2017_services_received_matr sr
    where inclusion_status != 'dqs_excluded'
    and ('exclude_for_cost_only_restricted' = any(sr.open_tags)
          or 'exclude_for_cost_only_unknown' = any(sr.open_tags))
  )

),

perc as (

  select distinct
    postal_cd_AK,
    purpose_adj,
    sum(line_item_district_mrc_unless_null) over (partition by postal_cd_AK, purpose_adj) as monthly_cost,
    sum(line_item_district_mrc_unless_null) over (partition by postal_cd_AK, purpose_adj)::numeric / 
      sum(line_item_district_mrc_unless_null) over (partition by postal_cd_AK)::numeric as perc_monthly_cost


  from li_lookup

),

lines as (

  select (dd.postal_cd = 'AK') as postal_cd_AK,
    line_item_id,
    recipient_id,
    line_item_district_mrc_unless_null

  from public.fy2017_services_received_matr sr

  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id

  where inclusion_status != 'dqs_excluded'
  and dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'

),

costs as (
 
select postal_cd_AK,
round(sum(line_item_district_mrc_unless_null * 12),0) as total_costs

from lines
group by 1

)

select 
  perc.postal_cd_ak,
  purpose_adj,
  round(perc_monthly_cost * total_costs,0) as extrap_wan_cost

from perc

join costs
on perc.postal_cd_AK = costs.postal_cd_AK

where purpose_adj = 'WAN'