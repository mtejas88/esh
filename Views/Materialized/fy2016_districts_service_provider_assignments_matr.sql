select  recipient_sp_bw_rank.recipient_id as esh_id, reporting_name
  from (
    select  *,
            row_number() over (partition by recipient_id order by bandwidth desc ) as bw_rank
    from (
      select  recipient_id,
              case
                when reporting_name = 'Ed Net of America'
                  then 'ENA Services, LLC'
                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')
                  then 'Charter'
                else reporting_name
              end as reporting_name,
              num_students,
              meeting_2014_goal_no_oversub,
              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,
              sum(case
                    when purpose = 'Upstream'
                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district
                    else 0
                  end) as upstream_bandwidth
      from public.fy2016_services_received_matr sr
      left join public.fy2016_districts_deluxe_matr dd
      on sr.recipient_id = dd.esh_id
      where purpose in ('Upstream', 'Internet')
      and inclusion_status = 'clean_with_cost'
      and recipient_include_in_universe_of_districts
      and district_type = 'Traditional'
      and recipient_exclude_from_ia_analysis = false
      group by 1,2,3,4
    )recipient_sp_bw
  ) recipient_sp_bw_rank
  left join (
    select  recipient_id,
            sum(bandwidth) as bw_total
    from (
      select  recipient_id,
              case
                when reporting_name = 'Ed Net of America'
                  then 'ENA Services, LLC'
                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')
                  then 'Charter'
                else reporting_name
              end as reporting_name,
              num_students,
              meeting_2014_goal_no_oversub,
              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,
              sum(case
                    when purpose = 'Upstream'
                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district
                    else 0
                  end) as upstream_bandwidth
      from public.fy2016_services_received_matr sr
      left join public.fy2016_districts_deluxe_matr dd
      on sr.recipient_id = dd.esh_id
      where purpose in ('Upstream', 'Internet')
      and inclusion_status = 'clean_with_cost'
      and recipient_include_in_universe_of_districts
      and district_type = 'Traditional'
      and recipient_exclude_from_ia_analysis = false
      group by 1,2,3,4
    )recipient_sp_bw

    group by 1
  ) recipient_sp_bw_total
  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id
  where bw_rank = 1
  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5
  --remove districts where their service providers bandwidth isn't fully upstream or internet
  and (bandwidth = upstream_bandwidth or upstream_bandwidth = 0)

/*
Author: Justine Schott
Created On Date: 1/26/2017
Last Modified Date:
Name of QAing Analyst(s):
Purpose: Service provider assignment as done in 2016 SotS
Methodology:
*/