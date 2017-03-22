select 
c.name as consultant_names,
c.consultant_registration_number as consultant_num,
count(distinct d.esh_id) as num_districts_served,
count(distinct case when d.exclude_from_ia_analysis = false then d.esh_id end) as num_clean_districts_served,
count(distinct case when d.exclude_from_ia_analysis = true then d.esh_id end) as num_dirty_districts_served,
count(distinct case when d.fiber_target_status = 'Target' then d.esh_id end) as num_fiber_target_districts_served,
count(distinct case when d.fiber_target_status = 'Potential Target' then d.esh_id end) as num_potential_fiber_target_districts_served,
count(distinct case when d.fiber_target_status = 'Not Target' then d.esh_id end) as num_not_fiber_target_districts_served,
count(distinct case when d.fiber_target_status = 'No Data' then d.esh_id end) as num_no_data_fiber_districts_served,
count(distinct case when d.bw_target_status = 'Target' then d.esh_id end) as num_bw_target_districts_served,
count(distinct case when d.bw_target_status = 'Potential Target' then d.esh_id end) as num_potential_bw_target_districts_served,
count(distinct case when d.bw_target_status = 'Not Target' then d.esh_id end) as num_not_bw_target_districts_served,
count(distinct case when d.bw_target_status = 'No Data' then d.esh_id end) as num_no_data_bw_districts_served,
count(distinct case when exclude_from_ia_cost_analysis = false and meeting_knapsack_affordability_target = True then d.esh_id end) as num_meeting_affordability_districts_served,
count(distinct case when exclude_from_ia_cost_analysis = false and meeting_knapsack_affordability_target = False then d.esh_id end) as num_not_meeting_affordability_districts_served,
count(distinct case when exclude_from_ia_cost_analysis = true then d.esh_id end) as num_unknown_affordability_districts_served,
count(distinct case when d.fiber_target_status = 'Target' or d.bw_target_status = 'Target' then d.esh_id end) as num_fiber_or_bw_target_districts_served,
count(distinct case when d.fiber_target_status = 'Potential Target' or d.bw_target_status = 'Potential Target' then d.esh_id end) as num_fiber_or_bw_potential_target_districts_served,
count(c.application_number) as num_applications


from public.fy2016_district_lookup_matr dl

left join public.entity_bens eb
on dl.esh_id::numeric = eb.entity_id

left join public.fy2016_districts_deluxe_matr d
on dl.district_esh_id = d.esh_id

join fy2016.consultants c
on eb.ben = c.applicant_ben

join fy2016.basic_informations b
on b.application_number = c.application_number
and b.category_of_service = '1'

where d.include_in_universe_of_districts 
and c.application_number in (
  select li.application_number
  from fy2016.line_items li
  join public.fy2016_services_received_matr sr
  on li.id = sr.line_item_id
)

group by  c.name,
          c.consultant_registration_number

order by c.name asc

/*
Author: Jeremy Holtzman
Created On Date: 3/8/2017
Name of QAing Analyst(s):
Purpose: To break out the consultants in based on the number of districts (and types of districts) they serve.
Methodology: Grouped by consultant. Only districts in our universe are included. Only C1 line items are included.
             Only applications that are received by the district are included).
*/