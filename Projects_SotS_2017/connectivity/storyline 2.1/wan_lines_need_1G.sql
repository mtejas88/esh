with district_school_lookup as (
select del.esh_id, del.postal_cd, del.name, del.lt_1g_fiber_wan_lines,del.lt_1g_nonfiber_wan_lines, del.meeting_2014_goal_no_oversub,
l.campus_id,
sum(l.num_students) as num_students 
from public.fy2017_districts_deluxe_matr del
join public.fy2017_schools_demog_matr l on del.esh_id::numeric=l.district_esh_id::numeric
where  del.include_in_universe_of_districts
and del.district_type = 'Traditional'
group by 1,2,3,4,5,6,7
),

school_campus_summary as (

select *,
row_number() over (partition by esh_id order by num_students desc) as rank
from district_school_lookup

order by  esh_id asc,
          num_students desc
),

wan_lookup as (

select 
s.recipient_id,
s.bandwidth_in_mbps,
s.quantity_of_line_items_received_by_district,
generate_series(1, quantity_of_line_items_received_by_district) AS c_id,
row_number() over (partition by s.recipient_id order by s.bandwidth_in_mbps desc) as rank

from public.fy2017_services_received_matr s

left join public.fy2017_districts_deluxe_matr d
on s.recipient_id = d.esh_id


where s.purpose = 'WAN'
and s.inclusion_status ilike '%clean%'
and d.exclude_from_wan_analysis = false
and quantity_of_line_items_received_by_district > 0

group by  c_id,
          s.recipient_id,
          s.bandwidth_in_mbps,
          s.quantity_of_line_items_received_by_district
          
),


final_table as(
select s.*,
w.bandwidth_in_mbps,
w.quantity_of_line_items_received_by_district,
w.c_id,
1000 * w.bandwidth_in_mbps::integer / s.num_students::integer  as wan_bw_per_student_kbps

from school_campus_summary s

left join wan_lookup w
on s.esh_id = w.recipient_id
and s.rank = w.rank

where s.num_students::integer > 0
and w.recipient_id is not null
and s.rank - w.rank <=4
)

select meeting_2014_goal_no_oversub, count(campus_id) as num_campuses,
count(case when bandwidth_in_mbps < 1000 and num_students > 100 then campus_id end) as campuses_need_1G
from final_table
group by 1
