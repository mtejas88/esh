select  recipient_sp_bw_rank.recipient_id as esh_id,

reporting_name,

recipient_sp_bw_rank.purpose_list as primary_sp_purpose,

recipient_sp_bw_rank.bandwidth as primary_sp_bandwidth,

recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total as primary_sp_percent_of_bandwidth

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

              sum(bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric) as bandwidth,

              sum(case

                    when purpose = 'Transport'

                      then bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric

                    else 0

                  end) as upstream_bandwidth,
                
              array_agg(distinct purpose2 order by purpose2) as purpose_list

      from (select a.*, case when purpose='Transport' then 'Upstream' else purpose end as purpose2
      from public.fy2015_services_received_m a) sr


      where quantity_of_lines_received_by_district != 'Shared Circuit'
      and (internet_conditions_met=true or upstream_conditions_met=true)
      and consortium_shared=false
      and dirty_status ilike '%clean%'

      group by 1,2

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

              sum(bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric) as bandwidth,

              sum(case

                    when purpose = 'Upstream'

                      then bandwidth_in_mbps * quantity_of_lines_received_by_district::numeric

                    else 0

                  end) as upstream_bandwidth

      from public.fy2015_services_received_m sr

      where quantity_of_lines_received_by_district != 'Shared Circuit'
      and (internet_conditions_met=true or upstream_conditions_met=true)
      and consortium_shared=false
      and dirty_status ilike '%clean%'

      group by 1,2

    )recipient_sp_bw




    group by 1

  ) recipient_sp_bw_total

  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id

  where bw_rank = 1
  
  and recipient_sp_bw_total.bw_total > 0

  /*adding bw_total > 0 as the new staging db Rose has more 2017 data and a lot of rows have bw_total that are 0,
this prevents the creation of the materialized view due to division error of 0*/

  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5