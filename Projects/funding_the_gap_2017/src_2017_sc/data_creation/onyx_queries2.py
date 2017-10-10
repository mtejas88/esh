from pandas import DataFrame

#to-do: query returns traditional, BIE, and charter in AZ. do we want to include more?

def getCampuses( conn ) :
    cur = conn.cursor()
    cur.execute( """\
      select  distinct  dd.esh_id,
                  dd.nces_cd as district_nces_cd,
                  dd.name as district_name,
                  dd.postal_cd as district_postal_cd,
                  dd.latitude as district_latitude,
                  dd.longitude as district_longitude,
                  dd.locale as district_locale,
                  dd.num_campuses as district_num_campuses,
                  dd.num_schools as district_num_schools,
                  dd.num_students as district_num_students,
                  case
                    when dd.discount_rate_c1_matrix is null
                      then round(state_agg_dr::numeric,2)
                    else dd.discount_rate_c1_matrix
                  end as c1_discount_rate_or_state_avg,
                  case
                    when  dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses > 0
                      then '1: Fit for FTG, Target'
                    else '2: Fit for FTG, Not Target'
                  end as denomination,
                  dd.exclude_from_ia_analysis as district_exclude_from_ia_analysis,
                  dd.fiber_target_status as district_fiber_target_status,
                  dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses as district_num_campuses_unscalable,
                  dd.hierarchy_ia_connect_category as district_hierarchy_ia_connect_category,

                  case when dd.esh_id = campus_category.district_esh_id
                  and campus_schools.campus_id = campus_category.campus_id
                  and category  ilike '%Correct Non-fiber%' and category != 'Incorrect Non-fiber'
                  then 1 else 0 end as correct_nonfiber_match,    

                  case when dd.esh_id = campus_category.district_esh_id
                  and campus_schools.campus_id = campus_category.campus_id
                  and category  = 'Correct Fiber' 
                  then 1 else 0 end as correct_fiber_match,  

                  campus_schools.campus_id,
                  campus_schools.campus_school_names,
                  campus_schools.campus_school_nces_cds,
                  campus_schools.sample_campus_nces_cd,
                  campus_schools.campus_school_count,
                  campus_schools.campus_student_count,
                  campus_schools.sample_campus_latitude,
                  campus_schools.sample_campus_longitude,
                  campus_schools.sample_campus_locale,
                  campus_schools.sample_campus_ulocal

from public.fy2017_districts_deluxe_matr dd
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
         min(locale) as sample_campus_locale,
         min("ULOCAL") as sample_campus_ulocal
-- 11/2 discussion recap min/max rule for identifying sample value for each campus is somewhat arbitrary
-- let's either document that it's arbitrary (or it wasn't but unclear of Greg's decisions) or
-- re-do it by assigning row number
  from public.fy2017_schools_demog_matr  sd
  left join public.sc141a sc
  on sd.school_nces_code = sc."NCESSCH"
  where district_include_in_universe_of_districts

  group by district_esh_id,
           case
              when campus_id = 'Unknown'
                  then address
              else campus_id
           end

) campus_schools
on dd.esh_id = campus_schools.district_esh_id

left join (
select ce.district_esh_id, ce.campus_id, category
  from public.fy2017_campuses_excluded_from_analysis_matr ce
  join public.fy2017_schools_demog_matr  sd
  on ce.district_esh_id = sd.district_esh_id
  and ce.campus_id = sd.campus_id
  where district_include_in_universe_of_districts
  and exclude_from_campus_analysis = false

  group by ce.district_esh_id, ce.campus_id, category
  ) campus_category
on dd.esh_id = campus_category.district_esh_id
and campus_schools.campus_id = campus_category.campus_id

left join (
  select
    recipient_postal_cd,
    sum(bb_funding)/sum(bb_cost) as state_agg_dr
  from (
    select
      sr.recipient_id,
      sr.recipient_postal_cd,
      sum(case
            when discount_rate is null
              then 0
            else sr.line_item_district_monthly_cost_total
          end) as bb_cost,
      sum(sr.line_item_district_monthly_cost_total*(case
                                                      when discount_rate is null
                                                        then 0
                                                      else discount_rate::numeric
                                                    end/100)) as bb_funding
    from public.fy2017_services_received_matr sr
    left join public.fy2017_esh_line_items_v li
    on sr.line_item_id = li.id
    left join fy2017.frns
    on li.frn = frns.frn

    where sr.broadband
    and recipient_include_in_universe_of_districts
    and inclusion_status in ('clean_with_cost', 'dirty')
    and sr.erate
    and li.funding_year = 2017

    group by  sr.recipient_id,
              sr.recipient_postal_cd
  ) districts_bb_recipient_2017
  where bb_cost > 0
  group by recipient_postal_cd
) state_agg_dr
on dd.postal_cd = state_agg_dr.recipient_postal_cd

where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
order by esh_id;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)

def getDistricts( conn ) :
    cur = conn.cursor()
    cur.execute("""\
select  distinct  dd.esh_id,
                  dd.nces_cd as district_nces_cd,
                  dd.name as district_name,
                  dd.postal_cd as district_postal_cd,
                  dd.latitude as district_latitude,
                  dd.longitude as district_longitude,
                  dd.locale as district_locale,
                  dd.num_campuses as district_num_campuses,
                  dd.num_schools as district_num_schools,
                  dd.num_students as district_num_students,
                  case
                    when dd.discount_rate_c1_matrix is null
                      then round(state_agg_dr::numeric,2)
                    else dd.discount_rate_c1_matrix
                  end as c1_discount_rate_or_state_avg,
                  case
                    when  dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses > 0
                      then '1: Fit for FTG, Target'
                    else '2: Fit for FTG, Not Target'
                  end as denomination,
                  dd.exclude_from_ia_analysis as district_exclude_from_ia_analysis,
                  dd.fiber_target_status as district_fiber_target_status,
                  dd.current_known_unscalable_campuses + dd.current_assumed_unscalable_campuses as district_num_campuses_unscalable,
                  dd.hierarchy_ia_connect_category as district_hierarchy_ia_connect_category

from public.fy2017_districts_deluxe_matr dd
left join (
  select
    recipient_postal_cd,
    sum(bb_funding)/sum(bb_cost) as state_agg_dr
  from (
    select
      sr.recipient_id,
      sr.recipient_postal_cd,
      sum(case
            when discount_rate is null
              then 0
            else sr.line_item_district_monthly_cost_total
          end) as bb_cost,
      sum(sr.line_item_district_monthly_cost_total*(case
                                                      when discount_rate is null
                                                        then 0
                                                      else discount_rate::numeric
                                                    end/100)) as bb_funding
    from public.fy2017_services_received_matr sr
    left join public.fy2017_esh_line_items_v li
    on sr.line_item_id = li.id
    left join fy2017.frns
    on li.frn = frns.frn

    where sr.broadband
    and recipient_include_in_universe_of_districts
    and inclusion_status in ('clean_with_cost', 'dirty')
    and sr.erate
    and li.funding_year = 2017

    group by  sr.recipient_id,
              sr.recipient_postal_cd
  ) districts_bb_recipient_2017
  where bb_cost > 0
  group by recipient_postal_cd
) state_agg_dr
on dd.postal_cd = state_agg_dr.recipient_postal_cd

where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
order by esh_id;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)
