/*
Author: Justine Schott
Created On Date: 2/9/2016
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: Purpose: Districts table data pull with added columns
Methodology: 
1) IA goals: 2014 and 2018, with and without concurrency
2) Fiber/Non-Fiber IA distinction and % Scaleable:
Fiber / Scaleable = Fiber, Fixed Wireless, and Cable for districts with under 100  students
3) Highest IA connect category/type 
4) FRL% from NCES
5) ULOCAL codes from NCES
6) Service Providers: distinguished for internet, upstream, ISP, and WAN
7) Whether district was verified by DQS
8) WAN / Internet & Upstream Lines
*/

with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
),

cd as (
select dl.district_esh_id,
         c.line_item_id,
         count(distinct ec.circuit_id) as allocation_lines
        
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join district_lookup dl
  on ec.entity_id = dl.esh_id
  left join line_items li
  on line_item_id = li.id
  
  where entity_type in ('School', 'District')
  and exclude_from_reporting = false
  and broadband = true
  
  group by  district_esh_id,
         line_item_id
),
cdd as (
        select d.esh_id as district_esh_id,
        d.postal_cd,
        case when d.num_students = 'No data' then null else d.num_students::numeric end as num_students,
        case when d.num_schools = 'No data' then null else d.num_schools::numeric end as num_schools,
        case when d.ia_cost_per_mbps in ('Insufficient data','Infinity', 'NaN') then null else d.ia_cost_per_mbps::numeric end as ia_cost_per_mbps,
        case when d.ia_bandwidth_per_student in ('Insufficient data','Infinity','NaN') then null else d.ia_bandwidth_per_student::numeric end as ia_bandwidth_per_student,
        d.num_campuses,
        d.locale,
        case 
          when d.district_size in ('Tiny', 'Small') then 1
          when d.district_size = 'Medium' then 1.5
          when d.district_size = 'Large' then 1.75
          when d.district_size = 'Mega' then 2.25
        end as ia_oversub_ratio,
        sum(case when li.connect_category in ('Fiber', 'Fixed Wireless') 
              then cd.allocation_lines
              else 0
            end) as fiber_equiv_lines,
        sum(case when li.connect_category = 'Fiber' 
              then cd.allocation_lines
              else 0
            end) as fiber_lines,
        sum(case when li.connect_category not in ('Fiber', 'Other / Uncategorized') 
              then cd.allocation_lines
              else 0
            end) as non_fiber_lines,
        sum(case when li.connect_type = 'Cable Modem' 
              then cd.allocation_lines
              else 0
            end) as cable_lines,
        sum(case when li.connect_type != 'Cable Modem' and li.connect_category in ('Copper', 'Cable / DSL') 
              then cd.allocation_lines
              else 0
            end) as copper_dsl_lines,
        sum(case when li.wan_conditions_met = true and exclude = false
              then cd.allocation_lines
              else 0
            end) as wan_lines,
        sum(case when bandwidth_in_mbps >= 1000 and wan_conditions_met = true
              then cd.allocation_lines
              else 0 
            end) as gt_1g_wan_lines,
        sum(case when bandwidth_in_mbps < 1000 and connect_category = 'Fiber' and wan_conditions_met = true
              then cd.allocation_lines
              else 0 
            end) as lt_1g_fiber_wan_lines,
        sum(case when bandwidth_in_mbps < 1000 and connect_category != 'Fiber' and wan_conditions_met = true 
              then cd.allocation_lines
              else 0 
            end) as lt_1g_nonfiber_wan_lines,
        sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Fiber' 
              then cd.allocation_lines
              else 0 
            end) as fiber_internet_upstream_lines,
        sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Fixed Wireless' 
              then cd.allocation_lines
            else 0 end) as fixed_wireless_internet_upstream_lines,
        sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Cable / DSL' 
              then cd.allocation_lines
            else 0 end) as cable_dsl_internet_upstream_lines,
        sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_category = 'Copper' 
              then cd.allocation_lines
            else 0 end) as copper_internet_upstream_lines,
        sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_type = 'Cable Modem' 
              then cd.allocation_lines
            else 0 end) as cable_internet_upstream_lines,
        cast(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE or upstream_conditions_met=TRUE 
                then connect_category 
            end --order by connect_category
          ) as text
        ) as all_IA_connectcat,
        cast(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE or upstream_conditions_met=TRUE 
                then connect_type 
            end --order by connect_type
          ) as text
        ) as all_IA_connecttype,
        cast(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ) as text
        ) as Internet_SP,
        cast(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE 
                then reporting_name
            end --order by service_provider_name
          ) as text
        ) as Internet_SP_Parent,
        count( distinct 
          case 
            when internet_conditions_met = TRUE 
              then service_provider_name 
          end
        ) as Internet_SP_Count,
        cast(
          array_agg( distinct
            case 
              when upstream_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ) as text
        ) as Upstream_SP,
        cast(
          array_agg( distinct
            case 
              when wan_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ) as text
        ) as WAN_SP,
        cast(
          array_agg( distinct
            case 
              when isp_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ) as text
        ) as ISP_SP
            
        from districts d
        left join cd
        on cd.district_esh_id = d.esh_id
        left join line_items li
        on cd.line_item_id = li.id
        left join (
          select distinct name, reporting_name
          from service_provider_categories
          ) spc
        on li.service_provider_name = spc.name

        group by d.esh_id, d.num_students, d.num_schools, d.ia_bandwidth_per_student, d.ia_cost_per_mbps, 
        d.postal_cd, d.locale, d.num_campuses, d.district_size
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
    end as assumed_unscalable_campuses,
    case
      when num_campuses < fiber_lines
        then num_campuses 
        else fiber_lines
    end as known_fiber_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 
          case 
            when num_campuses > fiber_lines 
              then num_campuses - fiber_lines
              else 0
          end
        else 0
    end as assumed_fiber_campuses,
    case
      when non_fiber_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
        then 
          case
            when num_campuses < fiber_lines
              then 0
            when num_campuses - fiber_lines < non_fiber_lines
              then num_campuses - fiber_lines 
              else non_fiber_lines
          end
        else 0
    end as known_nonfiber_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 0 
        else 
          case
            when num_campuses < fiber_lines + non_fiber_lines
              then 0
              else num_campuses - (fiber_lines + non_fiber_lines)
          end
    end as assumed_nonfiber_campuses
  
  from cdd
),

