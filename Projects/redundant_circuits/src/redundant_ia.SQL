with line_item_lookup as (

select 
  recipient_id,
  bandwidth_in_mbps,
  sum(quantity_of_line_items_received_by_district) as num_internet_lines,
  array_agg(line_item_id) as line_items

from 
  public.fy2016_services_received_matr

where inclusion_status ilike '%clean%'
and recipient_include_in_universe_of_districts = true
and purpose = 'Internet'
and bandwidth_in_mbps > 100
and recipient_exclude_from_ia_analysis = false
and recipient_postal_cd != 'AK'
and connect_category ilike '%Fiber%'
and line_item_total_monthly_cost > 0

group by
  recipient_id,
  bandwidth_in_mbps
  
having
  sum(quantity_of_line_items_received_by_district) > 1
  
),

temp as (

select
  lil.recipient_id,
  bandwidth_in_mbps,
  num_internet_lines,
  unnest(lil.line_items) as line_item_id

from
  line_item_lookup lil

),

national as (

select 
  bandwidth_in_mbps,
  median( case  
            when sr.monthly_circuit_cost_recurring is null or sr.monthly_circuit_cost_recurring = 0
              then line_item_total_monthly_cost / line_item_total_num_lines::numeric
            else sr.monthly_circuit_cost_recurring
          end ) as median_cost_per_circuit,
  avg( case  
            when sr.monthly_circuit_cost_recurring is null or sr.monthly_circuit_cost_recurring = 0
              then line_item_total_monthly_cost / line_item_total_num_lines::numeric
            else sr.monthly_circuit_cost_recurring
          end ) as avg_cost_per_circuit


from 
  public.fy2016_services_received_matr sr

where inclusion_status ilike '%clean%'
and recipient_include_in_universe_of_districts = true
and purpose = 'Internet'
and bandwidth_in_mbps > 100
and recipient_exclude_from_ia_analysis = false
and recipient_postal_cd != 'AK'
and connect_category ilike '%Fiber%'

group by 
  bandwidth_in_mbps
  
order by 
  bandwidth_in_mbps

)

select 
  temp.recipient_id,
  d.locale,
  temp.bandwidth_in_mbps,
  case  
    when sr.monthly_circuit_cost_recurring is null or sr.monthly_circuit_cost_recurring = 0
      then line_item_total_monthly_cost / line_item_total_num_lines::numeric
    else sr.monthly_circuit_cost_recurring
  end as cost_per_circuit,
  sr.quantity_of_line_items_received_by_district as num_internet_lines,
  n.median_cost_per_circuit,
  n.avg_cost_per_circuit

from temp

join public.fy2016_services_received_matr sr
on temp.line_item_id = sr.line_item_id
and temp.recipient_id = sr.recipient_id

left join national n
on sr.bandwidth_in_mbps = n.bandwidth_in_mbps

left join public.fy2016_districts_deluxe_matr d
on sr.recipient_id = d.esh_id

order by
  temp.recipient_id