select  distinct dd16.esh_id as esh_id_2016,
        dd16.postal_cd as postal_cd_2016,
        dd16.locale as locale_2016,
        dd16.num_students as num_students_2016,
        dd16.num_schools as num_schools_2016,
        ia_bw_mbps_total_2016,
        d15.esh_id as esh_id_2015,
        d15.postal_cd as postal_cd_2015,
        d15.locale as locale_2015,
        d15.num_students as num_students_2015,
        d15.num_schools as num_schools_2015,
        ia_bw_mbps_total_2015,
        case
          when ia_bw_mbps_total_2015 > 0
            then  round((ia_bw_mbps_total_2016-ia_bw_mbps_total_2015)/ia_bw_mbps_total_2015,2) >= .11
                  or ( (ia_bw_mbps_total_2016 - ia_bw_mbps_total_2015) % 50 = 0
                        and (ia_bw_mbps_total_2016 - ia_bw_mbps_total_2015) > 0)
          when ia_bw_mbps_total_2015 = 0
            then true
          else false
        end as upgrade_indicator

from (
  select *,
  round(ia_bw_mbps_total::numeric,0) as ia_bw_mbps_total_2016
  from public.fy2016_districts_predeluxe_matr
  where include_in_universe_of_districts
  and district_type = 'Traditional'
  and exclude_from_ia_analysis = false
  and postal_cd not in ('RI', 'HI', 'DE')
) dd16
left join (
  select *,
  round(total_ia_bw_mbps::numeric,0) as ia_bw_mbps_total_2015
  from public.fy2015_districts_deluxe_m
  where exclude_from_analysis = false
) d15
on dd16.esh_id = d15.esh_id::varchar
where d15.esh_id is not null

/*
Author: Justine Schott
Created On Date: 12/9/2016
Last Modified Date:
Name of QAing Analyst(s):
Purpose: 2016 district data in terms of 2016 methodology with targeting assumptions built in
Methodology:
*/