--copied from Form_477_Analysis > src > form477s-fiber3.sql which was QA'd, with addition on filtering by fiber target and additional fields
with entities_blocks as (
	select *
	from public.entities_to_census_blocks
	where blockcode!='None'
),

districts_blocks as (
	select 
		a.*, 
		district_esh_id, 
		locale,
		district_size
	from entities_blocks a
	join public.fy2016_district_lookup_matr b 
	on a.esh_id=b.esh_id
	join public.fy2016_districts_deluxe_matr c
	on b.district_esh_id = c.esh_id
	where include_in_universe_of_districts_all_charters
	and fiber_target_status = 'Target'
)

select 
	a.district_esh_id,
	a.locale,
	a.district_size,
	count(distinct f."HoldingCompanyName") as nproviders,
	array_agg(distinct f."HoldingCompanyName") as providerlist
from districts_blocks a
left join public.form477s f
on a.blockcode=f."BlockCode"
and f."TechCode"='50'
group by 1,2,3
