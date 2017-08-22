with meeting_goals_over_time as(
SELECT '2017' as year, meeting_2014_goal_no_oversub, 
count(*) as cnt
            from public.fy2017_districts_deluxe_matr del
            where  del.exclude_from_ia_analysis=false
            and include_in_universe_of_districts
            and district_type = 'Traditional'
            and locale in ('Rural','Town')
        group by 1,2
union
SELECT '2016' as year, meeting_2014_goal_no_oversub, 
count(*) as cnt
            from public.fy2016_districts_deluxe_matr del
            where  del.exclude_from_ia_analysis=false
            and include_in_universe_of_districts
            and district_type = 'Traditional'
            and locale in ('Rural','Town')
        group by 1,2
union
SELECT '2015' as year, meeting_2014_goal_no_oversub, 
count(*) as cnt
            from public.fy2015_districts_deluxe_m del
            where  del.exclude_from_analysis=false
            and locale in ('Rural','Small Town')
        group by 1,2
order by 1,2),

unscalable_campuses as(
SELECT '2017' as year, case when  locale in ('Rural','Town') then 'Rural/Town' else 'Rest' end as locale,
sum(current_known_unscalable_campuses) + sum(current_assumed_unscalable_campuses) as unscalable_campuses,
sum(num_campuses) as total_num_campuses
            from public.fy2017_districts_deluxe_matr del
            where include_in_universe_of_districts
            and district_type = 'Traditional'
        group by 1,2
union
SELECT '2016' as year, case when  locale in ('Rural','Town') then 'Rural/Town' else 'Rest' end as locale,
sum(current_known_unscalable_campuses) + sum(current_assumed_unscalable_campuses) as unscalable_campuses,
sum(num_campuses) as total_num_campuses
            from public.fy2016_districts_deluxe_matr del
            where include_in_universe_of_districts
            and district_type = 'Traditional'
        group by 1,2
union
SELECT '2015' as year, case when locale in ('Rural','Small Town') then 'Rural/Town' else 'Rest' end as locale,
9500 unscalable_campuses, sum(num_campuses) as total_num_campuses
            from public.fy2015_districts_deluxe_m del
        group by 1,2,3
order by 1,2)

--select * from meeting_goals_over_time
select * from unscalable_campuses
