with entities_blocks as(
select*from public.entities_to_census_blocks
where blockcode!='None'),

districts_blocks as(
select a.*, district_esh_id, fiber_target_status
from entities_blocks a
join public.fy2016_district_lookup_matr b 
on a.esh_id=b.esh_id
join endpoint.fy2016_districts_deluxe c
on b.district_esh_id = c.esh_id
where include_in_universe_of_districts
)


select a.district_esh_id, a.fiber_target_status,
count(distinct f."HoldingCompanyName") as nproviders,
array_agg(distinct f."HoldingCompanyName") as providerlist
from districts_blocks a
left join public.form477s f
on substring(a.blockcode from 1 for 12)  = substring(f."BlockCode" from 1 for 12) 
and f."TechCode"='50'
group by 1,2