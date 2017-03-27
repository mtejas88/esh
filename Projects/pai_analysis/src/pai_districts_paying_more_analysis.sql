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
)

select 
	case
		when bw_mbps_increase > .1
			then 'bw increase'
		when bw_mbps_increase < -.1
			then 'bw decrease'
		else 'same bw'
	end as bw_category,
	count(*)
from districts
where monthly_cost_increase > .1
group by 1