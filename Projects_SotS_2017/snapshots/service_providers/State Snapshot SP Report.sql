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
sum(case when exclude_from_ia_analysis=false and meeting_2014_goal_no_oversub=false then num_students else 0 end) as num_students_not_meeting_clean,
sum(case when exclude_from_ia_analysis=false then num_students else 0 end) as num_students_served_clean,
count(distinct case when dd.service_provider_assignment is not null then esh_id end) as num_districts_served_clean,
count(distinct case when exclude_from_ia_analysis=false and district_size in ('Mega','Large') then esh_id end) as num_districts_served_mega_large_clean,
count(distinct case when exclude_from_ia_analysis!=false and district_size in ('Mega','Large') then esh_id end) as num_districts_served_mega_large_dirty,
count(distinct sr.recipient_id) as num_districts_served_total,
sum(case when sr.recipient_id is not null then num_students else 0 end) as num_students_served_total
from public.fy2017_districts_deluxe_matr dd
--select all (distinct) recipients of the set of dominant service providers in dd
left join (
select distinct reporting_name,recipient_id 
from public.fy2017_districts_deluxe_matr dd
left join (select distinct
case when reporting_name = 'Ed Net of America'
then 'ENA Services, LLC'
when reporting_name in ('Bright House Net', 'Time Warner Cable Business LLC')
then 'Charter'
else reporting_name
end as reporting_name, recipient_id 
from public.fy2017_services_received_matr) sr
on dd.service_provider_assignment=sr.reporting_name
) sr
on dd.esh_id::numeric=sr.recipient_id::numeric
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
group by 1,2) a
where num_students_not_meeting_clean > 0
) as t
where r <=5
order by postal_cd