/*
Author: Greg Kurzhals
Created On Date: 11/01/2015
Last Modified Date: 12/28/2015
Name of QAing Analyst(s): Justine Schott
Purpose: To identify and display the broadband services (district-dedicated, shared IA, and backbone) received by each district, 
or applied for by each entity
Methodology: The query leverages the circuits table to identify each line item allocated to a district or its constituent schools 
(but NOT to other locations).  Thus, a copy of each line item is created for each district that receives the services represented by 
that line item.  Additionally,   based on existing metadata, each line item is classified as either 'Shared IA" (IA serving multiple districts), 
"Backbone" (transport serving multiple districts), or "District-dedicated", with district share of total line item cost calculated accordingly 
(e.g. by student population vs. by # of allocated lines).
*/

--District esh_id of districts and schools for purpose of looking up services received by a district's educational entities
with district_lookup as (
       select esh_id, district_esh_id, postal_cd
        from schools
        union
        select esh_id, esh_id as district_esh_id, postal_cd
        from districts
),
--Groups all circuits in circuits table by distinct recipient district and line item
lines_to_district_by_line_item as (
  select dl.district_esh_id,
         c.line_item_id,
         count(distinct ec.circuit_id) as allocation_lines
        
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join district_lookup dl
  on ec.entity_id = dl.esh_id
  
  group by  district_esh_id,
         line_item_id
),
services_received as (
      select ldli.district_esh_id as esh_id,
      d.name,
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
/*Joins "line_items" table to add relevant cost, bandwidth, connection type, and purpose information; joins "districts" table
to add demographic data used in metric calculations*/
services_applied_for as (
      select li.applicant_id as esh_id,
      li.applicant_name,
      li.postal_cd,
      li.id as line_item_id,
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

--not applicable at applicant level
      'n/a' as quantity_of_lines_received_by_district,

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

      'n/a' as line_item_district_monthly_cost,

--if months of service is null or zero, we assume that the services are in use throughout the entirety of the E-rate cycle
      case when li.orig_r_months_of_service is not null 
           and li.orig_r_months_of_service!=0 
            then li.total_cost::numeric/li.orig_r_months_of_service 
            else li.total_cost::numeric/12 
      end as "line_item_total_monthly_cost",

      'n/a' as "cat.1_allocations_to_district",
      li.num_lines as "line_item_total_num_lines",
      li.total_cost as "line_item_total_cost",
      li.rec_elig_cost as "line_item_recurring_elig_cost",
      li.one_time_eligible_cost as "line_item_one-time_cost",
      li.orig_r_months_of_service,
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
      x.recipient_districts,
      x.recipient_postal_cd,
      case 
        when 'false' = any(x.recipient_district_cleanliness)
          then 'include clean'
          else 'exclude dirty'
      end as dirty_status,
      spc.reporting_name

      from districts d

      left join line_items li
      on d.esh_id=li.applicant_id


      left join (
          select distinct name, reporting_name
          from service_provider_categories
      ) spc
      on li.service_provider_name = spc.name

      left join lateral (
        select  line_item_id,
                array_agg(DISTINCT district_esh_id) as "recipient_districts",
                array_agg(DISTINCT postal_cd) as "recipient_postal_cd",
                array_agg(DISTINCT exclude_from_analysis) as "recipient_district_cleanliness"
        from lines_to_district_by_line_item ldli
        left join districts
        on ldli.district_esh_id = districts.esh_id
        GROUP BY line_item_id) x
      on li.id=x.line_item_id

      where li.broadband=true  
       and (li.consortium_shared=false 
         OR li.ia_conditions_met=true 
         OR 'backbone'=any(li.open_flags)
       )  
       and d.include_in_universe_of_districts=true 
       and (case when 'exclude'=any(li.open_flags) then true else false end)=false
),

unscalable_clean as (
  select reporting_name,
  postal_cd,
  sum(distinct num_students::numeric) as num_students,
  count(distinct esh_id) as num_districts,
  count(distinct line_item_id) as num_line_items,
  sum(quantity_of_lines_received_by_district::numeric) as num_circuits,
  sum(line_item_district_monthly_cost) as total_cost

from services_received
where not( connect_category in ('Fiber', 'Fixed Wireless')
          or (num_students::numeric < 100 and connect_type = 'Cable Modem')
) and dirty_status = 'include clean' and shared_service = 'District-dedicated' 
group by reporting_name, postal_cd
),

parent_overall as (
  select reporting_name,
  postal_cd,
  sum(line_item_total_num_lines) as num_line_items_overall,
  sum(line_item_total_monthly_cost) as total_cost_overall

from services_applied_for
group by reporting_name, postal_cd
),

overall as (
  select postal_cd,
  sum(line_item_total_monthly_cost) as total_cost_state

from services_applied_for
group by postal_cd
),

ranked as (
  select uc.*,
  po.num_line_items_overall,
  po.total_cost_overall,
  po.total_cost_overall/o.total_cost_state::numeric as pct_total_cost_overall,
  row_number() over (partition by uc.postal_cd order by num_circuits desc, num_students desc) as ranking

  from unscalable_clean uc
  left join parent_overall po
  on concat(uc.postal_cd,uc.reporting_name) = concat(po.postal_cd,po.reporting_name)
  left join overall o
  on uc.postal_cd = o.postal_cd
)

select *
from ranked
where ranking <= 3