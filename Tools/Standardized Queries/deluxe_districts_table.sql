/*
Author: Justine Schott
Created On Date: 2/9/2016
Last Modified Date: 07/18/2016
Name of QAing Analyst(s): Greg Kurzhals; last modified by Jess Seok
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
9) Meeting Goals metrics adjusted for FCC's new definition of broadband: districts is meeting IA goal if it has at least 100 kbps per student AND at least 1 25 Mbps circuit
*/

with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
),

--Lines 27-203 - all services

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
/*Joins "line_items" table to add relevant cost, bandwidth, connection type, and purpose information; joins "districts" table
to add demographic data used in metric calculations*/
services_received as (
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
      
      round((case when li.consortium_shared=false 
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
      end), 2) as line_item_district_monthly_cost_adjusted,

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
      li.open_flags,
      li.contract_end_date,
      
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
         OR 'backbone'=any(li.open_flags)
       )  
       and d.include_in_universe_of_districts=true 
       and (case when 'exclude'=any(li.open_flags) then true else false end)=false
       and not('video_conferencing'=any(open_flags))
       and not('charter_service'=any(open_flags))
),

procurement_type as (
select recipient_id,
array_to_string(array_agg(distinct case when ia_conditions_met=true then 
concat(applicant_name,
case when consortium_shared=true
then ' (shared)'
when consortium_shared=false and isp_conditions_met=true
then ' (dedicated ISP only)'
when consortium_shared=false and internet_conditions_met=true
then ' (dedicated Internet)'
else ' (unknown purpose)'
end)end), '; ') as "ia_applicants",

array_to_string(array_agg(distinct case when ia_conditions_met=true and consortium_shared=true then applicant_name else null end), '; ') as "shared_ia_applicants",


array_to_string(array_agg(distinct case when isp_conditions_met=true and consortium_shared=false then applicant_name else null end), '; ') as "dedicated_isp_applicants",
array_to_string(array_agg(distinct case when internet_conditions_met=true and consortium_shared=false then applicant_name else null end), '; ') as "bundled_internet_applicants",
array_to_string(array_agg(distinct case when internet_conditions_met=true and consortium_shared=false then bandwidth_in_mbps else null end), '; ') as "bundled_internet_bandwidth_li",
array_to_string(array_agg(distinct case when upstream_conditions_met=true and consortium_shared=false then applicant_name else null end), '; ') as "upstream_applicants",
array_to_string(array_agg(distinct case when upstream_conditions_met=true and consortium_shared=false then bandwidth_in_mbps else null end), '; ') as "upstream_internet_bandwidth_li",

array_to_string(array_agg(distinct case when wan_conditions_met=true and consortium_shared=false then applicant_name end), '; ') as "wan_applicants",

sum(distinct case when internet_conditions_met=true and consortium_shared=false then bandwidth_in_mbps else null end) as "bundled_internet_bandwidth",
sum(distinct case when upstream_conditions_met=true and consortium_shared=false then bandwidth_in_mbps else null end) as "upstream_bandwidth",

--dedicated ISP
array_to_string(array_agg(
            case when isp_conditions_met=true and consortium_shared=false
                then 
                concat(quantity_of_lines_received_by_district, ' ', ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                end), '; ') as "dedicated_isp_services",
                
                array_to_string(array_agg(case when isp_conditions_met=true and consortium_shared=false
                then concat(service_provider_name, ' - ', extract(month from contract_end_date::timestamp), '/', extract(year from contract_end_date::timestamp)) end), '; ') as "dedicated_isp_contract_expiration",





--bundled IA
array_to_string(array_agg(
            case when internet_conditions_met=true and consortium_shared=false
                then 
                concat(quantity_of_lines_received_by_district, ' ', ( 
                    case when connect_category='Cable / DSL'
                    and connect_type='Cable Modem'
                    then 'Cable'
                    when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                    then 'DSL'
                    when connect_category='Copper'
                    and bandwidth_in_mbps::numeric=45 
                    then 'T-3'
                    when connect_category='Copper'
                    and round(bandwidth_in_mbps::numeric, 1)=1.5 then 'T-1'
                else connect_category end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                end), '; ') as "bundled_internet_connections",
                
                array_to_string(array_agg(case when internet_conditions_met=true and consortium_shared=false
                then concat(service_provider_name, ' - ', extract(month from contract_end_date::timestamp), '/', extract(year from contract_end_date::timestamp)) end), '; ') as "bundled_internet_contract_expiration",


--upstream
array_to_string(array_agg(
            case when upstream_conditions_met=true and consortium_shared=false
                then 
                concat(quantity_of_lines_received_by_district, ' ', ( 
                    case when connect_category='Cable / DSL'
                    and connect_type='Cable Modem'
                    then 'Cable'
                    when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                    then 'DSL'
                    when connect_category='Copper'
                    and bandwidth_in_mbps::numeric=45 
                    then 'T-3'
                    when connect_category='Copper'
                    and round(bandwidth_in_mbps::numeric, 1)=1.5 then 'T-1'
                else connect_category end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                end), '; ') as "upstream_connections",
                
                array_to_string(array_agg(case when upstream_conditions_met=true and consortium_shared=false
                then concat(service_provider_name, ' - ', extract(month from contract_end_date::timestamp), '/', extract(year from contract_end_date::timestamp)) end), '; ') as "upstream_contract_expiration",

--WAN                
array_to_string(array_agg(
            case when wan_conditions_met=true and consortium_shared=false
                then 
                concat(quantity_of_lines_received_by_district, ' ', ( 
                    case when connect_category='Cable / DSL'
                    and connect_type='Cable Modem'
                    then 'Cable'
                    when connect_category='Cable / DSL' and connect_type='Digital Subscriber Line (DSL)'
                    then 'DSL'
                    when connect_category='Copper'
                    and bandwidth_in_mbps::numeric=45 
                    then 'T-3'
                    when connect_category='Copper'
                    and round(bandwidth_in_mbps::numeric, 1)=1.5 then 'T-1'
                else connect_category end), ' line(s) at ', bandwidth_in_mbps, ' Mbps from ', service_provider_name, ' for $', line_item_district_monthly_cost_adjusted, '/mth')
                end), '; ') as "wan_connections",
                
                array_to_string(array_agg(case when wan_conditions_met=true and consortium_shared=false
                then concat(service_provider_name, ' - ', extract(month from contract_end_date::timestamp), '/', extract(year from contract_end_date::timestamp)) end), '; ') as "wan_contract_expiration"
        

from services_received svcs

GROUP BY recipient_id),
--Lines 207-633 - only district-dedicated services

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
   /* sum(case when li.connect_category in ('Fiber', 'Fixed Wireless') 
          then cd.allocation_lines
          else 0
        end) as fiber_equiv_lines,*/
    sum(case when li.connect_category = 'Fiber' 
          then cd.allocation_lines
          else 0
        end) as fiber_lines,
    sum(case when li.connect_category = 'Fixed Wireless' 
          then cd.allocation_lines
          else 0
        end) as fixed_wireless_lines,
    sum(case when li.connect_category not in ('Fiber', 'Other / Uncategorized') 
          then cd.allocation_lines
          else 0
        end) as non_fiber_lines,
    sum(case when li.connect_type = 'Cable Modem' 
          then cd.allocation_lines
          else 0
        end) as cable_lines,
    sum(case when (li.connect_type != 'Cable Modem' and li.connect_category in ('Copper', 'Cable / DSL'))
          OR
          'ethernet_copper'=any(li.open_flags)
          then cd.allocation_lines
          else 0
        end) as copper_dsl_lines,
        
    sum(case when isp_conditions_met=false and connect_category not in ('Fiber',
    'Fixed Wireless', 'Cable / DSL', 'Copper')
    and not('ethernet_copper'=any(li.open_flags))
    then cd.allocation_lines
    else 0
    end) as other_uncategorized_lines,
    
    sum(case when li.wan_conditions_met = true and exclude = false and (not('backbone'=any(open_flags)) or open_flags is null)
          then cd.allocation_lines
          else 0
        end) as wan_lines,
    sum(case when bandwidth_in_mbps >= 1000 and wan_conditions_met = true and exclude = false and (not('backbone'=any(open_flags)) or open_flags is null)
          then cd.allocation_lines
          else 0 
        end) as gt_1g_wan_lines,
    sum(case when bandwidth_in_mbps < 1000 and connect_category = 'Fiber' and wan_conditions_met = true and exclude = false and (not('backbone'=any(open_flags)) or open_flags is null)
          then cd.allocation_lines
          else 0 
        end) as lt_1g_fiber_wan_lines,
    sum(case when bandwidth_in_mbps < 1000 and connect_category != 'Fiber' and wan_conditions_met = true  and exclude = false and (not('backbone'=any(open_flags)) or open_flags is null)
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
    sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and 
    (li.connect_type != 'Cable Modem' and connect_category in ('Cable / DSL', 'Copper'))
    OR 
    'ethernet_copper'=any(open_flags) 
    then cd.allocation_lines
        else 0 end) as copper_dsl_internet_upstream_lines,
    sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and connect_type = 'Cable Modem' 
          then cd.allocation_lines
        else 0 end) as cable_internet_upstream_lines,
        
    sum(case when (internet_conditions_met = true or upstream_conditions_met = true) 
    and isp_conditions_met=false and connect_category not in ('Fiber',
    'Fixed Wireless', 'Cable / DSL','Copper')
    and not('ethernet_copper'=any(li.open_flags))
    then cd.allocation_lines
    else 0 end) as other_uncategorized_internet_upstream_lines,
    
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
      array_agg( distinct
        case 
          when internet_conditions_met = TRUE 
            then reporting_name
        end --order by service_provider_name
      ), ', ') as "internet_sp_parent",
    
    count( distinct 
      case 
        when internet_conditions_met = TRUE 
          then service_provider_name 
      end
    ) as "bundled_internet_sp_count",
    
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
      
--Circuits that affect goal meeting metrics under FCC's new broadband definition
--no-fiber consideration in the definition per meeting with Evan on 7/15/16
  
  sum(case when (internet_conditions_met = true or upstream_conditions_met = true) and bandwidth_in_mbps < 25 
              then cd.allocation_lines
           else 0 end) as NotBB_internet_upstream_lines,  -- number of IA/Upstream lines that are less than 25 mbps (includes low-bandwidth fiber
  sum(case when (internet_conditions_met = true or upstream_conditions_met = true) 
              then cd.allocation_lines
           else 0 end) as Tot_internet_upstream_lines -- number of IA/Upstream lines 

            
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
    /*case
      when num_campuses < fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
        then num_campuses 
        else fiber_equiv_lines + case when num_students < 100 then cable_lines else 0 end
    end as known_scalable_campuses,
    case calc
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
      when num_campuses < fiber_lines + case when num_students < 100 then cable_lines+fixed_wireless_lines else 0 end
        then num_campuses 
        else fiber_lines + case when num_students < 100 then cable_lines+fixed_wireless_lines else 0 end
    end as nga_v1_known_scalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 
          case 
            when num_campuses > fiber_lines + case when num_students < 100 then cable_lines+fixed_wireless_lines else 0 end
              then num_campuses - fiber_lines + case when num_students < 100 then cable_lines+fixed_wireless_lines else 0 end
              else 0
          end
        else 0
    end as nga_v1_assumed_scalable_campuses,
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
      when num_students >= 100 and (copper_dsl_lines + cable_lines + fixed_wireless_lines)> 0  and not(num_schools > 5 and wan_lines = 0 ) 
        then
          case
            when num_campuses < (fiber_lines)
              then 0
            when num_campuses - (fiber_lines ) < copper_dsl_lines + cable_lines + fixed_wireless_lines
              then num_campuses - (fiber_lines)
              else copper_dsl_lines + cable_lines + fixed_wireless_lines
          end
        else 0
    end as nga_v1_known_unscalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 0 
        else 
          case
            when num_campuses < (fiber_equiv_lines + copper_dsl_lines + cable_lines)
              then 0
              else num_campuses - (fiber_equiv_lines + copper_dsl_lines + cable_lines)
          end
    end as nga_v1_assumed_unscalable_campuses,
*/
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
    
  from cdd
),

av as (
        select distinct district_esh_id, a.line_item_id
        from allocations a
        join district_lookup dl
          on dl.esh_id = a.recipient_id
        where broadband = true
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
  --1) demographics
  districts.esh_id,
  districts.nces_cd,
  districts.name,
  ag121a."ULOCAL",
  districts.locale,
  districts.district_size,
  cdd_calc.ia_oversub_ratio,
  --districts.consortium_member,
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
  
  districts.ia_cost_per_mbps,
  
  --4) affordability
  
  case 
    when cdd_calc.ia_cost_per_mbps is null 
      then districts.ia_cost_per_mbps 
      else (cdd_calc.ia_cost_per_mbps/12)::varchar
  end as "monthly_ia_cost_per_mbps",
  (cdd_calc.ia_bandwidth_per_student/1000) * cdd_calc.num_students as total_ia_bw_mbps, 
  (cdd_calc.ia_bandwidth_per_student/1000) * cdd_calc.num_students * cdd_calc.ia_cost_per_mbps/12 as total_ia_monthly_cost,

  case 
    when cdd_calc.ia_cost_per_mbps/12.0<=3 
      then true 
      else false 
  end as meeting_$3_per_mbps_affordability_target,
  
  /*districts.percentage_fiber,
  districts.highest_connect_type,*/
  --5) fiber
  COALESCE (
    case when (cdd_calc.all_IA_connectcat ILIKE '%Fiber%') then 'Fiber' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Fixed Wireless%') then 'Fixed Wireless' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Cable%' and cdd_calc.all_IA_connecttype ILIKE '%Cable%') then 'Cable' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%DSL%' and cdd_calc.all_IA_connecttype ILIKE '%DSL%') then 'DSL' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Copper%') then 'Copper' else NULL end,
    case when (cdd_calc.all_IA_connectcat ILIKE '%Other%') then 'Other/Uncategorized' else 'None - Error' end
  ) as hierarchy_connect_category,
  cdd_calc.all_IA_connectcat,
  cdd_calc.all_IA_connecttype,
  cdd_calc.nga_v2_known_scalable_campuses,
  cdd_calc.nga_v2_assumed_scalable_campuses,
  cdd_calc.nga_v2_known_unscalable_campuses,
  cdd_calc.nga_v2_assumed_unscalable_campuses,
  
  cdd_calc.known_fiber_campuses,
  cdd_calc.assumed_fiber_campuses,
  cdd_calc.known_nonfiber_campuses,
  cdd_calc.assumed_nonfiber_campuses,
  
  cdd_calc.fiber_lines, 
  cdd_calc.fixed_wireless_lines,
  cdd_calc.cable_lines,
  cdd_calc.copper_dsl_lines,
  cdd_calc.other_uncategorized_lines,
  
