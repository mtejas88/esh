select  distinct dd17.esh_id as esh_id_2017,
        dd17.postal_cd as postal_cd_2017,
        dd17.locale as locale_2017,
        dd17.num_students as num_students_2017,
        dd17.num_schools as num_schools_2017,
        dd17.ia_bw_mbps_total as ia_bw_mbps_2017,
        d16.esh_id as esh_id_2016,
        d16.postal_cd as postal_cd_2016,
        d16.locale as locale_2016,
        d16.num_students as num_students_2016,
        d16.num_schools as num_schools_2016,
        d16.ia_bw_mbps_total as ia_bw_mbps_2016,

        case

          when d16.ia_bw_mbps_total > 0
            then ((dd17.ia_bw_mbps_total - d16.ia_bw_mbps_total)/d16.ia_bw_mbps_total) >= .11 --added minus sign
                  or ( (dd17.ia_bw_mbps_total - d16.ia_bw_mbps_total) * .50 = 0
                        and (dd17.ia_bw_mbps_total - d16.ia_bw_mbps_total) > 0)

          when d16.ia_bw_mbps_total = 0
            then true
          else false
        end as upgrade_indicator

from (

  select *
  --round(ia_bw_mbps_total::numeric as ia_bw_mbps_total __ per Jusine this doesn't have to be rounded this year -- there were issues with 2015 data that caused rounding to be necessary
  from public.fy2017_districts_predeluxe_matr
  where include_in_universe_of_districts = true
  and include_in_universe_of_districts_all_charters = true
  --and district_type = 'Traditional' __per Justine, this line can be removed -- analysis for 2015 was only done on traditional districts, but that is not the case for 2016
  and exclude_from_ia_analysis = false
  and postal_cd not in ('RI', 'HI', 'DE')
) dd17

left join (
  select *
  --round(total_ia_bw_mbps::numeric,0) as d16.ia_bw_mbps_total __ per Justne, this doesn't have to be rounded this year -- there were issues with 2015 data that caused rounding to be necessary
  from public.fy2016_districts_predeluxe_matr --fixing spelling of predeluxe
/*comparing 2016 against 2017*/
  where exclude_from_ia_analysis = false --changed from "exclude_from_analysis" to "exclude_from_ia_analysis"
) d16
on dd17.esh_id::varchar = d16.esh_id::varchar --forcing data type to be varchar, just in case underlying tables have discrepancy
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
