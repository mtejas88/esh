with a as
 (select esh_id
 from public.fy2016_districts_deluxe_matr
 where
 include_in_universe_of_districts
 and district_type = 'Traditional'
 and exclude_from_ia_analysis = 'False'
 and upgrade_indicator = 'True')

 select
 (select count(esh_id) from
 public.fy2017_districts_deluxe_matr d17
 where
 d17.include_in_universe_of_districts
 and  d17.district_type = 'Traditional'
 and  d17.exclude_from_ia_analysis = 'False'
 and  d17.upgrade_indicator = 'True'
 and d17.esh_id not in (select * from a)
 ) as "total_new_upgraders_2017",

 (
  select
 count(distinct d17.esh_id)
 from public.fy2017_districts_deluxe_matr d17
 left join public.fy2016_districts_deluxe_matr d16
 on d17.esh_id = d16.esh_id
where
 d17.include_in_universe_of_districts
 and  d17.district_type = 'Traditional'
 and  d17.exclude_from_ia_analysis = 'False'
 and  d17.upgrade_indicator = 'True'
 and  d17.esh_id not in (select * from a)
 and d17.ia_bw_mbps_total >= (d16.ia_bw_mbps_total*1.10)
 ) as "unique_upgraders_2017_with_10pc_more_bw",

 (select count(esh_id) from
 public.fy2016_districts_deluxe_matr d17
 where
 d17.include_in_universe_of_districts
 and  d17.district_type = 'Traditional'
 and  d17.exclude_from_ia_analysis = 'False'
 and  d17.upgrade_indicator = 'True'
 ) as "total_upgraders_2016",

 (select
 count(distinct d16.esh_id)
 from
  public.fy2016_districts_deluxe_matr d16
  left join fy2015_districts_deluxe_m d15
  on d16.esh_id = d15.esh_id::varchar
 where
 d16.include_in_universe_of_districts
 and d16.district_type = 'Traditional'
 and d16.exclude_from_ia_analysis = 'False'
 and d16.upgrade_indicator = 'True'
 and d16.ia_bw_mbps_total >= (d15.total_ia_bw_mbps * 1.10)
) as "unique_upgraders_2016_with_10pc_more_bw"