av as (
        select distinct district_esh_id, line_item_id
        from cd
      ),

version_order as (
                select fy2015_item21_services_and_cost_id,
                      case when contacted is null or contacted = false then 'false' 
                        when contacted = true then 'true'
                      end as contacted,
                      version_id,
                      row_number() over (
                                        partition by fy2015_item21_services_and_cost_id 
                                        order by version_id desc
                                        ) as row_num
                
                from line_item_notes
                where note not like '%little magician%'
),
most_recent as (
                select av.line_item_id,
                      version_order.contacted,
                      av.district_esh_id,
                      case when 'assumed_ia' = any(open_flags)
                            or 'assumed_wan' = any(open_flags)
                            or 'assumed_fiber' = any(open_flags)
                      then true else false end as assumed_flags
                      
                from av
                left join version_order
                on av.line_item_id = version_order.fy2015_item21_services_and_cost_id
                left join line_items
                on av.line_item_id = line_items.id
                
                where row_num = 1
                or row_num is null
                ),
                
district_counts as (
                    select district_esh_id,
                          count(case when contacted = 'true' then 1 end) as true_count,
                          count(case when contacted = 'false' then 1 end) as false_count,
                          count(case when contacted is null and assumed_flags = true then 1 end) as null_assumed_count,
                          count(case when contacted is null and assumed_flags = false then 1 end) as null_untouched_count
                    
                    from most_recent
                    
                    group by district_esh_id
),