--6) IA overview  
  cdd_calc.fiber_internet_upstream_lines,
  cdd_calc.fixed_wireless_internet_upstream_lines,
  cdd_calc.cable_internet_upstream_lines,
  cdd_calc.copper_dsl_internet_upstream_lines,
  other_uncategorized_internet_upstream_lines,
  
--7) WAN overview
  cdd_calc.wan_lines,
  districts.wan_cost_per_connection,
  districts.wan_bandwidth_low,
  districts.wan_bandwidth_high,
  cdd_calc.gt_1g_wan_lines,
  cdd_calc.lt_1g_fiber_wan_lines,
  cdd_calc.lt_1g_nonfiber_wan_lines,

--8) Procurement
  pt.ia_applicants,
  cdd_calc."dedicated_isp_sp",
  pt.dedicated_isp_services,
  pt.dedicated_isp_contract_expiration,
  --cdd_calc."Internet_SP_Parent",
  cdd_calc."bundled_internet_sp",
  pt.bundled_internet_connections,
  pt.bundled_internet_contract_expiration,
  pt.upstream_applicants,
  cdd_calc."upstream_sp",
  pt.upstream_connections,
  pt.upstream_contract_expiration,
  pt.wan_applicants,
  cdd_calc."wan_sp",
  pt.wan_connections,
  pt.wan_contract_expiration,
  

  
  
  /*,
  district_contacted.totally_verified, 
  cdd_calc.nga_v1_known_scalable_campuses,
  cdd_calc.nga_v1_assumed_scalable_campuses,
  cdd_calc.nga_v1_known_unscalable_campuses,
  cdd_calc.nga_v1_assumed_unscalable_campuses,
  cdd_calc.known_scalable_campuses,
  cdd_calc.assumed_scalable_campuses,
  cdd_calc.known_unscalable_campuses,
  cdd_calc.assumed_unscalable_campuses, 


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
  as percent_scalable_IA,*/ 

