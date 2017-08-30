with lookup as (
	select round(sum(c2_prediscount_budget_15 - c2_prediscount_remaining_15),2) as total_cost_15,
	round(sum(c2_prediscount_remaining_15 - c2_prediscount_remaining_16),2) as total_cost_16,
	round(sum(c2_prediscount_remaining_16 - c2_prediscount_remaining_17),2) as total_cost_17
	from public.fy2017_districts_deluxe_matr
	where include_in_universe_of_districts = true
	and district_type = 'Traditional'
)

select 
funding_year::numeric,
sum(cmtd_total_cost::numeric) as total_cost

/*applicant_state,
application_type,
cmtd_category_of_service,
cmtd_total_cost::numeric,
commitment_status,
funding_year*/
from public.funding_requests
where cmtd_category_of_service not in ('VOICE SERVICES','INTERNET ACCESS', 'TELCOMM SERVICES')
and cmtd_category_of_service is not null
and commitment_status != 'NOT FUNDED'
and application_type not in ('LIBRARY')
and funding_year::numeric <= 2014

group by 1

UNION

select 
	2015 as funding_year,
	total_cost_15 as total_cost

from lookup

UNION

select 
	2016 as funding_year,
	total_cost_16 as total_cost

from lookup

UNION

select 
	2017 as funding_year,
	total_cost_17 as total_cost

from lookup

