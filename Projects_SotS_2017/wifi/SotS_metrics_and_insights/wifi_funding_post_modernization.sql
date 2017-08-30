with lookup as (
	select 
	round(sum(c2_prediscount_budget_15 - c2_prediscount_remaining_15),2) as total_cost_15,
	round(sum(c2_prediscount_remaining_15 - c2_prediscount_remaining_16),2) as total_cost_16,
	round(sum(c2_prediscount_remaining_16 - c2_prediscount_remaining_17),2) as total_cost_17,
	count(case when round(c2_prediscount_budget_15 - c2_prediscount_remaining_15,0) > 0 then esh_id end) as num_recip_districts_thru_15,
	count(case when round(c2_prediscount_budget_15 - c2_prediscount_remaining_16,0) > 0 then esh_id end) as num_recip_districts_thru_16,
	count(case when round(c2_prediscount_budget_15 - c2_prediscount_remaining_17,0) > 0 then esh_id end) as num_recip_districts_thru_17
	from public.fy2017_districts_deluxe_matr
	where include_in_universe_of_districts = true
	and district_type = 'Traditional'
)

select 
	2015 as funding_year,
	num_recip_districts_thru_15 as num_recip_districts,
	total_cost_15 as total_cost

from lookup

UNION

select 
	2016 as funding_year,
	num_recip_districts_thru_16 as num_recip_districts,
	total_cost_16 as total_cost

from lookup

UNION

select 
	2017 as funding_year,
	num_recip_districts_thru_17 as num_recip_districts,
	total_cost_17 as total_cost

from lookup

