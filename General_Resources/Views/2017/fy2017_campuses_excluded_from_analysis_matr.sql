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

),

district_summary as (
select d.esh_id,
count(case when c.category ilike '%non-fiber%' then c.campus_id end) as num_campuses_nonfiber
from public.fy2017_campus_summary_matr c

left join public.fy2017_districts_deluxe_matr d
on c.district_esh_id = d.esh_id

left join nonfiber_district n
on c.district_esh_id = n.district_esh_id

group by 1

)

select c.district_esh_id,
c.campus_id,
d.exclude_from_wan_analysis,
d.exclude_from_ia_analysis,
d.exclude_from_campus_analysis,
d.fiber_target_status,
c.category,
case 
  when d.exclude_from_campus_analysis = false
   then false
  --if non-fiber goes to district ben, than the campus is excluded from campus analysis
  when n.district_esh_id is not null
    then true
  --if excluded from wan analysis, then not fit
  when d.exclude_from_wan_analysis = true
    then true
  when c.category is null
    then true
  when d.fiber_target_status = 'Target'
   and ds.num_campuses_nonfiber::numeric = 0
    then true
  when c.category in ('Incorrect Non-fiber', 'Correct Non-fiber and Incorrect Fiber', 'Incorrect Fiber', 'No lines received')
    then true
  when c.category in ('Correct Fiber', 'Correct Non-fiber')
    then false
end as campuses_excluded_from_campus_analysis


from public.fy2017_campus_summary_matr c

left join public.fy2017_districts_deluxe_matr d
on c.district_esh_id = d.esh_id

left join nonfiber_district n
on c.district_esh_id = n.district_esh_id

left join district_summary ds
on d.esh_id = ds.esh_id

/*
Author: Jeremy Holtzman
Created On Date: 9/8/2017
Name of QAing Analyst(s):
Purpose: to list out which campuses are clean to the campus and which are not
Methodology:
hierarchy:
1. If district is fit for campus analysis, then the campuses are good
2. If a non-fiber line goes to the district BEN, then the campus is not fit for campus analysis
3. If the district is not fit for wan analysis, then the campus is not fit for campus analysis
4. If the campus receives no services, then the campus is not fit for campus analysis
5. If the district is a target but there is no nonfiber, then the campus is not fit for campus analysis
6. If the campus has any incorrectly allocated line, then the campus is not fit for campus analysis
7. If the campus has correctly allocated fiber or non-fiber, then the campus IS fit for campus analysis
*/
