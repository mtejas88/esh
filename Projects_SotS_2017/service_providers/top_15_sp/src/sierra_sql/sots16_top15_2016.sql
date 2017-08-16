with sp_assignments as (
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

                when reporting_name is null then service_provider_name
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
      from public.fy2016_services_received_matr sr
      left join public.fy2016_districts_predeluxe_matr dd
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

                when reporting_name = 'Zayo'

                  then 'Zayo Group, LLC'

                when reporting_name = 'CenturyLink Qwest'

                  then 'CenturyLink'

                when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')

                  then 'Charter'

                when reporting_name is null then service_provider_name
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
      left join public.fy2016_districts_predeluxe_matr dd
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
  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5
)

select reporting_name as service_provider_assignment,
postal_cd,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false and reporting_name is not null then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=true and reporting_name is not null then num_students else 0 end) as num_students_meeting_clean,
sum(case when exclude_from_ia_analysis=false and reporting_name is not null then num_students else 0 end) as num_students_served_clean,
count(distinct case when reporting_name is not null then dd.esh_id end) as num_districts_served_clean
from public.fy2016_districts_deluxe_matr dd
left join sp_assignments s
on dd.esh_id::numeric=s.esh_id::numeric
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and reporting_name in 
('Level 3','CenturyLink', 'Windstream' , 'Grande Comm', 'Cogent', 'Cox', 'Sunesys, LLC', 'Frontier','Computer Sciences','Charter','PHONOSCOPE LIGHT','Comcast','AT&T','ENA Services, LLC','Zayo Group, LLC')
group by 1,2