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
                    end) > 0 as frns_0_bid_indicator,
                sum(case
                        when num_bids_received = 1
                            then 1
                        else 0
                    end) > 0 as frns_1_bid_indicator,
                sum(case
                        when num_bids_received = 2
                            then 1
                        else 0
                    end) > 0 as frns_2_bid_indicator,
                sum(case
                        when num_bids_received = 2
                            then 1
                        else 0
                    end) > 0 as frns_3p_bid_indicator
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
                'Fixed Wireless' = any(array_agg(sr.purpose)) as fixed_wireless_indicator
            from public.fy2016_districts_deluxe_matr del
            left join (
                select *
                from public.fy2016_services_received_matr
                where broadband
                and inclusion_status != 'dqs_excluded'
            ) sr
            on del.esh_id = sr.recipient_id
            left join fy2016.line_items li
            on sr.line_item_id = li.id
            left join fy2016.frns
            on li.frn = frns.frn
            where del.include_in_universe_of_districts_all_charters
            group by 1,2,3,4,5,6,7,8,9,10,11,12
        ) frns_districts
        group by 1,2,3,4,5,6,7,8,9,10