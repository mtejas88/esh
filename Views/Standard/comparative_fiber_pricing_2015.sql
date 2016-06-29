select recipient_id,
       concat('Lit Fiber ', bandwidth_in_mbps, ' mbps', 
                    case 
                      when internet_conditions_met = true then ' internet'
                      when upstream_conditions_met = true then ' upstream'
                    end, ' from ', service_provider_name) as service_type,
       (select count(*)
            from public.district_fiber_ia_prices_rank_2015 as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
            and fiap_all.service_provider_name = fiap.service_provider_name
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / (select count(*)
              from public.district_fiber_ia_prices_rank_2015 as fiap_all
              where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
              and fiap_all.internet_conditions_met = fiap.internet_conditions_met
              and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
              and fiap_all.service_provider_name = fiap.service_provider_name
            )::numeric as pct_dists_cheaper_fiber_tech_state_sp, 
        (select count(*)
            from public.district_fiber_ia_prices_rank_2015 as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.recipient_postal_cd = fiap.recipient_postal_cd
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / district_count::numeric as pct_dists_cheaper_fiber_tech_state,
        (select count(*)
            from public.district_fiber_ia_prices_rank_2015 as fiap_all
            where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
            and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            and fiap_all.best_cost_per_mbps < fiap.best_cost_per_mbps
        ) / (select count(*)
              from public.district_fiber_ia_prices_rank_2015 as fiap_all
              where fiap_all.bandwidth_in_mbps = fiap.bandwidth_in_mbps
              and fiap_all.internet_conditions_met = fiap.internet_conditions_met
            )::numeric as pct_dists_cheaper_fiber_tech_nation
from public.district_fiber_ia_prices_rank_2015 fiap
where rank_order = 1