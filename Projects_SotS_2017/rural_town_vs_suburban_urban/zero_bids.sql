with t as (
SELECT 
                esh_id,
                locale,
                district_size,

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
                del.locale,
                del.district_size
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
            group by 1,2,3,4,5
        ) frns_districts
        group by 1,2,3
order by 1,2,3)

select locale, frns_0_bid_indicator, count(distinct esh_id) as num_districts
from t group by 1,2 order by 1,2