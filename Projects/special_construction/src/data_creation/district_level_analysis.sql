with state_bids as (
    select
        postal_cd,
        case
            when frns_2p_bid > 0
                then '2+ bid received'
            when frns_1_bid > 0
                then '1 bid received'
            when frns_0_bid > 0
                then '0 bid received'
            else 'remove'
        end as bid_category,
        count(*) as districts,
        median(ia_monthly_cost_per_mbps) as median_ia_monthly_cost_per_mbps,
        median(ia_bandwidth_per_student_kbps) as median_ia_bandwidth_per_student_kbps
    from(
        select  esh_id,
                postal_cd,
                fiber_target_status,
                locale,
                ia_monthly_cost_per_mbps,
                meeting_knapsack_affordability_target,
                ia_bandwidth_per_student_kbps,
                meeting_2014_goal_no_oversub,
                exclude_from_ia_analysis,
                exclude_from_ia_cost_analysis,
                sum(case
                        when num_bids_received = 0
                            then 1
                        else 0
                    end) as frns_0_bid,
                sum(case
                        when num_bids_received = 1
                            then 1
                        else 0
                    end) as frns_1_bid,
                sum(case
                        when num_bids_received >= 2
                            then 1
                        else 0
                    end) as frns_2p_bid
        from(
             select
                frns.frn,
                frns.num_bids_received::numeric,
                del.esh_id,
                del.postal_cd,
                del.fiber_target_status,
                del.locale,
                del.ia_monthly_cost_per_mbps,
                del.meeting_knapsack_affordability_target,
                del.ia_bandwidth_per_student_kbps,
                del.meeting_2014_goal_no_oversub,
                del.exclude_from_ia_analysis,
                del.exclude_from_ia_cost_analysis,
                'Internet' = any(array_agg(sr.purpose)) as internet_indicator,
                'WAN' = any(array_agg(sr.purpose)) as wan_indicator,
                'Upstream' = any(array_agg(sr.purpose)) as upstream_indicator,
                'Backbone' = any(array_agg(sr.purpose)) as backbone_indicator,
                'ISP' = any(array_agg(sr.purpose)) as isp_indicator,
                'Lit Fiber' = any(array_agg(sr.purpose))
                  or 'Dark Fiber' = any(array_agg(sr.purpose)) as fiber_indicator,
                'Other Copper' = any(array_agg(sr.purpose))
                  or 'T-1' = any(array_agg(sr.purpose))
                  or 'DSL' = any(array_agg(sr.purpose)) as copper_indicator,
                'Cable' = any(array_agg(sr.purpose)) as cable_indicator,
                'Fixed Wireless' = any(array_agg(sr.purpose)) as fixed_wireless_indicator,
                sum(case
                        when sr.bandwidth_in_mbps < 100
                            then 1
                        else 0
                    end) as low_bw_indicator,
                sum(case
                        when sr.bandwidth_in_mbps < 100
                            then 1
                        else 0
                    end) as low_bw_indicator
            from public.fy2016_services_received_matr sr
            left join public.fy2016_districts_deluxe_matr del
            on sr.recipient_id = del.esh_id
            left join fy2016.line_items li
            on sr.line_item_id = li.id
            left join fy2016.frns
            on li.frn = frns.frn
            where frns.frn is not null
            and sr.broadband
            and sr.inclusion_status != 'dqs_excluded'
            and del.include_in_universe_of_districts_all_charters
            group by 1,2,3,4,5,6,7,8,9,10,11,12
        ) frns_districts
        where   not(internet_indicator and
                    wan_indicator = false
                    and upstream_indicator = false
                    and backbone_indicator = false
                    and isp_indicator = false
                    and total_pre_discount_charges < 3600
                    and low_bw_indicator = 0
                )
        group by 1,2,3,4,5,6,7,8,9,10
    ) districts
    where exclude_from_ia_cost_analysis = false
    and exclude_from_ia_cost_analysis = false
    group by 1,2
    having count(*) > 5
    order by 1,2
)

select  *,
        rank()
from state_bids
where postal_cd in (
    select distinct postal_cd
    from state_bids
    where bid_category = '0 bid received'
)