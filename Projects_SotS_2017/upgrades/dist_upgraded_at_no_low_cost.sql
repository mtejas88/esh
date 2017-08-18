
select count(a.esh_id) from
public.fy2017_districts_deluxe_matr a
left join public.fy2016_districts_deluxe_matr b
on a.esh_id = b.esh_id
where
a.include_in_universe_of_districts = 'True'
and a.district_type = 'Traditional'
and a.upgrade_indicator = 'True'
and a.exclude_from_ia_analysis = 'False'
and a.exclude_from_ia_cost_analysis = 'False'
and a.ia_bw_mbps_total > b.ia_bw_mbps_total
and a. ia_monthly_cost_total <= b.ia_monthly_cost_total
