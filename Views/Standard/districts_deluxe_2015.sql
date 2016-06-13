
with agg_district_apps as (
  --these values separate since they include consortium_shared line items, which are excluded from the cdd table below
      select 
        recipient_id,
        array_to_string(
          array_agg(distinct 
                      case 
                        when ia_conditions_met=true 
                          then concat(applicant_name,
                                        case 
                                          when consortium_shared=true
                                            then ' (shared)'
                                          when consortium_shared=false and isp_conditions_met=true
                                            then ' (dedicated ISP only)'
                                          when consortium_shared=false and internet_conditions_met=true
                                            then ' (dedicated Internet)'
                                          else ' (unknown purpose)'
                                        end)
                      end), '; ') as "ia_applicants"

      from services_received svcs
      GROUP BY recipient_id),
agg_district_lines as (
        select 
          d.esh_id as district_esh_id,
          d.postal_cd,
          case 
            when d.num_students = 'No data' 
              then null 
            else 
              d.num_students::numeric 
          end as num_students,
          case 
            when d.num_schools = 'No data' 
              then null 
            else 
              d.num_schools::numeric 
          end as num_schools,
          case 
            when d.ia_cost_per_mbps in ('Insufficient data','Infinity', 'NaN') 
              then null 
            else 
              d.ia_cost_per_mbps::numeric 
          end as ia_cost_per_mbps,
          case 
            when d.ia_bandwidth_per_student in ('Insufficient data','Infinity','NaN') 
              then null 
            else 
              d.ia_bandwidth_per_student::numeric 
          end as ia_bandwidth_per_student,
          d.num_campuses,
          d.locale,
          case 
            when d.district_size in ('Tiny', 'Small') 
              then 1
            when d.district_size = 'Medium' 
              then 1.5
            when d.district_size = 'Large' 
              then 1.75
            when d.district_size = 'Mega' 
              then 2.25
          end as ia_oversub_ratio,
          sum(case 
                when li.connect_category = 'Fiber' 
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as fiber_lines,
          sum(case 
                when li.connect_category = 'Fixed Wireless' 
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as fixed_wireless_lines,
          sum(case 
                when li.connect_category not in ('Fiber', 'Other / Uncategorized') 
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as non_fiber_lines,
          sum(case 
                when li.connect_type = 'Cable Modem' 
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as cable_lines,
          sum(case 
                when (li.connect_type != 'Cable Modem' and li.connect_category in ('Copper', 'Cable / DSL'))
                      OR 'ethernet_copper'=any(li.open_flags)
                  then 
                    sr."cat.1_allocations_to_district"
                else 0
              end) as copper_dsl_lines,
          sum(case 
                when  isp_conditions_met=false 
                      and connect_category not in ('Fiber','Fixed Wireless', 'Cable / DSL', 'Copper')
                      and not('ethernet_copper'=any(li.open_flags))
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as other_uncategorized_lines,
          sum(case 
                when li.wan_conditions_met = true 
                  then sr."cat.1_allocations_to_district"
                else 0
              end) as wan_lines,
          sum(case 
                when  bandwidth_in_mbps >= 1000 
                      and wan_conditions_met = true 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as gt_1g_wan_lines,
          sum(case 
                when  bandwidth_in_mbps < 1000 
                      and connect_category = 'Fiber'
                      and wan_conditions_met = true 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as gt_1g_wan_lines,        
          sum(case 
                when  bandwidth_in_mbps < 1000 
                      and connect_category != 'Fiber'
                      and wan_conditions_met = true 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as lt_1g_nonfiber_wan_lines,
          sum(case 
                when  (internet_conditions_met = true or upstream_conditions_met = true) 
                      and connect_category = 'Fiber' 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as fiber_internet_upstream_lines,
          sum(case 
                when  (internet_conditions_met = true or upstream_conditions_met = true) 
                      and connect_category = 'Fixed Wireless' 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as fixed_wireless_internet_upstream_lines,
          sum(case 
                when  (internet_conditions_met = true or upstream_conditions_met = true) 
                      and (li.connect_type != 'Cable Modem' and connect_category in ('Cable / DSL', 'Copper'))
                          OR 'ethernet_copper'=any(open_flags) 
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as copper_dsl_internet_upstream_lines,
          sum(case 
                when  (internet_conditions_met = true or upstream_conditions_met = true) 
                      and li.connect_type = 'Cable Modem'
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as cable_internet_upstream_lines,   
          sum(case 
                when  (internet_conditions_met = true or upstream_conditions_met = true) 
                      and isp_conditions_met=false 
                      and connect_category not in ('Fiber', 'Fixed Wireless', 'Cable / DSL','Copper')
                      and not('ethernet_copper'=any(li.open_flags))
                  then sr."cat.1_allocations_to_district"
                else 0 
              end) as other_uncategorized_internet_upstream_lines,
        
        array_to_string(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE or upstream_conditions_met=TRUE 
                then connect_category 
            end --order by connect_category
          ), ', ') as all_IA_connectcat,
       
        array_to_string(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE or upstream_conditions_met=TRUE 
                then connect_type 
            end --order by connect_type
          ), ', ') as all_IA_connecttype,
        
        array_to_string(
          array_agg( distinct
            case 
              when internet_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ), ', ') as "bundled_internet_sp",
        
        array_to_string(
          array_agg(distinct
            case 
              when upstream_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ), ', ') as "upstream_sp",
       
        array_to_string(       
          array_agg( distinct
            case 
              when wan_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ), ', ') as "wan_sp",
        
        array_to_string(
          array_agg( distinct
            case 
              when isp_conditions_met = TRUE 
                then service_provider_name
            end --order by service_provider_name
          ), '; ') as "dedicated_isp_sp",
        array_to_string(
          array_agg(distinct 
                      case 
                        when upstream_conditions_met=true
                          then applicant_name 
                        else null 
                      end), '; ') as "upstream_applicants",
        array_to_string(
          array_agg(distinct 
                      case 
                        when wan_conditions_met=true
                          then applicant_name 
                        end), '; ') as "wan_applicants",
        --dedicated ISP
        array_to_string(
          array_agg(case 
                      when isp_conditions_met=true
                        then concat(quantity_of_lines_received_by_district, ' line(s) at ', 
                                    bandwidth_in_mbps, ' Mbps from ', service_provider_name, 
                                    ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                      end), '; ') as "dedicated_isp_services",             
        array_to_string(
          array_agg(case 
                      when isp_conditions_met=true 
                        then concat(service_provider_name, ' - ', 
                                    extract(month from contract_end_date::timestamp), '/', 
                                    extract(year from contract_end_date::timestamp)) 
                      end), '; ') as "dedicated_isp_contract_expiration",
        --bundled IA
        array_to_string(
          array_agg(case 
                      when internet_conditions_met=true
                        then concat(quantity_of_lines_received_by_district, ' ', 
                                    (case 
                                      when connect_category='Cable / DSL' and connect_type='Cable Modem'
                                        then 'Cable'
                                      when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                                        then 'DSL'
                                      when connect_category='Copper' and bandwidth_in_mbps::numeric=45 
                                        then 'T-3'
                                      when connect_category='Copper' and round(bandwidth_in_mbps::numeric, 1)=1.5 
                                        then 'T-1'
                                      else connect_category 
                                    end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, 
                                    ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                    end), '; ') as "bundled_internet_connections", 
        array_to_string(
          array_agg(case 
                      when internet_conditions_met=true 
                        then concat(service_provider_name, ' - ', 
                                    extract(month from contract_end_date::timestamp), '/', 
                                    extract(year from contract_end_date::timestamp)) 
                    end), '; ') as "bundled_internet_contract_expiration",
        --upstream
        array_to_string(
          array_agg(case 
                      when upstream_conditions_met=true
                        then concat(quantity_of_lines_received_by_district, ' ',  
                                    (case 
                                      when connect_category='Cable / DSL' and connect_type='Cable Modem'
                                        then 'Cable'
                                      when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                                        then 'DSL'
                                      when connect_category='Copper' and bandwidth_in_mbps::numeric=45 
                                        then 'T-3'
                                      when connect_category='Copper' and round(bandwidth_in_mbps::numeric, 1)=1.5 
                                        then 'T-1'
                                      else connect_category
                                    end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, 
                                    ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                    end), '; ') as "upstream_connections",
          array_to_string(
            array_agg(case 
                        when upstream_conditions_met=true
                          then concat(service_provider_name, ' - ', 
                                      extract(month from contract_end_date::timestamp), '/', 
                                      extract(year from contract_end_date::timestamp)) 
                      end), '; ') as "upstream_contract_expiration",
        --WAN                
        array_to_string(
          array_agg(case 
                      when wan_conditions_met=true
                        then concat(quantity_of_lines_received_by_district, ' ', 
                                    (case 
                                      when connect_category='Cable / DSL' and connect_type='Cable Modem'
                                        then 'Cable'
                                      when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                                        then 'DSL'
                                      when connect_category='Copper' and bandwidth_in_mbps::numeric=45 
                                        then 'T-3'
                                      when connect_category='Copper' and round(bandwidth_in_mbps::numeric, 1)=1.5 
                                        then 'T-1'
                                      else connect_category
                                    end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, 
                                    ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                        end), '; ') as "wan_connections",         
        array_to_string(
          array_agg(case 
                      when wan_conditions_met=true 
                          then concat(service_provider_name, ' - ', 
                                      extract(month from contract_end_date::timestamp), '/', 
                                      extract(year from contract_end_date::timestamp)) 
                    end), '; ') as "wan_contract_expiration"
            
        from districts d
        left join services_received sr
        on d.esh_id = sr.recipient_id

        where dirty_status = 'include clean'
        and shared_service = 'District-dedicated'

        group by d.esh_id, d.num_students, d.num_schools, d.ia_bandwidth_per_student, d.ia_cost_per_mbps, 
        d.postal_cd, d.locale, d.num_campuses, d.district_size
),
agg_district_campus as (
    select *,
    case
      when num_campuses < fiber_lines 
        then num_campuses 
        else fiber_lines 
    end as nga_v2_known_scalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 
          case 
            when num_campuses > fiber_lines 
              then num_campuses - fiber_lines 
              else 0
          end
        else 0
    end as nga_v2_assumed_scalable_campuses,
    case
      when copper_dsl_lines > 0 and not(num_schools > 5 and wan_lines = 0 )
        then 
          case
            when num_campuses < (fiber_lines )
              then 0
            when num_campuses - (fiber_lines ) < copper_dsl_lines
              then num_campuses - (fiber_lines)
              else copper_dsl_lines
          end
        else 0
    end as nga_v2_known_unscalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 0 
        else 
          case
            when num_campuses < (fiber_lines + copper_dsl_lines)
              then 0
              else num_campuses - (fiber_lines + copper_dsl_lines)
          end
    end as nga_v2_assumed_unscalable_campuses,

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
  
  from agg_district_lines
)

  select 
--1) demographics
  districts.esh_id,
  districts.nces_cd,
  districts.name,
  ag121a."ULOCAL",
  districts.locale,
  districts.district_size,
  adc.ia_oversub_ratio,
  districts.district_type,
  districts.num_schools,
  districts.num_campuses,
  districts.num_students,
  districts.num_students_and_staff,
  (sc121a_frl.num_frl_students::numeric / sc121a_frl.num_tot_students::numeric) as FRL_Percent,
  districts.address,
  districts.city,
  districts.zip,
  ag121a."CONAME" as "county",
  districts.postal_cd,
  districts.latitude,
  districts.longitude,
--2) clean status  
  districts.exclude_from_analysis,
  districts.num_open_dirty_flags,
  district_contacted.clean_categorization, 
--3) goals
  districts.ia_bandwidth_per_student,
  case 
    when adc.ia_bandwidth_per_student >= 100 
      then true
      else false
  end as meeting_2014_goal_no_oversub,
  case 
    when adc.ia_bandwidth_per_student * ia_oversub_ratio >= 100 
      then true
      else false
  end as meeting_2014_goal_oversub,
  case 
    when adc.ia_bandwidth_per_student >= 1000 
      then true
      else false 
  end as meeting_2018_goal_no_oversub,
  case 
    when adc.ia_bandwidth_per_student * ia_oversub_ratio >= 1000 
      then true
      else false 
  end as meeting_2018_goal_oversub,
  districts.ia_cost_per_mbps,
--4) affordability
  case 
    when adc.ia_cost_per_mbps is null 
      then districts.ia_cost_per_mbps 
      else (adc.ia_cost_per_mbps/12)::varchar
  end as "monthly_ia_cost_per_mbps",
  (adc.ia_bandwidth_per_student/1000) * adc.num_students as total_ia_bw_mbps, 
  (adc.ia_bandwidth_per_student/1000) * adc.num_students * adc.ia_cost_per_mbps/12 as total_ia_monthly_cost,
  case 
    when adc.ia_cost_per_mbps/12.0<=3 
      then true 
      else false 
  end as meeting_$3_per_mbps_affordability_target,
--5) fiber
  COALESCE (
    case when (adc.all_IA_connectcat ILIKE '%Fiber%') then 'Fiber' else NULL end,
    case when (adc.all_IA_connectcat ILIKE '%Fixed Wireless%') then 'Fixed Wireless' else NULL end,
    case when (adc.all_IA_connectcat ILIKE '%Cable%' and adc.all_IA_connecttype ILIKE '%Cable%') then 'Cable' else NULL end,
    case when (adc.all_IA_connectcat ILIKE '%DSL%' and adc.all_IA_connecttype ILIKE '%DSL%') then 'DSL' else NULL end,
    case when (adc.all_IA_connectcat ILIKE '%Copper%') then 'Copper' else NULL end,
    case when (adc.all_IA_connectcat ILIKE '%Other%') then 'Other/Uncategorized' else 'None - Error' end
  ) as hierarchy_connect_category,
  adc.all_IA_connectcat,
  adc.all_IA_connecttype,
  adc.nga_v2_known_scalable_campuses,
  adc.nga_v2_assumed_scalable_campuses,
  adc.nga_v2_known_unscalable_campuses,
  adc.nga_v2_assumed_unscalable_campuses,
  adc.known_fiber_campuses,
  adc.assumed_fiber_campuses,
  adc.known_nonfiber_campuses,
  adc.assumed_nonfiber_campuses,
  adc.fiber_lines, 
  adc.fixed_wireless_lines,
  adc.cable_lines,
  adc.copper_dsl_lines,
  adc.other_uncategorized_lines,
--6) IA overview  
  adc.fiber_internet_upstream_lines,
  adc.fixed_wireless_internet_upstream_lines,
  adc.cable_internet_upstream_lines,
  adc.copper_dsl_internet_upstream_lines,
  other_uncategorized_internet_upstream_lines,
--7) WAN overview
  adc.wan_lines,
  districts.wan_cost_per_connection,
  districts.wan_bandwidth_low,
  districts.wan_bandwidth_high,
  adc.gt_1g_wan_lines,
  adc.lt_1g_fiber_wan_lines,
  adc.lt_1g_nonfiber_wan_lines,
--8) Procurement
  ada.ia_applicants,
  adc.dedicated_isp_sp,
  adc.dedicated_isp_services,
  adc.dedicated_isp_contract_expiration,
  adc.bundled_internet_sp,
  adc.bundled_internet_connections,
  adc.bundled_internet_contract_expiration,
  adc.upstream_applicants,
  adc.upstream_sp,
  adc.upstream_connections,
  adc.upstream_contract_expiration,
  adc.wan_applicants,
  adc.wan_sp,
  adc.wan_connections,
  adc.wan_contract_expiration

from  districts
left join district_contacted_2015 as district_contacted
on district_contacted.district_esh_id = districts.esh_id
left join sc121a_frl 
on sc121a_frl.nces_cd = districts.nces_cd
left join ag121a 
on districts.nces_cd = ag121a.nces_cd
left join agg_district_campus adc
on adc.district_esh_id = districts.esh_id
left join agg_district_apps ada
on districts.esh_id=ada.recipient_id

where districts.include_in_universe_of_districts = TRUE

/*
Author: Justine Schott
Created On Date: 2/9/2016
Last Modified Date: 06/13/2016
Name of QAing Analyst(s): Greg Kurzhals
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