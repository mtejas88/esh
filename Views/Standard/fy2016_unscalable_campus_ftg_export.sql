select  distinct  dd.esh_id,
                  dd.nces_cd as district_nces_cd,
                  dd.name as district_name,
                  dd.postal_cd as district_postal_cd,
                  dd.latitude as district_latitude,
                  dd.longitude as district_longitude,
                  dd.locale as district_locale,
                  dd.num_schools as district_num_schools,
                  dd.num_students as district_num_students,
                  case
                    when dd.discount_rate_c1 is null
                      then round(state_agg_dr::numeric,2)
                    else dd.discount_rate_c1::numeric
                  end as c1_discount_rate_or_state_avg,
                  case
                  --Not Target districts don't have any unscalable campuses
                    when  fbts.fiber_target_status in ('Target', 'No Data')
                          or (fbts.fiber_target_status = 'Potential Target'
                            and (   dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses > 0
                                    and dd.exclude_from_ia_analysis = false
                                )
                          )
                      then '1: Fit for FTG, Target'
                    when  fbts.fiber_target_status = 'Potential Target'
                          and dd.exclude_from_ia_analysis = true
                      then '3: Not Fit for FTG'
                    else '2: Fit for FTG, Not Target'
                  end as denomination,
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

left join (
  select
    recipient_postal_cd,
    sum(bb_funding)/sum(bb_cost) as state_agg_dr
  from (
    select
      sr.recipient_id,
      sr.recipient_postal_cd,
      sum(sr.line_item_district_monthly_cost_total) as bb_cost,
      sum(sr.line_item_district_monthly_cost_total*(case
                                                      when discount_rate is null
                                                        then 70
                                                      else discount_rate::numeric
                                                    end/100)) as bb_funding
    from endpoint.fy2016_services_received sr
    left join fy2016.line_items li
    on sr.line_item_id = li.id
    left join fy2016.frns
    on li.frn = frns.frn

    where sr.broadband
    and recipient_include_in_universe_of_districts

    group by  sr.recipient_id,
              sr.recipient_postal_cd
  ) districts_bb_recipient_2016
  where bb_cost > 0
  group by recipient_postal_cd
) state_agg_dr
on dd.postal_cd = state_agg_dr.recipient_postal_cd


where dd.include_in_universe_of_districts

/*
Author: Justine Schott
Created On Date: 11/3/2016
Last Modified Date:
Name of QAing Analyst(s):
Purpose: List potential unscalable campuses in our sample
Methodology:
*/