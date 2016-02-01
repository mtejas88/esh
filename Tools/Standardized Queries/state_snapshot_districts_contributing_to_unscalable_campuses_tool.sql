/*
Author: Justine Schott
Created On Date: 12/29/2015
Last Modified Date: 12/29/2015
Name of QAing Analyst(s): 
Purpose: To display all districts in a state that have unscalable campuses according to the state snapshot fiber pct query
Methodology: All tables are same as state_snapshot_tool.sql without the summary up to the state level. Only districts with
unscalable campuses, assumed or known, are shown.
*/

--state profile metrics
with universe_districts as (
  select *
  from districts
  where include_in_universe_of_districts = true
),

--goals and sample metrics
clean_goal_fiber_districts as (
  select *,
    ia_bandwidth_per_student::numeric*
                      case when district_size in ('Tiny', 'Small') then 1
                        when district_size = 'Medium' then 1.5
                        when district_size = 'Large' then 1.75
                        when district_size = 'Mega' then 2.25
                      end as adj_ia_bandwidth_per_student
  from universe_districts
  where exclude_from_analysis = false
--there are 6 districts whose IA line items were all "cancelled" and are not marked as dirty
    and ia_bandwidth_per_student != 'Insufficient data' 
--portland, ME should have been marked dirty
    and esh_id not in ('917448') 
),
district_lookup as (
  select esh_id, esh_id as district_esh_id
  from universe_districts
  union
  select schools.esh_id, district_esh_id
  from schools
  inner join universe_districts sd
  on sd.esh_id = schools.district_esh_id
),
--fiber metrics
cd as (
select dl.district_esh_id,
         c.line_item_id,
         count(*) as allocation_lines
        
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join district_lookup dl
  on ec.entity_id = dl.esh_id
  
  where entity_type in ('School', 'District')
  and exclude_from_reporting = false
  
  group by  district_esh_id,
         line_item_id
),
cdd as (
        select cgfd.esh_id as district_esh_id,
        cgfd.postal_cd,
        cgfd.num_students::numeric,
        cgfd.num_schools::numeric,
        cgfd.num_campuses,
        cgfd.locale,
        sum(case when li.connect_category in ('Fiber', 'Fixed Wireless') 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as fiber_equiv_lines,
        sum(case when li.connect_type = 'Cable Modem' 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as cable_lines,
        sum(case when li.connect_type != 'Cable Modem' and li.connect_category in ('Copper', 'Cable / DSL') 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as copper_dsl_lines,
        sum(case when li.wan_conditions_met = true and exclude = false
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as wan_lines
            
        from clean_goal_fiber_districts cgfd
        left join cd
        on cd.district_esh_id = cgfd.esh_id
        left join line_items li
        on cd.line_item_id = li.id
        
        group by cgfd.esh_id, cgfd.num_students, cgfd.num_schools, cgfd.postal_cd, cgfd.locale, cgfd.num_campuses
),
cdd_calc as (
    select *,
    case
      when num_campuses < fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
        then num_campuses 
        else fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
    end as known_scalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 
          case 
            when num_campuses > fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
              then num_campuses - fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
              else 0
          end
        else 0
    end as assumed_scalable_campuses,
    case
      when num_students < 100 and copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
        then 
          case
            when num_campuses < (fiber_equiv_lines + cable_lines)
              then 0
            when num_campuses - (fiber_equiv_lines + cable_lines) < copper_dsl_lines
              then num_campuses - (fiber_equiv_lines + cable_lines)
              else copper_dsl_lines
          end
      when num_students >= 100 and (copper_dsl_lines + cable_lines)> 0  and not(num_schools > 5 and wan_lines = 0 ) 
        then
          case
            when num_campuses < (fiber_equiv_lines)
              then 0
            when num_campuses - (fiber_equiv_lines ) < copper_dsl_lines + cable_lines
              then num_campuses - (fiber_equiv_lines)
              else copper_dsl_lines + cable_lines
          end
        else 0
    end as known_unscalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 0 
        else 
          case
            when num_campuses < (fiber_equiv_lines + copper_dsl_lines + cable_lines)
              then 0
              else num_campuses - (fiber_equiv_lines + copper_dsl_lines + cable_lines)
          end
    end as assumed_unscalable_campuses
  
  from cdd
)

  select 
    cdd_calc.district_esh_id,
    d.name,
    d.city,
    cdd_calc.postal_cd,
    d.nces_cd,
    d.district_Type,
    d.locale,
    cdd_calc.num_students,
    cdd_calc.num_schools,
    cdd_calc.num_campuses,
    cdd_calc.fiber_equiv_lines,
    cdd_calc.cable_lines,
    cdd_calc.copper_dsl_lines,
    cdd_calc.fiber_equiv_lines + case when cdd_calc.num_students < 100 then cdd_calc.cable_lines else 0 end as scalable_lines,
    cdd_calc.copper_dsl_lines + case when cdd_calc.num_students >= 100 then cdd_calc.cable_lines else 0 end as non_scalable_lines,
    cdd_calc.known_scalable_campuses,
    cdd_calc.assumed_scalable_campuses,
    cdd_calc.known_unscalable_campuses,
    cdd_calc.assumed_unscalable_campuses,
    schools.esh_id as school_esh_id,
    schools.name as school_name,
    schools.address,
    schools.school_nces_cd,
    schools.co_located

  from cdd_calc
  left join districts d
  on d.esh_id = cdd_calc.district_esh_id
  left join schools
  on schools.district_esh_id = cdd_calc.district_esh_id
  where cdd_calc.postal_cd =  '{{ state }}'
  and known_unscalable_campuses + assumed_unscalable_campuses > 0
  and schools.charter= false
  and schools.max_grade_level != 'PK'

{% form %}
  
state:
  type: text
  default: 'KY'

{% endform %}