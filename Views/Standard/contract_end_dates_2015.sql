/*
Date Created: Spring 2016
Date Last Modified : 06/02/2016
Author(s): Justine Schott
QAing Analyst(s): Jess Seok
Purpose: For each district, find the earliest contract end date and the end date for the largest IA contract.
*/

/*Joins "line_items" table to add relevant cost, bandwidth, connection type, and purpose information; joins "districts" table
to add demographic data used in metric calculations*/
with services_received as (
      select ldli.district_esh_id as recipient_id,
      d.name as recipient_name,
      d.postal_cd,
      ldli.line_item_id,
      li.consortium_shared,

--classifies circuits as either "Shared IA", "Backbone", or "District-dedicated"
      case when li.consortium_shared=true 
            and li.ia_conditions_met=true
              then 'Shared IA'
           when 'backbone'=any(li.open_flags) or (
              li.consortium_shared=true 
            and li.ia_conditions_met!=true
            )
              then 'Backbone'
              else 'District-dedicated' 
      end as shared_service,

--limits lines received by district to the total num_lines listed in the line item, unless the line item is allocated to multiple districts
      case when li.consortium_shared=true 
            OR 'backbone'=any(open_flags)
              then 'Shared Circuit'
              else ldli.allocation_lines::varchar 
      end as quantity_of_lines_received_by_district,

      li.bandwidth_in_mbps,
      li.connect_type,
      li.connect_category,
      li.purpose,
      li.wan,

/*For "District-dedicated circuits", the district share of the line item cost is calculated by 
multiplying the line item cost by the proportion of the total num_lines allocated to 
the district (see previous comment).  For "Shared IA" and "Backbone" line items, line item cost is divided 
proportionally between recipient districts based on their number of 
students (e.g. num_students in district/num_students in ALL districts served by line item)*/ 

      case when li.consortium_shared=false 
            and (not('backbone'=any(li.open_flags)) or li.open_flags is null)
            and li.total_cost::numeric>0 
            and li.num_lines!=0 
              then (ldli.allocation_lines::numeric/li.num_lines)*(li.total_cost::numeric)
           when li.consortium_shared=true 
            OR 'backbone'=any(li.open_flags) 
              then (d.num_students::numeric/district_info_by_li.num_students_served)*(li.total_cost::numeric) 
              else 0
      end/
      case when li.orig_r_months_of_service is not null 
           and li.orig_r_months_of_service!=0 
            then li.orig_r_months_of_service 
            else 12 
      end as line_item_district_monthly_cost,

--if months of service is null or zero, we assume that the services are in use throughout the entirety of the E-rate cycle

      case when li.orig_r_months_of_service is not null 
           and li.orig_r_months_of_service!=0 
            then li.total_cost::numeric/li.orig_r_months_of_service 
            else li.total_cost::numeric/12 
      end as "line_item_total_monthly_cost",

      ldli.allocation_lines as "cat.1_allocations_to_district",
      li.num_lines as "line_item_total_num_lines",
      li.total_cost as "line_item_total_cost",
      li.rec_elig_cost as "line_item_recurring_elig_cost",
      li.one_time_eligible_cost as "line_item_one-time_cost",
      li.orig_r_months_of_service,
      li.applicant_id,
      li.applicant_name,
      li.isp_conditions_met,
      li.internet_conditions_met,
      li.ia_conditions_met,
      li.wan_conditions_met,
      li.upstream_conditions_met,
      li.broadband,
      li.service_provider_name,
      li.exclude,
      array_to_string(li.open_flags,', ') as open_flags,
      
      case when 'exclude'=any(open_flags) then true else false end as dqs_excluded,
      
      case when d.ia_cost_per_mbps!='Insufficient data' 
            and d.ia_cost_per_mbps!='Infinity' 
            and d.ia_cost_per_mbps!='NaN' 
              then d.ia_cost_per_mbps::numeric/12 
              else null 
      end as district_monthly_ia_cost_per_mbps,

--total IA "backed out" from metrics by multiplying bandwidth per student by num_students
      case when d.ia_bandwidth_per_student!='Insufficient data' 
            and d.num_students!='No data' 
              then ((d.ia_bandwidth_per_student::numeric*d.num_students::bigint)/1000)::int
              else null 
      end as district_total_ia_rounded_to_nearest_mbps,

      d.ia_bandwidth_per_student,
      d.num_students,
      d.num_students_and_staff,
      d.num_schools,
      d.latitude,
      d.longitude,
      d.locale,
      d.district_size,
      d.exclude_from_analysis,
      d.consortium_member,
      'n/a' as recipient_districts,
      'n/a' as recipient_postal_cd,
      case 
        when d.exclude_from_analysis = true
          then 'exclude dirty'
          else 'include clean'
      end as dirty_status,
      spc.reporting_name

      from lines_to_district_by_line_item ldli

      left join line_items li
      on ldli.line_item_id=li.id

      left join (
          select distinct name, reporting_name
          from service_provider_categories
      ) spc
      on li.service_provider_name = spc.name

      left join districts d
      on ldli.district_esh_id=d.esh_id

--Group by line_item_id to yield students served by each line item 
      left join (
                  select  ldli.line_item_id,
                          sum(d.num_students::numeric) as num_students_served

                  from lines_to_district_by_line_item ldli

                  left join districts d
                  on ldli.district_esh_id = d.esh_id

                  left join line_items li
                  on ldli.line_item_id = li.id

                  where li.consortium_shared=true 
                     OR 'backbone'=any(li.open_flags)

                  group by ldli.line_item_id
          ) district_info_by_li
      on ldli.line_item_id=district_info_by_li.line_item_id

      where li.broadband=true  
       and (li.consortium_shared=false 
         OR li.ia_conditions_met=true 
         OR li.wan_conditions_met=true 
         OR li.upstream_conditions_met=true 
         OR 'backbone'=any(li.open_flags)
       )  
       and d.include_in_universe_of_districts=true 
       and (case when 'exclude'=any(li.open_flags) then true else false end)=false
),

--new for Targeting
district_contract_rank as (
select  recipient_id,
        contract_end_date,
        row_number() over (partition by recipient_id order by contract_end_date) as rank_order
        
from services_received svcs
join (select *
      from line_items
      where contract_end_date is not null) li
on svcs.line_item_id = li.id
where shared_service = 'District-dedicated'
and svcs.dqs_excluded = false
        
order by recipient_id ),

--new for Targeting
district_contract_largest_ia_rank as (
select  recipient_id,
        contract_end_date,
        row_number() over (partition by recipient_id order by svcs.bandwidth_in_mbps desc) as rank_order
        
from services_received svcs
join (select *
      from line_items
      where contract_end_date is not null) li
on svcs.line_item_id = li.id
where shared_service = 'District-dedicated'
and svcs.dqs_excluded = false
and svcs.internet_conditions_met = true
        
order by recipient_id )

select  dcr.recipient_id,
        dcr.contract_end_date as soonest_contract_end_date,
        dclir.contract_end_date as largest_internet_contract_end_date
from district_contract_rank dcr
left join district_contract_largest_ia_rank dclir
on dcr.recipient_id = dclir.recipient_id
where (dcr.rank_order = 1 or  dcr.rank_order is null)
and (dclir.rank_order = 1 or dclir.rank_order is null)
and (dcr.contract_end_date is not null
    or dclir.contract_end_date is not null)