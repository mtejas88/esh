select  recipient_sp_bw_rank.recipient_id as esh_id,

reporting_name,

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

              num_students,

              meeting_2014_goal_no_oversub,

              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,

              sum(case

                    when purpose = 'Upstream'

                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district

                    else 0

                  end) as upstream_bandwidth

      from public.fy2017_services_received_matr sr

      left join public.fy2017_districts_predeluxe_matr dd

      on sr.recipient_id = dd.esh_id

      where purpose in ('Upstream', 'Internet')

      and inclusion_status in ('clean_with_cost', 'clean_no_cost')

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

      from public.fy2017_services_received_matr sr

      left join public.fy2017_districts_predeluxe_matr dd

      on sr.recipient_id = dd.esh_id

      where purpose in ('Upstream', 'Internet')

      and inclusion_status in ('clean_with_cost', 'clean_no_cost')

      and recipient_include_in_universe_of_districts

      and district_type = 'Traditional'

      and recipient_exclude_from_ia_analysis = false

      group by 1,2,3,4

    )recipient_sp_bw




    group by 1

  ) recipient_sp_bw_total

  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id

  where bw_rank = 1
  
  and recipient_sp_bw_total.bw_total > 0 
  
  /*adding bw_total > 0 as the new staging db Rose has more 2017 data and a lot of rows have bw_total that are 0,
this prevents the creation of the materialized view due to division error of 0*/

  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5







/*
Author: Justine Schott
Created On Date: 1/26/2017
Last Modified Date: 3/30/2017 - - included clean_no_cost line items. Included districts whose primary
      service provider gives them IA and upstream
Name of QAing Analyst(s):
Purpose: Service provider assignment as done in 2016 SotS
Methodology:
Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise.
*/
