with t as (
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

                when reporting_name = 'Zayo'

                  then 'Zayo Group, LLC'

                when reporting_name = 'CenturyLink Qwest'

                  then 'CenturyLink'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                when reporting_name is null or reporting_name = '' then service_provider_name
                else reporting_name

              end as reporting_name,

              num_students,

              meeting_2014_goal_no_oversub,

              sum(bandwidth_in_mbps * quantity_of_line_items_received_by_district) as bandwidth,

              sum(case

                    when purpose = 'Upstream'

                      then bandwidth_in_mbps * quantity_of_line_items_received_by_district

                    else 0

                  end) as upstream_bandwidth,
                
              array_agg(distinct purpose order by purpose) as purpose_list

      from public.fy2017_services_received_matr sr

      left join public.fy2017_districts_predeluxe_matr dd

      on sr.recipient_id = dd.esh_id

      where purpose in ('Upstream', 'Internet')

      and inclusion_status in ('clean_with_cost', 'clean_no_cost')

      and recipient_include_in_universe_of_districts

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

                when reporting_name = 'Zayo'

                  then 'Zayo Group, LLC'

                when reporting_name = 'CenturyLink Qwest'

                  then 'CenturyLink'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                when reporting_name is null or reporting_name = '' then service_provider_name
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

)

select t.esh_id,
case when l.esh_id is not null then (
  case

                when l.service_provider_assignment = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when l.service_provider_assignment in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                else l.service_provider_assignment end
)
else t.reporting_name end as reporting_name,
t.primary_sp_purpose,
t.primary_sp_bandwidth,
t.primary_sp_percent_of_bandwidth
from t
left join public.large_mega_dqt_overrides l
on t.esh_id::integer=l.esh_id::integer
union
select l.esh_id::varchar,
  case

                when l.service_provider_assignment = 'Ed Net of America'

                  then 'ENA Services, LLC'

                when l.service_provider_assignment in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                else l.service_provider_assignment end
as reporting_name,
NULL as primary_sp_purpose,
NULL as primary_sp_bandwidth,
NULL as primary_sp_percent_of_bandwidth
from  public.large_mega_dqt_overrides l
where l.esh_id::varchar not in (select esh_id from t)





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

Modified Date: 8/9/2017
Name of Modifier: Sierra Costanza
Purpose/Methodology: Small modifications to reporting name (if null, use service_provider_name). The same logic was ap[plied to the 2016 view.
Also applying a table with DQT primary service provider overrides for some mostly dirty Large and Mega districts unique to 2017.


Modified Date: 9/6/2017
Name of Modifier: Jamie Barnes
Purpose/Methodology: slight tweak to deal with instances where reporting_name = '' and open up to AZ Charters

*/
