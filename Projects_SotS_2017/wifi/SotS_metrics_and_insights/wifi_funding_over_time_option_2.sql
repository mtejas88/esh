select 
funding_year::numeric,
sum(cmtd_total_cost::numeric) as total_cost,
count(distinct funding_requests.ben) as num_applicants,
count(distinct dd.esh_id) as num_applicants_in_districts,
sum(case when dd.esh_id is not null then cmtd_total_cost::numeric end) as cost_in_districts,
round(count(distinct dd.esh_id)::numeric / 
	(sum(case when dd.esh_id is not null then cmtd_total_cost::numeric end)::numeric / sum(cmtd_total_cost::numeric)),0) as proj_recip_districts,
(round(count(distinct dd.esh_id)::numeric / 
	(sum(case when dd.esh_id is not null then cmtd_total_cost::numeric end)::numeric / sum(cmtd_total_cost::numeric)),0)) / (
	select count(esh_id)::numeric
	from public.fy2017_districts_deluxe_matr
	where include_in_universe_of_districts = true
	and district_type = 'Traditional'
	) as perc_recipients

from public.funding_requests

left join public.entity_bens eb
on funding_requests.ben = eb.ben

left join public.fy2017_district_lookup_matr dl
on eb.entity_id::varchar = dl.esh_id

left join public.fy2017_districts_deluxe_matr dd
on dl.district_esh_id = dd.esh_id
and dd.include_in_universe_of_districts = true
and dd.district_type = 'Traditional'

where cmtd_category_of_service not in ('VOICE SERVICES','INTERNET ACCESS', 'TELCOMM SERVICES')
and cmtd_category_of_service is not null
and commitment_status != 'NOT FUNDED'
and application_type not in ('LIBRARY')
and funding_year::numeric <= 2014

group by 1
