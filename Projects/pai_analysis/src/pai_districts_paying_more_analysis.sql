with districts as (
	select
		d16.district_size,
		d16.locale,
		d15.ia_monthly_cost*(1-d16.discount_rate_c1) as monthly_cost_2015,
		d16.ia_monthly_cost_total*(1-d16.discount_rate_c1) as monthly_cost_2016,
		(d16.ia_monthly_cost_total - d15.ia_monthly_cost)/
			d15.ia_monthly_cost as monthly_cost_increase,
		d15o.total_ia_bw_mbps as bw_mbps_2015,
		d16.ia_bw_mbps_total as bw_mbps_2016,
		case
			when d15o.total_ia_bw_mbps > 0
				then (d16.ia_bw_mbps_total - d15o.total_ia_bw_mbps)/
						d15o.total_ia_bw_mbps
			else 1
		end as bw_mbps_increase
	from fy2016_districts_deluxe_matr d16
	left join public.fy2015_districts_metrics_fy2016_methods_m d15
	on d16.esh_id = d15.district_esh_id
	left join public.fy2015_districts_deluxe_m d15o
	on d16.esh_id = d15o.esh_id::varchar
	where d16.include_in_universe_of_districts
	and d16.exclude_from_ia_cost_analysis = false
	and d15.exclude_from_analysis = false
	and d15.ia_monthly_cost > 0
),

cost_agg as (
	select
		locale,
		case
			when monthly_cost_increase > .1
				then 'cost increase'
			when monthly_cost_increase < -.1
				then 'cost decrease'
			else 'same cost'
		end as cost_category,
		count(*) as sample,
		sum(case
				when bw_mbps_increase > .1
					then 1
				else 0
			end) as num_districts_bw_increase,
		sum(case
				when bw_mbps_increase < -.1
					then 1
				else 0
			end) as num_districts_bw_decrease,
		sum(case
				when bw_mbps_increase >= -.1 and bw_mbps_increase <= .1
					then 1
				else 0
			end) as num_districts_bw_flat,
		median(bw_mbps_increase) as median_bw_mbps_increase,
		sum(monthly_cost_2015)/1000000 as aggregate_monthly_cost_m_2015,
		sum(monthly_cost_2016)/1000000 as aggregate_monthly_cost_m_2016,
		sum(bw_mbps_2015)/1000 as aggregate_bw_gbps_2015,
		sum(bw_mbps_2016)/1000 as aggregate_bw_gbps_2016,
		median(bw_mbps_2016) as median_bw_mbps_2016
	from districts
	group by 1, 2
)

select
	locale,
	cost_category,
	num_districts_bw_increase/(num_districts_bw_increase+num_districts_bw_decrease+num_districts_bw_flat)::numeric as pct_districts_bw_increase,
	num_districts_bw_decrease/(num_districts_bw_increase+num_districts_bw_decrease+num_districts_bw_flat)::numeric as pct_districts_bw_decrease,
	num_districts_bw_flat/(num_districts_bw_increase+num_districts_bw_decrease+num_districts_bw_flat)::numeric as pct_districts_bw_flat,
	(aggregate_monthly_cost_m_2016 - aggregate_monthly_cost_m_2015)/aggregate_monthly_cost_m_2015 as pct_increase_monthly_cost,
	(aggregate_bw_gbps_2016 - aggregate_bw_gbps_2015)/aggregate_bw_gbps_2015 as pct_increase_bw,
	median_bw_mbps_increase,
	median_bw_mbps_2016,
	sample
from cost_agg