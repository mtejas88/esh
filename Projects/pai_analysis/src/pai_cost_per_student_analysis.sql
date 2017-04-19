with dist_size as (
	select 
		d16.district_size,
		sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2015,
		sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2016,
		(sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1)) - sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)))/
			sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)) as monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost > .1
					then 1
				else 0
			end) as num_districts_monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost < -.1
					then 1
				else 0
			end) as num_districts_monthly_cost_decrease,
		sum(1) as num_districts
	from fy2016_districts_deluxe_matr d16
	left join public.fy2015_districts_metrics_fy2016_methods_m d15
	on d16.esh_id = d15.district_esh_id
	where d16.include_in_universe_of_districts
	and d16.exclude_from_ia_cost_analysis = false
	and d15.exclude_from_analysis = false
	and d15.ia_monthly_cost > 0
	group by 1
),

locale as (
	select 
		d16.locale,
		sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2015,
		sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2016,
		(sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1)) - sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)))/
			sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)) as monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost > .1
					then 1
				else 0
			end) as num_districts_monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost < -.1
					then 1
				else 0
			end) as num_districts_monthly_cost_decrease,
		sum(1) as num_districts
	from fy2016_districts_deluxe_matr d16
	left join public.fy2015_districts_metrics_fy2016_methods_m d15
	on d16.esh_id = d15.district_esh_id
	where d16.include_in_universe_of_districts
	and d16.exclude_from_ia_cost_analysis = false
	and d15.exclude_from_analysis = false
	and d15.ia_monthly_cost > 0
	group by 1
),

overall as (
	select 
		sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2015,
		sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1))/1000000 as monthly_cost_2016,
		(sum(d16.ia_monthly_cost_total*(1-d16.discount_rate_c1)) - sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)))/
			sum(d15.ia_monthly_cost*(1-d16.discount_rate_c1)) as monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost > .1
					then 1
				else 0
			end) as num_districts_monthly_cost_increase,
		sum(case
				when (d16.ia_monthly_cost_total - d15.ia_monthly_cost)/d15.ia_monthly_cost < -.1
					then 1
				else 0
			end) as num_districts_monthly_cost_decrease,
		sum(1) as num_districts
	from fy2016_districts_deluxe_matr d16
	left join public.fy2015_districts_metrics_fy2016_methods_m d15
	on d16.esh_id = d15.district_esh_id
	where d16.include_in_universe_of_districts
	and d16.exclude_from_ia_cost_analysis = false
	and d15.exclude_from_analysis = false
	and d15.ia_monthly_cost > 0
),

agg as (
	select 
		ds.district_size, 
		'all' as locale, 
		ds.monthly_cost_2015,
		ds.monthly_cost_2016,
		ds.monthly_cost_increase,
		ds.num_districts_monthly_cost_increase,
		ds.num_districts_monthly_cost_decrease,
		ds.num_districts
	from dist_size ds

	UNION

	select 
		'all' as district_size, 
		l.locale, 
		l.monthly_cost_2015,
		l.monthly_cost_2016,
		l.monthly_cost_increase,
		l.num_districts_monthly_cost_increase,
		l.num_districts_monthly_cost_decrease,
		l.num_districts
	from locale l

	UNION

	select 
		'all' as district_size, 
		'all' as locale, 
		o.monthly_cost_2015,
		o.monthly_cost_2016,
		o.monthly_cost_increase,
		o.num_districts_monthly_cost_increase,
		o.num_districts_monthly_cost_decrease,
		o.num_districts
	from overall o
)

select
	*,
	num_districts_monthly_cost_increase/num_districts::numeric as pct_districts_monthly_cost_increase,
	num_districts_monthly_cost_decrease/num_districts::numeric as pct_districts_monthly_cost_decrease,
	num_districts_monthly_cost_increase/(num_districts_monthly_cost_decrease+num_districts_monthly_cost_increase)::numeric 
		as pct_districts_monthly_cost_increase_of_non_0,
	num_districts_monthly_cost_decrease/(num_districts_monthly_cost_decrease+num_districts_monthly_cost_increase)::numeric 
		as pct_districts_monthly_cost_decrease_of_non_0
from agg
order by district_size, locale