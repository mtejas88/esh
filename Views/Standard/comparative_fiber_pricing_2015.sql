/*
Date Created: Spring 2016
Date Last Modified : 06/27/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: Calculate various state/national-level measures on comparative lit fiber technology pricing. 
Eg. Percent of districts in the state that pay lower cost per mbps for lit fiber at same bandwidth.
*/

with district_fiber_ia_prices as (
  select  svcs.recipient_id,
          svcs.recipient_postal_cd,
          bandwidth_in_mbps,
          internet_conditions_met,
          upstream_conditions_met,
          service_provider_name,
          min(line_item_total_monthly_cost / (line_item_total_num_lines * bandwidth_in_mbps)) 
          as best_cost_per_mbps       
  from public.services_received_2015 svcs
  where shared_service = 'District-dedicated'
  and dirty_status = 'include clean'
  and exclude = false
  and (internet_conditions_met = true or upstream_conditions_met = true)
  and not (internet_conditions_met = true and upstream_conditions_met = true)
  and connect_category = 'Fiber'   -- lit fiber
  and connect_type != 'Dark Fiber Service'
  group by  svcs.recipient_id,
          svcs.recipient_postal_cd,
          bandwidth_in_mbps,
          internet_conditions_met,
          upstream_conditions_met,
          service_provider_name      
  order by svcs.recipient_id ),

district_service_count as (
  select bandwidth_in_mbps,
         internet_conditions_met,
         upstream_conditions_met,
         recipient_postal_cd,
         count(*) as district_count
  from district_fiber_ia_prices
  where best_cost_per_mbps is not null and best_cost_per_mbps != 0
  group by bandwidth_in_mbps,
           internet_conditions_met,
           upstream_conditions_met,
           recipient_postal_cd    
),

district_fiber_ia_prices_rank as (
  select fpia.*,
          dsc.district_count,
          row_number() over (partition by recipient_id order by district_count desc) as rank_order
  from district_fiber_ia_prices fpia
  join district_service_count dsc
  on  concat(fpia.bandwidth_in_mbps,fpia.internet_conditions_met,fpia.recipient_postal_cd) = 
      concat(dsc.bandwidth_in_mbps,dsc.internet_conditions_met,dsc.recipient_postal_cd)
  where best_cost_per_mbps is not null and best_cost_per_mbps != 0
)

select  recipient_id,
        concat('Lit Fiber ', bandwidth_in_mbps, ' mbps', 
                    case 
                      when internet_conditions_met = true then ' internet'
                      when upstream_conditions_met = true then ' upstream'
                    end, ' from ', service_provider_name) as service_type,

        (select count(*)
            from district_fiber_ia_prices_rank as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
            and fiap_all.service_provider_name = fiap.service_provider_name
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / (select count(*)
              from district_fiber_ia_prices_rank as fiap_all
              where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
              and fiap_all.internet_conditions_met = fiap.internet_conditions_met
              and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
              and fiap_all.service_provider_name = fiap.service_provider_name
            )::numeric as pct_dists_cheaper_fiber_tech_state_sp, 
        (select count(*)
            from district_fiber_ia_prices_rank as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / district_count::numeric as pct_dists_cheaper_fiber_tech_state,
        (select count(*)
            from district_fiber_ia_prices_rank as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / (select count(*)
              from district_fiber_ia_prices_rank as fiap_all
              where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
              and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            )::numeric as pct_dists_cheaper_fiber_tech_nation
from district_fiber_ia_prices_rank fiap
where rank_order = 1