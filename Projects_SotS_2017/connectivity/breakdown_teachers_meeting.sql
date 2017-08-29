with teachers_by_dist_size as (
  select 
    district_size,
    median(num_teachers/num_students::numeric) as median_teachers_per_student
  from fy2017_districts_deluxe_matr dd
  where dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
  group by 1
),

districts as (
select 
  esh_id,
  exclude_from_ia_analysis, 
  meeting_2014_goal_no_oversub,
  case
    when num_teachers <= 0 or num_teachers is null
      then median_teachers_per_student * num_students
    else num_teachers
  end as num_teachers,
  num_schools
from fy2017_districts_deluxe_matr dd
join teachers_by_dist_size tds
on dd.district_size = tds.district_size
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
)

select
  sum(case
        when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub
          then num_teachers
        else 0
      end::numeric) as sample_num_teachers_connected,
  round(sum(case
              when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub
                then num_teachers
              else 0
            end::numeric)/  sum(case
                                  when exclude_from_ia_analysis = false
                                    then num_teachers
                                  else 0
                                end)::numeric * sum(num_teachers::numeric) / 1000000,1) as extrapolated_num_teachers_connected,
  sum(case
        when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub = false
          then num_teachers
        else 0 
      end::numeric) as sample_num_teachers_left,
  round(sum(case
              when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub = false
                then num_teachers
              else 0
            end::numeric)/  sum(case
                                  when exclude_from_ia_analysis = false
                                    then num_teachers
                                  else 0
                                end)::numeric * sum(num_teachers::numeric) / 1000000,1) as extrapolated_num_teachers_left,
  sum(case
        when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub
          then num_schools
        else 0
      end::numeric) as sample_num_schools_connected,
  sum(case
        when exclude_from_ia_analysis = false and meeting_2014_goal_no_oversub
          then num_schools
        else 0
      end::numeric)/  sum(case
                            when exclude_from_ia_analysis = false
                              then num_schools
                            else 0
                          end)::numeric * sum(num_schools::numeric) as extrapolated_num_schools_connected
from districts