with t as(
SELECT esh_id, district_size, meeting_2014_goal_no_oversub,
ia_monthly_cost_total, num_students
from public.fy2017_districts_deluxe_matr del
where  del.exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_cost_analysis=FALSE 
and postal_cd !='AK')

select 'all' as grp,
meeting_2014_goal_no_oversub,
median(ia_monthly_cost_total/num_students) as median_cost_per_student,
sum(ia_monthly_cost_total)::numeric/sum(num_students) as avg_cost_per_student
from t
group by 1,2
union
select 'mega/large' as grp,
meeting_2014_goal_no_oversub,
median(ia_monthly_cost_total/num_students) as median_cost_per_student,
sum(ia_monthly_cost_total)::numeric/sum(num_students) as avg_cost_per_student
from t
where district_size in ('Mega', 'Large')
group by 1,2

order by 1,2
