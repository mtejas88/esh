/*
Author: Justine Schott
Created On Date: 2/8/2016
Last Modified Date: 
Name of QAing Analyst(s): Greg Kurzhals (via v1 query creation) 
Purpose: To classify districts in our sample on the district team requested fiber categorization.
Methodology: The query leverages the existing lines_to_district_by_line_item subquery to determine which circuits are receivied by which district,
which is joined to the districts in our universe and the subset line_items we used to determine fiber status by the SOTS fiber metric percentage.
*/

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

district_line_items as (
  select  d.esh_id,
          d.name, 
          d.address,
          d.city,
          d.nces_cd,
          d.locale,
          d.num_students,
          d.num_schools,
          d.num_campuses,
          d.exclude_from_analysis,
          case 
            when d.district_size in ('Tiny', 'Small') 
              then 1
            when d.district_size='Medium' 
              then 1.5
            when d.district_size='Large' 
              then 1.75
          else 2.25 end as ia_oversub_factor,
          sum(case
              when li.connect_category = 'Fiber'
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_count,
          sum(case
              when li.connect_category = 'Fiber' and li.bandwidth_in_mbps < {{bandwidth_mbps_at_or_under}}
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_circuit_count,
          sum(case
              when li.connect_category = 'Fiber' and li.bandwidth_in_mbps/d.num_students::numeric < {{kbps_per_student_at_or_under}}
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_student_count,
          sum(case
              when li.connect_type = 'Cable Modem' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as cable_ia_count,
          sum(case
              when li.connect_type = 'Digital Subscriber Line (DSL)' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as dsl_ia_count,
          sum(case
              when li.connect_type = 'DS-1 (T-1)' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as t1_ia_count,
          sum(case
              when li.connect_type = 'DS-3 (T-3)' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as t3_ia_count,
          sum(case
              when li.connect_category = 'Fixed Wireless' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as fixedwireless_ia_count,
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_ia_count,
          sum(case
              when li.connect_category != 'Fiber' 
                  and connect_type not in ('DS-3 (T-3)', 'DS-1 (T-1)', 'Digital Subscriber Line (DSL)', 'Cable Modem') 
                  and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as other_ia_bandwidth

  from districts d
  left join lines_to_district_by_line_item ldli
  on d.esh_id = ldli.district_esh_id
  left join (
      select *
      from line_items 
      where broadband = true
      and exclude = false --to exclude those that are not in metric calculations
  ) li
  on ldli.line_item_id = li.id

  where d.include_in_universe_of_districts = true
  and (d.postal_cd = '{{state}}' or 'All' = '{{state}}')

  group by  d.esh_id,
          d.name, 
          d.address,
          d.city,
          d.nces_cd,
          d.locale,
          d.num_students,
          d.num_schools,
          d.num_campuses,
          d.exclude_from_analysis,
          d.district_size
)

  select  esh_id,
          name, 
          address,
          city,
          nces_cd,
          locale,
          num_students,
          num_schools,
          num_campuses,
          case 
            when exclude_from_analysis = true 
              then 'dirty'
            when fiber_count = 0
              then 'nonfiber' 
            when lowfiber_circuit_count > 0
              then 'lowfiber-circuit'
            when lowfiber_student_count > 0
              then 'lowfiber-student' 
            when fiber_count > 0
              then 'highfiber'
            else 'unknown'
          end as district_targeting_categorization,
          case 
            when exclude_from_analysis = true 
              then 'unknown'
            when fiber_ia_count > 0 
                  or (num_students::numeric*.1 <= --2014 bw goal
                              (cable_ia_count*150) +
                              (dsl_ia_count*50) +
                              (t1_ia_count*1.5) +
                              (t3_ia_count*45) +
                              (fixedwireless_ia_count*1000) +
                              other_ia_bandwidth
                      )
                    then 'Yes'
                    else 'No'
          end as district_able_to_meet_2014_goal_given_current_circuits,
          case 
            when exclude_from_analysis = true 
              then 'unknown'
            when fiber_ia_count > 0 
                  or (num_students::numeric*.1/ia_oversub_factor <= --2014 bw goal
                              (cable_ia_count*150) +
                              (dsl_ia_count*50) +
                              (t1_ia_count*1.5) +
                              (t3_ia_count*45) +
                              (fixedwireless_ia_count*1000) +
                              other_ia_bandwidth
                      )
                    then 'Yes'
                    else 'No'
          end as district_able_to_meet_2014_goal_given_current_circuits_incl_oversubscription

  from district_line_items


{% form %}

state:
  type: text
  default: 'All'
  
bandwidth_mbps_at_or_under:
  type: text
  default: '50'
  
kbps_per_student_at_or_under:
  type: text
  default: '100'

{% endform %}