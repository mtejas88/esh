with nonfiber_district as (

  select distinct dl.district_esh_id

    from
      public.esh_allocations a

    join public.esh_line_items li
    on a.line_item_id = li.id

    left join (
      select
        flaggable_id,
        array_agg(label) as open_flag_labels,
        count(label) as num_open_flags

      from
        public.flags f

      where f.status = 'open'
      and f.flaggable_type = 'LineItem'

      group by
        flaggable_id
    ) f
    on li.id = f.flaggable_id

    left join entity_bens eb
    on a.recipient_ben = eb.ben

    --only looking at recipients that are districts
    join fy2017_district_lookup_matr dl
    on eb.entity_id::varchar = dl.district_esh_id

    where li.funding_year = 2017
      and li.broadband = true
      and li.isp_conditions_met = false
      and li.backbone_conditions_met = false
      and li.consortium_shared = false
      and li.num_lines != -1
      and (not('canceled' = any(f.open_flag_labels) or
               'video_conferencing' = any(f.open_flag_labels) or
               'exclude' = any(f.open_flag_labels))
          or f.open_flag_labels is null)
      and not(li.connect_category ilike '%Fiber%')
      and a.num_lines_to_allocate is not null
      and a.num_lines_to_allocate > 0

)

select 
  c.district_esh_id,
  c.fiber_target_status,
  c.exclude_from_wan_analysis,
  case
    --for districts that aren't targets, they just need to be fit for wan to be fit for campus
    --and have num_lines >= num_campuses
    when c.exclude_from_wan_analysis = false
     and c.fiber_target_status != 'Target'
     and da.lines_w_dirty >= dm.num_campuses
      then false
    --For districts that are targets and have an unscalable heirarchy_ia_connect_cat they are clean to the campus
    --because every school in the district needs a fiber internet connection
    WHEN df.fiber_target_status = 'Target'
      AND df.hierarchy_ia_connect_category IN  ('Cable','Copper','Satellite/LTE','Fixed Wireless')
      AND df.exclude_from_ia_analysis = FALSE
      then false
    --for all districts, if they are not fit for wan analysis then they are not fit for campus
    --or if they have less lines than campuses
    when c.exclude_from_wan_analysis = true
      or da.lines_w_dirty < dm.num_campuses
      then true
    --for targets, if they have any category = Incorrect Non-fiber or 'Correct Non-fiber and Incorrect Fiber' then they are not fit for campus
    when count(
              case 
                when c.category in ('Incorrect Non-fiber','Correct Non-fiber and Incorrect Fiber')
                  then c.campus_id
              end) > 0
      then true
    --for targets, if they have any non-fiber allocated to the district BEN then not fit
    when d.district_esh_id is not null
      then true
    --for targets, if they have any correct non fiber and every campus has a connection and not in the above then  fit for campus
    when count(
              case
                when c.category = 'Correct Non-fiber'
                  then c.campus_id
              end) > 0
     and count(case when c.category is null then c.campus_id end) = 0
      then false
    else true
  end as exclude_from_campus_analysis
            

from public.fy2017_campus_summary_matr c

left join nonfiber_district d
on c.district_esh_id = d.district_esh_id

left join public.fy2017_districts_aggregation_matr da
on c.district_esh_id = da.district_esh_id

left join public.fy2017_districts_metrics_matr dm
on c.district_esh_id = dm.esh_id

left join public.fy2017_districts_fiberpredeluxe_matr df
on c.district_esh_id = df.esh_id


group by 
  c.district_esh_id,
  d.district_esh_id,
  c.non_fiber_lines_w_dirty,
  c.exclude_from_wan_analysis,
  da.lines_w_dirty,
  dm.num_campuses,
  c.fiber_target_status


/*
Author: Jeremy Holtzman
Created On Date: 9/8/2017
Modied: 9/20/17 - JH need at least as many lines than campuses to be fit for campus analysis
Updated On: 9/28/2017 Chris Kemnitzer added ia heirarchy
Name of QAing Analyst(s):
Purpose: use the campus summary to determine if fit for campus analysis
Methodology:
1. All districts that are not fiber targets and are fit for WAN analysis 
   and at least as many lines as campuses are fit for campus analysis
2. All districts that are not fit for WAN analysis are NOT fit for campus analysis
3. Remaining districts that have any incorrectly allocated non-fiber, non-fiber to the district, 
    or a campus with Correct non-fiber and incorrect fiber are NOT fit for campus analysis
4. Remaining districts that have any correct non-fiber and every campus has some sort of connection are fit fot campus analysis
5. Remaining districts are NOT fit for campus analysis

*/
