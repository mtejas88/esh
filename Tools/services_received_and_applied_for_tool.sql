/*
Author: Greg Kurzhals
Created On Date: 11/01/2015
Last Modified Date: 12/28/2015
Name of QAing Analyst(s): Justine Schott
Purpose: To identify and display the broadband services (district-dedicated, shared IA, and backbone) received or applied for by each district
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
         count(*) as allocation_lines
        
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join district_lookup dl
  on ec.entity_id = dl.esh_id
  
  group by  district_esh_id,
         line_item_id
),
/*Joins "line_items" table to add relevant cost, bandwidth, connection type, and purpose information; joins "districts" table
to add demographic data used in metric calculations*/
internet_services_received as (
      select ldli.district_esh_id,
      d.name,
      d.postal_cd,
      ldli.line_item_id,
      li.consortium_shared,

--classifies circuits as either "Shared IA", "Backbone", or "District-dedicated"
      case when li.consortium_shared=true 
            and li.ia_conditions_met=true
              then 'Shared IA'
           when 'backbone'=any(li.open_flags)
              then 'Backbone'
              else 'District-dedicated' 
      end as shared_service,

--limits lines received by district to the total num_lines listed in the line item, unless the line item is allocated to multiple districts
      case when li.consortium_shared=false 
            and ldli.allocation_lines>=li.num_lines 
              then li.num_lines::varchar
           when li.consortium_shared=true 
            OR 'backbone'=any(open_flags)
              then 'Shared Circuit'
              else ldli.allocation_lines::varchar 
      end as quantity_of_lines_received_by_district,

      li.bandwidth_in_mbps,
      li.connect_type,
      li.purpose,
      li.wan,

/*For "District-dedicated circuits", the district share of the line item cost is calculated by 
multiplying the line item cost by the proportion of the total num_lines allocated to 
the district (see previous comment).  For "Shared IA" and "Backbone" line items, line item cost is divided 
proportionally between recipient districts based on their number of 
students (e.g. num_students in district/num_students in ALL districts served by line item)*/ 

      case when li.rec_elig_cost!='No data' 
            and li.consortium_shared=false 
            and ldli.allocation_lines>=li.num_lines 
            and li.total_cost::numeric>0 
            and li.num_lines!=0 
            and li.orig_r_months_of_service is not null
            and li.orig_r_months_of_service!=0 
              then li.total_cost::numeric/li.orig_r_months_of_service 
           when li.consortium_shared=false and ldli.allocation_lines<li.num_lines and li.num_lines!=0 and li.total_cost::numeric>0 
            and li.orig_r_months_of_service is not null 
            and li.orig_r_months_of_service!=0 
              then (ldli.allocation_lines/li.num_lines)*(li.total_cost::numeric/li.orig_r_months_of_service)
           when li.consortium_shared=true 
            OR 'backbone'=any(li.open_flags) 
              then (d.num_students::numeric/district_info_by_li.num_students_served)*(li.total_cost::numeric/li.orig_r_months_of_service)  
              else 0
      end as "district_monthly_cost",

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
      d.consortium_member

      from lines_to_district_by_line_item ldli

      left join line_items li
      on ldli.line_item_id=li.id

      left join districts d
      on ldli.district_esh_id=d.esh_id

/*Group by line_item_id to yield students served by each line item (note that most fields in this sub-query are unused, 
  and have been retained in case we want to build them into the main query*/
      left join (

                  select  a.line_item_id,
                          li.applicant_name,
                          li.applicant_id,
                          li.applicant_postal_cd,
                          array_agg(DISTINCT dl.district_esh_id::varchar) as recepient_ids,
                          count(DISTINCT dl.district_esh_id) as num_recepient_ids,
                          sum(DISTINCT d.num_students::bigint) as num_students_served, -- fix: this would not count 2 districts with the same student count
                          array_agg(DISTINCT d.name) as recepient_names,
                          array_agg(DISTINCT eim.ben::varchar) as recepient_bens

                  from allocations a

                  left join district_lookup dl
                  on a.recipient_id=dl.esh_id

                  left join districts d
                  on dl.district_esh_id=d.esh_id

                  left join line_items li
                  on a.line_item_id=li.id

                  left join esh_id_mappings eim
                  on d.esh_id=eim.entity_id

                  where d.num_students!='No data'
                  GROUP BY  a.line_item_id,
                            li.applicant_name,
                            li.applicant_id,
                            li.applicant_postal_cd
          ) district_info_by_li
      on ldli.line_item_id=district_info_by_li.line_item_id

      where li.broadband=true  
       and (li.consortium_shared=false 
         OR li.ia_conditions_met=true 
         OR 'backbone'=any(li.open_flags)
       )  
       and d.include_in_universe_of_districts=true 
       and (case when 'exclude'=any(li.open_flags) then true else false end)=false
)

  
select * 
from internet_services_received sr

--Liquid parameters allow user to filter for district_esh_id, state, and clean status
where (sr.district_esh_id::varchar='{{district_esh_id}}' OR 'All'='{{district_esh_id}}') 
  and (sr.postal_cd='{{state}}' OR 'All'='{{state}}') 
  and (sr.exclude_from_analysis::varchar='{{exclude_from_analysis}}' OR 'All'='{{exclude_from_analysis}}')

ORDER BY district_esh_id

{% form %}

district_esh_id:
  type: text
  default: 'All'
  
state:
  type: text
  default: 'All'
  
exclude_from_analysis:
  type: select
  default: 'All'
  options: [['true'],
            ['false'],
            ['All']
           ]

{% endform %}
