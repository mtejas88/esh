select  dd.esh_id,
        dd.nces_cd as district_nces_cd,
        dd.name as district_name,
        dd.postal_cd as district_postal_cd,
        dd.latitude as district_latitude,
        dd.longitude as district_longitude,
        dd.locale as district_locale,
        dd.num_schools as district_num_schools,
        dd.num_students as district_num_students,
        dd.exclude_from_ia_analysis as district_exclude_from_ia_analysis,
        fbts.fiber_target_status as district_fiber_target_status,
        case
            when    dd.exclude_from_ia_analysis = false
                    and fbts.fiber_target_status = 'Target'
                    and dd.current_known_unscalable_campuses +
                            dd.current_assumed_unscalable_campuses = 0
                    and dd.non_fiber_lines > 0
              then dd.non_fiber_lines
            when    dd.exclude_from_ia_analysis = false
                    and fbts.fiber_target_status = 'Target'
                    and dd.current_known_unscalable_campuses +
                            dd.current_assumed_unscalable_campuses > 0
              then  dd.current_known_unscalable_campuses +
                      dd.current_assumed_unscalable_campuses
            when    fbts.fiber_target_status in ('Target', 'No Data')
                    and num_campuses in (1,2)
                then 1
            when    fbts.fiber_target_status in ('Target', 'No Data')
                then num_campuses::numeric * .34
            else dd.current_known_unscalable_campuses +
                    dd.current_assumed_unscalable_campuses
        end as district_num_campuses_unscalable,
        campus_schools.campus_id,
        campus_schools.campus_school_names,
        campus_schools.campus_school_nces_cds,
        campus_schools.sample_campus_nces_cd,
        campus_schools.campus_school_count,
        campus_schools.campus_student_count,
        campus_schools.sample_campus_latitude,
        campus_schools.sample_campus_longitude,
        campus_schools.sample_campus_locale

from endpoint.fy2016_districts_deluxe dd
left join endpoint.fy2016_fiber_bw_target_status fbts
on dd.esh_id = fbts.esh_id
left join (
  select district_esh_id,
         case
            when campus_id = 'Unknown'
                then address
            else campus_id
         end as campus_id,
         array_agg(name) as campus_school_names,
         array_agg(school_nces_code) as campus_school_nces_cds,
         max(school_nces_code) as sample_campus_nces_cd,
         count(*) as campus_school_count,
         sum(num_students) as campus_student_count,
         min("LATCOD") as sample_campus_latitude,
         min("LONCOD") as sample_campus_longitude,
         min(locale) as sample_campus_locale
-- 11/2 discussion recap; min/max rule for identifying sample value for each campus is somewhat arbitrary
-- let's either document that it's arbitrary (or it wasn't but unclear of Greg's decisions) or
-- re-do it by assigning row number
  from endpoint.fy2016_schools_demog  sd
  left join public.sc131a sc
  on sd.school_nces_code = sc."NCESSCH"
  where district_include_in_universe_of_districts

  group by  district_esh_id,
         case
            when campus_id = 'Unknown'
                then address
            else campus_id
         end

) campus_schools

on dd.esh_id = campus_schools.district_esh_id

where dd.include_in_universe_of_districts
--Not Target districts don't have any unscalable campuses
    and fbts.fiber_target_status != 'Not Target'
--Don't include Potential Targets if they are dirty or have 0 unscalable campuses
    and not(fbts.fiber_target_status = 'Potential Target'
            and (   dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses = 0
                    or dd.exclude_from_ia_analysis = true
                )
            )

/*
Author: Justine Schott
Created On Date: 11/1/2016
Last Modified Date:
Name of QAing Analyst(s):
Purpose: List potential unscalable campuses in our sample
Methodology:
*/