district_contacted as (
                        select district_esh_id,
                              case when true_count >= 1 then 'verified'
                                when true_count = 0 and false_count >= 1 then 'inferred'
                                when true_count = 0 and false_count = 0 and null_assumed_count >= 1 then 'interpreted'
                                when true_count = 0 and false_count = 0 and null_assumed_count = 0 and null_untouched_count >= 1 then 'assumed'
                              end as clean_categorization,
                              case when true_count >= 1 and false_count = 0 and null_assumed_count = 0 and null_untouched_count = 0
                                then true else false end as totally_verified
                                
                        
                        from district_counts
)

  select 
  districts.esh_id,
  districts.nces_cd,
  districts.name,
  ag121a."ULOCAL",
  districts.locale,
  districts.district_size,
  districts.exclude_from_analysis,
  districts.consortium_member,
  districts.district_type,
  districts.num_schools,
  districts.num_campuses,
  districts.num_students,
  districts.num_students_and_staff,
  districts.address,
  districts.city,
  districts.zip,
  districts.postal_cd,
  districts.latitude,
  districts.longitude,
  districts.num_flags,
  districts.num_open_dirty_flags,
  districts.ia_bandwidth_per_student,
  districts.wan_bandwidth_per_student,
  cdd_calc.ia_cost_per_mbps,
  cdd_calc.ia_cost_per_mbps/12 as "monthly_ia_cost_per_mbps",
  districts.wan_cost_per_connection,
  districts.wan_bandwidth_low,
  districts.wan_bandwidth_high,
  districts.percentage_fiber,
  districts.highest_connect_type,
  cdd_calc.all_IA_connectcat,
  cdd_calc.all_IA_connecttype,
  cdd_calc.Internet_SP_Parent,
  cdd_calc.Internet_SP,
  cdd_calc.Internet_SP_Count,
  cdd_calc.Upstream_SP,
  cdd_calc.WAN_SP, 
  cdd_calc.ISP_SP, 
  district_contacted.clean_categorization, 
  district_contacted.totally_verified, 
  (sc121a_frl.num_frl_students::numeric / sc121a_frl.num_tot_students::numeric) as FRL_Percent,
  cdd_calc.ia_oversub_ratio,
  cdd_calc.fiber_equiv_lines, 
  cdd_calc.cable_lines,
  cdd_calc.copper_dsl_lines,
  cdd_calc.num_campuses,
  cdd_calc.known_scalable_campuses,
  cdd_calc.assumed_scalable_campuses,
  cdd_calc.known_unscalable_campuses,
  cdd_calc.assumed_unscalable_campuses,
  cdd_calc.known_fiber_campuses,
  cdd_calc.assumed_fiber_campuses,
  cdd_calc.known_nonfiber_campuses,
  cdd_calc.assumed_nonfiber_campuses,
  cdd_calc.wan_lines,
  cdd_calc.fiber_internet_upstream_lines,
  cdd_calc.fixed_wireless_internet_upstream_lines,
  cdd_calc.cable_DSL_internet_upstream_lines,
  cdd_calc.copper_internet_upstream_lines,
  cdd_calc.gt_1g_wan_lines,
  cdd_calc.lt_1g_fiber_wan_lines,
  cdd_calc.lt_1g_nonfiber_wan_lines,
  (cdd_calc.ia_bandwidth_per_student/1000) * cdd_calc.num_students as total_ia_bw_mbps, 
  (cdd_calc.ia_bandwidth_per_student/1000) * cdd_calc.num_students * cdd_calc.ia_cost_per_mbps/12 as total_ia_monthly_cost,
  case 
    when cdd_calc.ia_bandwidth_per_student >= 100 
      then true
      else false 
  end as meeting_2014_goal_no_oversub,
  case 
    when cdd_calc.ia_bandwidth_per_student * ia_oversub_ratio >= 100 
      then true
      else false
  end as meeting_2014_goal_oversub,
  case 
    when cdd_calc.ia_bandwidth_per_student >= 1000 
      then true
      else false 
  end as meeting_2018_goal_no_oversub,
  case 
    when cdd_calc.ia_bandwidth_per_student * ia_oversub_ratio >= 1000 
      then true
      else false 
  end as meeting_2018_goal_oversub,
  case 
    when cdd_calc.ia_cost_per_mbps/12<=3 
      then true 
      else false 
  end as meeting_$3_per_mbps_affordability_target,
  case 
    when known_scalable_campuses > 0
      then 'Fiber IA'
      else 'Non-Fiber IA' 
  end as "IA is Fiber or Equiv?", -- TRUE if at least one line is Fiber or Equiv
  case 
    when 
      cdd_calc.copper_internet_upstream_lines = 0
      and cdd_calc.cable_DSL_internet_upstream_lines - cable_internet_upstream_lines = 0 
      and fiber_internet_upstream_lines+ 
          fixed_wireless_internet_upstream_lines + 
            case 
              when cdd_calc.num_students <= 100 
                then cable_internet_upstream_lines 
                else 0 
            end > 0
        then 'All Scaleable IA' 
    when  fiber_internet_upstream_lines+ 
          fixed_wireless_internet_upstream_lines + 
            case 
              when cdd_calc.num_students <= 100 
                then cable_internet_upstream_lines 
                else 0 
            end = 0
        then 'No Scaleable IA' 
        else 'Some Scaleable IA' end
  as percent_scalable_IA, 
  COALESCE (
    case when (cdd_calc.all_IA_connectcat ILIKE '%Fiber%') then 'Fiber' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Fixed Wireless%') then 'Fixed Wireless' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Cable%' and cdd_calc.all_IA_connecttype ILIKE '%Cable%') then 'Cable' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%DSL%' and cdd_calc.all_IA_connecttype ILIKE '%DSL%') then 'DSL' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Copper%') then 'Copper' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Other%') then 'Other/Uncategorized' else 'None - Error' end
  ) as hierarchy_connect_category 


  from  districts
  left join district_contacted 
  on district_contacted.district_esh_id = districts.esh_id
  left join sc121a_frl 
  on sc121a_frl.nces_cd = districts.nces_cd
  left join ag121a 
  on districts.nces_cd = ag121a.nces_cd
  left join cdd_calc 
  on cdd_calc.district_esh_id = districts.esh_id
  where districts.include_in_universe_of_districts = TRUE
    and (districts.postal_cd = '{{postal_cd}}' OR 'All' = '{{postal_cd}}') 
    and (exclude_from_analysis::varchar='{{exclude_from_analysis}}' OR 'All'='{{exclude_from_analysis}}')

{% form %}

postal_cd:
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