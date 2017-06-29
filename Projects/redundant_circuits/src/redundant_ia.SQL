with line_item_lookup as (

select 
  recipient_id,
  sum(quantity_of_line_items_received_by_district) as num_internet_lines,
  sum(quantity_of_line_items_received_by_district * bandwidth_in_mbps) as redundant_bw,
  sum(case  
        when monthly_circuit_cost_recurring is null or monthly_circuit_cost_recurring = 0
          then line_item_total_monthly_cost * (quantity_of_line_items_received_by_district / line_item_total_num_lines::numeric)
        else monthly_circuit_cost_recurring * quantity_of_line_items_received_by_district
      end) as redundant_monthly_cost,
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
and line_item_total_num_lines != 'Unknown'
and line_item_total_num_lines::numeric > 0
and not('special_construction_tag' = any(open_tags))


group by
  recipient_id
  
having
  sum(quantity_of_line_items_received_by_district) > 1
  
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
          end ) as avg_cost_per_circuit,
  percentile_cont (0.3) within group (order by case  
                                                when sr.monthly_circuit_cost_recurring is null or sr.monthly_circuit_cost_recurring = 0
                                                  then line_item_total_monthly_cost / line_item_total_num_lines::numeric
                                                else sr.monthly_circuit_cost_recurring
                                              end ) as thirtieth_percentile


from 
  public.fy2016_services_received_matr sr

where inclusion_status ilike '%clean%'
and recipient_include_in_universe_of_districts = true
and purpose = 'Internet'
and bandwidth_in_mbps > 100
and recipient_exclude_from_ia_analysis = false
and recipient_postal_cd != 'AK'
and connect_category ilike '%Fiber%'
and line_item_total_monthly_cost > 0
and line_item_total_num_lines != 'Unknown'
and line_item_total_num_lines::numeric > 0
and not('special_construction_tag' = any(open_tags))

group by 
  bandwidth_in_mbps
  
order by 
  bandwidth_in_mbps

),

temp as (
  
  select 
    recipient_id,
    redundant_monthly_cost,
    redundant_bw,
    case
      when redundant_bw in (select bandwidth_in_mbps from national)
        then redundant_bw
      when redundant_bw < 1000
        then round(redundant_bw::numeric, -2)
      when redundant_bw < 10000 and redundant_bw != 9000
        then round(redundant_bw::numeric, -3)
      when redundant_bw = 9000
        then 10000
      else round(redundant_bw::numeric, -4)
    end as rounded_redundant_bw
    
  from 
    line_item_lookup

)

select 
  t.recipient_id,
  t.redundant_bw,
  t.rounded_redundant_bw,
  dd.locale,
  t.redundant_monthly_cost,
  n.median_cost_per_circuit as national_median_cost_per_circuit_at_bw,
  n.avg_cost_per_circuit as national_avg_cost_per_circuit_at_bw,
  n.thirtieth_percentile as national_thirtieth_percentile_at_bw

from temp t

left join national n
on t.rounded_redundant_bw = n.bandwidth_in_mbps

left join public.fy2016_districts_deluxe_matr dd
on t.recipient_id = dd.esh_id

--need to get rid of the 3 districts that don't have a comparison bw (30Gbps, 30 Gbps, and 79Gbps)
where n.median_cost_per_circuit is not null

order by
  t.recipient_id