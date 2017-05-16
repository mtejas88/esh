select  distinct dd17.esh_id as esh_id_2017,
        dd17.postal_cd as postal_cd_2017,
        dd17.locale as locale_2017,
        dd17.num_students as num_students_2017,
        dd17.num_schools as num_schools_2017,
        ia_bw_mbps_total_2017,
        d16.esh_id as esh_id_2016,
        d16.postal_cd as postal_cd_2016,
        d16.locale as locale_2016,
        d16.num_students as num_students_2016,
        d16.num_schools as num_schools_2016,
        ia_bw_mbps_total_2016,

        case

          when ia_bw_mbps_total_2016 > 0
            then  round((ia_bw_mbps_total_2017ia_bw_mbps_total_2016)/ia_bw_mbps_total_2016,2) >= .11
                  or ( (ia_bw_mbps_total_2017 - ia_bw_mbps_total_2016) % 50 = 0
                        and (ia_bw_mbps_total_2017 - ia_bw_mbps_total_2016) > 0)

          when ia_bw_mbps_total_2016 = 0
            then true
          else false
        end as upgrade_indicator

from (

  select *,
  round(ia_bw_mbps_total::numeric,0) as ia_bw_mbps_total_2017
  from public.fy2017_districts_predeluxe_matr
  where include_in_universe_of_districts
  and district_type = 'Traditional'
  and exclude_from_ia_analysis = false
  and postal_cd not in ('RI', 'HI', 'DE')
) dd17

left join (
  select *,
  round(total_ia_bw_mbps::numeric,0) as ia_bw_mbps_total_2016
  from public.fy2016_districts_prdeluxe_matr
/*comparing 2016 against 2017*/
  where exclude_from_analysis = false
) d16
on dd17.esh_id = d16.esh_id::varchar
where d16.esh_id is not null



/*

Author: Justine Schott
Created On Date: 12/9/2017
Last Modified Date:
Name of QAing Analyst(s):
Purpose: 2017 district data in terms of 2017 methodology with targeting assumptions built in
Methodology:

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise




*/
