/*
Author: Justine Schott
Created On Date: 2/9/2016
Last Modified Date:2/10/2016 
Name of QAing Analyst(s): Greg Kurzhals 
Purpose: To classify districts in our sample on the district team requested fiber categorization.
Methodology: The query leverages the existing lines_to_district_by_line_item subquery to determine which circuits are receivied by which district,
which is joined to the districts in our universe and the subset line_items we used to determine fiber status by the SOTS fiber metric percentage.

Please note the following regarding the query:
1. The categorization assumes that lowfiber-circuit is less likely than lowfiber-student, so if a district has both then the categorization is lowfiber-circuit.
2. This query also includes two extra columns: district_able_to_meet_2014_goal_given_current_circuits. This column, along with its over-subscription adjusted partnering column, can help you create an even more targeted list of districts -- if there are multiple nonfiber districts, perhaps one that isn't able to meet the 2014 goal is higher priority than one that is.
3. The default parameters are "All" states, and "50" mbps circuit id'd as low, and "100" kbps/student id'd as low.
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
          case when d.ia_bandwidth_per_student!='Insufficient data' 
          then d.ia_bandwidth_per_student::numeric else null end as "ia_bandwidth_per_student",
          
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
          ) as other_ia_bandwidth,
          sum(case when internet_conditions_met = true or upstream_conditions_met = true
          and bandwidth_in_mbps::numeric>='{{receives_at_least_one_ia_circuit_at_or_above}}'
          then 1 else 0 end) as "receives_ia_circuit_over_x_bandwidth"

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
          d.district_size,
          case when d.ia_bandwidth_per_student!='Insufficient data' 
          then d.ia_bandwidth_per_student::numeric else null end
          
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
          
        case when district_line_items.ia_bandwidth_per_student is null
        then 'Unknown'
        when ia_bandwidth_per_student<100
        then 'Not meeting'
        else 'Meeting' end as "100_kbps_goal_status",
        
        case when district_line_items.ia_bandwidth_per_student is null
        then 'Unknown'
        when ia_bandwidth_per_student*ia_oversub_factor<100
        then 'Not Meeting'
        else 'Meeting' end as "100_kbps_goal_w/oversub",
        
        case when receives_ia_circuit_over_x_bandwidth>0
        then 'Yes' else 'No' end as "ia_circuit_over_specified_bandwidth",
        
        case when district_line_items.ia_bandwidth_per_student is null
        then 'Unknown Goal Status'
        when ia_bandwidth_per_student<100 and
        receives_ia_circuit_over_x_bandwidth>0
        then 'Yes'
        else 'No' end as "receives_x_bandwidth_circuit_yet_does_not_meet_goals",
        
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
  
receives_at_least_one_ia_circuit_at_or_above:
  type: text
  default: '1000'

{% endform %}
