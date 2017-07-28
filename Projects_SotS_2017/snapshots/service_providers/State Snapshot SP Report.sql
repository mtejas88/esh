with dirty_sp_assignments as (
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

      left join public.fy2017_districts_deluxe_matr dd

      on sr.recipient_id = dd.esh_id

      where purpose in ('Upstream', 'Internet')

      --and inclusion_status in ('clean_with_cost', 'clean_no_cost')

      and recipient_include_in_universe_of_districts

      and district_type = 'Traditional'

      and recipient_exclude_from_ia_analysis = true
      and dd.exclude_from_ia_analysis=true

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

      left join public.fy2017_districts_deluxe_matr dd

      on sr.recipient_id = dd.esh_id

      where purpose in ('Upstream', 'Internet')

      --and inclusion_status in ('clean_with_cost', 'clean_no_cost')

      and recipient_include_in_universe_of_districts

      and district_type = 'Traditional'

      and recipient_exclude_from_ia_analysis =  true
      and dd.exclude_from_ia_analysis=true

      group by 1,2,3,4

    )recipient_sp_bw




    group by 1

  ) recipient_sp_bw_total

  on recipient_sp_bw_rank.recipient_id = recipient_sp_bw_total.recipient_id

  where bw_rank = 1
  and recipient_sp_bw_total.bw_total > 0
  and recipient_sp_bw_rank.bandwidth/recipient_sp_bw_total.bw_total > .5)

select * from (

select postal_cd, 
service_provider_assignment,
num_students_not_meeting_clean,
case when num_students_served_clean > 0 then 
(num_students_not_meeting_clean::numeric/num_students_served_clean)*num_students_served_total 
else 0 end as extrap_num_students_not_meeting,
num_districts_served_clean,
case when (num_districts_served_mega_large_dirty+num_districts_served_mega_large_clean) > 0
then num_districts_served_mega_large_clean::numeric/
(num_districts_served_mega_large_dirty+num_districts_served_mega_large_clean) end as pct_mega_large_clean,
num_districts_served_total,
ROW_NUMBER() OVER (PARTITION BY postal_cd ORDER BY num_students_not_meeting_clean desc) AS r
from(

select postal_cd, 
case when dd.service_provider_assignment is not null then dd.service_provider_assignment
else sr.reporting_name end as service_provider_assignment,
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false dd.service_provider_assignment is not null then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false and dd.service_provider_assignment is not null then num_students else 0 end) as num_students_served_clean,
count(distinct case when dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_served_clean,
count(distinct case when exclude_from_ia_analysis=false and district_size in ('Mega','Large') dd.service_provider_assignment is not null then dd.esh_id end) as num_districts_served_mega_large_clean,
count(distinct case when exclude_from_ia_analysis!=false and district_size in ('Mega','Large') then dd.esh_id end) as num_districts_served_mega_large_dirty,
count(distinct case when exclude_from_ia_analysis=false or sr.reporting_name is not null then dd.esh_id end) as num_districts_served_total,
sum(case when exclude_from_ia_analysis=false or sr.reporting_name is not null then num_students else 0 end) as num_students_served_total
from public.fy2017_districts_deluxe_matr dd
left join dirty_sp_assignments sr
on dd.esh_id::numeric=sr.esh_id::numeric
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1,2) a
where num_students_not_meeting_clean > 0
)

as t
where r <=5
order by postal_cd