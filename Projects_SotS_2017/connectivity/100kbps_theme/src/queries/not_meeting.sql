
SELECT 
                esh_id,
                postal_cd,
                county,
                latitude,
                longitude,
                fiber_target_status,
                locale,
                district_size,
                ia_monthly_cost_total,
                ia_bw_mbps_total,
                ia_monthly_cost_per_mbps,
                ia_bandwidth_per_student_kbps,
                meeting_2014_goal_no_oversub,
                exclude_from_ia_cost_analysis,
                num_schools,
                num_students,
                num_campuses,
                frl_percent,
                discount_rate_c1_matrix,

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
                        when num_bids_received >= 2
                            then 1
                        else 0
                    end) > 0 as frns_2p_bid_indicator
        FROM (select
                frns.frn,
                frns.num_bids_received::numeric,
                del.esh_id,
                del.postal_cd,
                del.county,
                del.latitude,
                del.longitude,
                del.fiber_target_status,
                del.locale,
                del.district_size,
                del.ia_monthly_cost_total,
                del.ia_bw_mbps_total,
                del.ia_monthly_cost_per_mbps,
                del.ia_bandwidth_per_student_kbps,
                del.meeting_2014_goal_no_oversub,
                del.exclude_from_ia_cost_analysis,
                del.num_schools,
                del.num_students,
                del.num_campuses,
                del.frl_percent,
                del.discount_rate_c1_matrix
            from public.fy2017_districts_deluxe_matr del
            left join (
                select *
                from public.fy2017_services_received_matr
                where broadband
                and inclusion_status != 'dqs_excluded'
            ) sr
            on del.esh_id = sr.recipient_id
            left join public.fy2017_esh_line_items_v li
            on sr.line_item_id = li.id
            left join fy2017.frns
            on li.frn = frns.frn
            where  del.exclude_from_ia_analysis=false
            and include_in_universe_of_districts
            and district_type = 'Traditional'
            and meeting_2014_goal_no_oversub=false
            group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
        ) frns_districts
        group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
        ORDER BY esh_id;