-- Columns that indicate whether district is meeting IA goals under new FCC broadband definition
-- i.e. In addition to meeting the bandwidth floor, district must have at least one >=25 mbps IA/Upstream circuit
case 
    when cdd_calc.ia_bandwidth_per_student >= 100   -- meetings bandwidth
      and cdd_calc.Tot_internet_upstream_lines - cdd_calc.NotBB_internet_upstream_lines > 0  -- at least one circuit that is not less than 25 mbps 
      then TRUE
      else FALSE 
end as meeting_2014_goal_no_oversub_fcc_25, 
case 
  when cdd_calc.ia_bandwidth_per_student * ia_oversub_ratio >= 1000   -- meetings bandwidth after taking account of oversubscription ratio
    and cdd_calc.Tot_internet_upstream_lines - cdd_calc.NotBB_internet_upstream_lines > 0  -- at least one circuit that is not less than 25 mbps & non-fiber connect type
    then TRUE
    else FALSE 
end as meeting_2018_goal_oversub_fcc_25 -- TRUE if NOT ALL IA/upstream circuits are <25 mbps AND nonfiber


  from  districts
  left join district_contacted 
  on district_contacted.district_esh_id = districts.esh_id
  left join sc121a_frl 
  on sc121a_frl.nces_cd = districts.nces_cd
  left join ag121a 
  on districts.nces_cd = ag121a.nces_cd
  left join cdd_calc 
  on cdd_calc.district_esh_id = districts.esh_id
  
left join procurement_type pt
on districts.esh_id=pt.recipient_id

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