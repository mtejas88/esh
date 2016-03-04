/*
Author: Greg Kurzhals
Created On Date: 2/18/2016
Last Modified Date: 
Name of QAing Analyst(s): 
Purpose: To classify districts in our sample on the district team requested fiber categorization.
Methodology: The query leverages the existing lines_to_district_by_line_item subquery to determine which 
circuits are receivied by which district. The "districts" and "line_items" tables are then joined to the 
the output of this sub-query, in order to bring in district-level summary statistics re: service providers
and contract length. 

Districts were each evaluated on the basis of three criteria indicative of ongoing fiber need:
1) the district receives at least one non-fiber circuit,
2) there is no WAN information available for the district (i.e. zero WAN lines allocated to district) ,
3) the district is not allocated any broadband services,
4) the district receives at least one lit fiber IA circuit under 100 mbps + the district is not meeting 
the 2018 connectivity goal,
5) the ONLY WAN circuits received by the district are low-bandwidth fiber circuits
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

district_providers as (
select district_esh_id,
array_to_string(array_agg(distinct line_items.applicant_name),',') as "applicants"

from lines_to_district_by_line_item

left join line_items
on lines_to_district_by_line_item.line_item_id=line_items.id

where broadband = true
and consortium_shared=false

GROUP BY district_esh_id),

ia_sp as (
select ldli.district_esh_id,
li.service_provider_name,
sum(ldli.allocation_lines*li.bandwidth_in_mbps) as "ia_bandwidth_sp",
sum(ldli.allocation_lines) as "ia_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "ia_mrc_sp",
sum(one_time_eligible_cost::numeric) as "ia_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "ia_contract_end_date_sp"

from lines_to_district_by_line_item ldli

left join line_items li
  on ldli.line_item_id = li.id
  
where (internet_conditions_met=true OR upstream_conditions_met=true)
and broadband = true
      and consortium_shared=false
      and not('videoconferencing'=any(open_flags))
      and not('exclude'=any(open_flags))
  
GROUP BY ldli.district_esh_id,
li.service_provider_name),

wan_sp as (
select ldli.district_esh_id,
li.service_provider_name,
sum(ldli.allocation_lines) as "wan_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "wan_mrc_sp",
sum(one_time_eligible_cost::numeric) as "wan_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "wan_contract_end_date_sp"

from lines_to_district_by_line_item ldli

left join line_items li
  on ldli.line_item_id = li.id
  
where wan_conditions_met=true
and broadband = true
      and consortium_shared=false
      and not('videoconferencing'=any(open_flags))
      and not('exclude'=any(open_flags))

GROUP BY ldli.district_esh_id,
li.service_provider_name),


district_line_items as (
  select  d.esh_id,
          d.name, 
          d.postal_cd,
          d.address,
          d.city,
          d.nces_cd,
          d.locale,
          d.percentage_fiber,
          d.ia_cost_per_mbps,
          d.num_students,
          d.num_schools,
          d.num_campuses,
          d.exclude_from_analysis,
          case when d.ia_bandwidth_per_student not in ('Insufficient data', 'Infinity') 
          then d.ia_bandwidth_per_student::numeric else null end as "ia_bandwidth_per_student",
          
          case 
            when d.district_size in ('Tiny', 'Small') 
              then 1
            when d.district_size='Medium' 
              then 1.5
            when d.district_size='Large' 
              then 1.75
          else 2.25 end as ia_oversub_factor,
          
          sum(case when ldli.allocation_lines is not null
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ldli.allocation_lines else 0 end) as total_lines,
          
          sum(case
              when li.connect_category = 'Fiber'
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_lines,
          
          
          sum(case when (internet_conditions_met=true OR upstream_conditions_met=true)
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ldli.allocation_lines else 0 end) as total_ia_lines,
          
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_ia_lines,
          
          sum(case
              when li.connect_category = 'Fiber' and (wan_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_wan_lines,
          
              
          
          sum(case when wan_conditions_met=true
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ldli.allocation_lines else 0 end) as total_wan_lines,
          
          array_agg(distinct case when (internet_conditions_met=true OR upstream_conditions_met=true)
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))then connect_category
          else null end) as "ia_technology",
          
          array_agg(distinct case when wan_conditions_met=true and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags)) then connect_category
          else null end) as "wan_technology",
          
          
          sum(case
              when li.connect_category = 'Fiber' 
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_circuit_count,
          
          sum(case
              when li.connect_category = 'Fiber' 
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))and (internet_conditions_met=true OR upstream_conditions_met=true)
              and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_ia_circuit_count,
          
          sum(case
              when li.connect_category = 'Fiber' and wan_conditions_met=true
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
              and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_wan_circuit_count,
          
          
          
          sum(case
              when li.connect_type = 'Cable Modem' 
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
              and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as cable_ia_count,
          sum(case
              when li.connect_type = 'Digital Subscriber Line (DSL)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as dsl_ia_count,
          sum(case
              when li.connect_type = 'DS-1 (T-1)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as t1_ia_count,
          sum(case
              when li.connect_type = 'DS-3 (T-3)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as t3_ia_count,
          sum(case
              when li.connect_category = 'Fixed Wireless' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines
                else 0
            end
          ) as fixedwireless_ia_count,
          
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as fiber_ia_bandwidth,

          sum(case
              when li.connect_category != 'Fiber' and
                   (internet_conditions_met = true or upstream_conditions_met = true)
                   and not('videoconferencing'=any(open_flags))
                   and not('exclude'=any(open_flags))
                then ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as "non-fiber_ia_bandwidth",
          
          sum(case
              when li.connect_category != 'Fiber' 
                  and connect_type not in ('DS-3 (T-3)', 'DS-1 (T-1)', 'Digital Subscriber Line (DSL)', 'Cable Modem') 
                  and (internet_conditions_met = true or upstream_conditions_met = true)
                  and not('videoconferencing'=any(open_flags))
                  and not('exclude'=any(open_flags))
                then ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as other_ia_bandwidth

  from districts d
  left join lines_to_district_by_line_item ldli
  on d.esh_id = ldli.district_esh_id
  left join line_items li
  on ldli.line_item_id = li.id

  where d.include_in_universe_of_districts = true
  and broadband = true
      and consortium_shared=false
  and (d.postal_cd = '{{state}}' or 'All' = '{{state}}')

  group by  d.esh_id,
          d.name, 
          d.address,
          d.postal_cd,
          d.city,
          d.nces_cd,
          d.locale,
          d.ia_cost_per_mbps,
          d.num_students,
          d.num_schools,
          d.num_campuses,
          d.percentage_fiber,
          d.exclude_from_analysis,
          d.district_size,
          case when d.ia_bandwidth_per_student not in ('Insufficient data', 'Infinity') 
          then d.ia_bandwidth_per_student::numeric else null end
          
),

revised_demographics as (
select case when "FIPST"<10 then concat('0',LEFT("NCESSCH",6)) 
else LEFT("NCESSCH",7) end as "district_nces",
count(*) as "num_all_schools",
sum(case when "CHARTR"='1' then 1 else 0 end) as "num_charter_schools",
sum("MEMBER"::numeric) as "num_students_all_schools"

from sc121a

where "MSTATE"!='VT'

GROUP BY case when "FIPST"<10 then concat('0',LEFT("NCESSCH",6)) else LEFT("NCESSCH",7) end),

revised_demographics_VT as (
select ag121a."LEAID",
ag121a."UNION",
su."num_all_schools",
su."num_charter_schools",
su."num_students_all_schools"

from ag121a

left join lateral (
select "UNION",
count(*) as "num_all_schools",
sum(case when "CHARTR"='1' then 1 else 0 end) as "num_charter_schools",
sum("MEMBER"::numeric) as "num_students_all_schools"

from sc121a

where "MSTATE"='VT'

GROUP BY "UNION") su
on ag121a."UNION"=su."UNION"

where "MSTATE"='VT' and "TYPE"=3),

demographics_updated as (
select revised_demographics."district_nces",
revised_demographics."num_all_schools",
revised_demographics."num_charter_schools",
revised_demographics."num_students_all_schools"
from revised_demographics
union
select revised_demographics_VT."LEAID" as "district_nces",
revised_demographics_VT."num_all_schools",
revised_demographics_VT."num_charter_schools",
revised_demographics_VT."num_students_all_schools"
from revised_demographics_VT),

--clean categorization sub-queries
ad as (
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
                select ad.line_item_id,
                      version_order.contacted,
                      ad.district_esh_id,
                      case when 'assumed_ia' = any(open_flags)
                            or 'assumed_wan' = any(open_flags)
                            or 'assumed_fiber' = any(open_flags)
                      then true else false end as assumed_flags
                      
                from ad
                left join version_order
                on ad.line_item_id = version_order.fy2015_item21_services_and_cost_id
                left join line_items
                on ad.line_item_id = line_items.id
                
                where (row_num = 1
                or row_num is null)
                and exclude = false
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
),

criteria as (

  select  esh_id,
          case when exclude_from_analysis=false then 'clean' else 'dirty' end as "clean_status",
          case when exclude_from_analysis=false then clean_categorization
          else 'dirty' end as "how_cleaned",
          array_to_string(ia_technology, ', ') as "ia_technology",
          array_to_string(wan_technology, ', ') as "wan_technology",
          percentage_fiber,
          num_students,
          num_schools,
          num_campuses,
          total_lines,
          fiber_lines,
          total_ia_lines,
          fiber_ia_lines,
          total_wan_lines,
          fiber_wan_lines,
          lowfiber_circuit_count,
          
          lowfiber_ia_circuit_count,
          lowfiber_wan_circuit_count,
          
          
          fiber_ia_bandwidth+"non-fiber_ia_bandwidth" as "total_ia_bandwidth",
          fiber_ia_bandwidth,
          "non-fiber_ia_bandwidth",
          case when fiber_ia_bandwidth+"non-fiber_ia_bandwidth">0 
          then (fiber_ia_bandwidth/(fiber_ia_bandwidth+"non-fiber_ia_bandwidth"))
          else null end as "pct_ia_bandwidth_over_fiber",
          
          case when ia_cost_per_mbps not in ('Insufficient data', 'Infinity') then (ia_cost_per_mbps::numeric/12)::varchar
          else ia_cost_per_mbps end as "ia_cost_per_mbps_monthly",
          ia_bandwidth_per_student,
          
          
        case when district_line_items.ia_bandwidth_per_student is null
        then 'unknown'
        when ia_bandwidth_per_student<100
        then 'not meeting'
        else 'meeting' end as "100_kbps_goal_status",
        
        case when district_line_items.ia_bandwidth_per_student is null
        then 'unknown'
        when ia_bandwidth_per_student*ia_oversub_factor<100
        then 'not meeting'
        else 'meeting' end as "100_kbps_goal_status_w/oversub",
          
          case 
            when exclude_from_analysis = true 
              then 'unknown'
            when fiber_ia_lines > 0 
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
            when fiber_ia_lines > 0 
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
          end as district_able_to_meet_2014_goal_given_current_circuits_incl_oversubscription,
          ia_service_providers.*,
          wan_service_providers.*

  from district_line_items
  
  left join district_contacted
  on district_line_items.esh_id=district_contacted.district_esh_id
  
  left join lateral (
  select ia_sp.district_esh_id,
  array_to_string(array_agg(ia_sp.service_provider_name), ',') as "ia_service_providers",
  array_to_string(array_agg(ia_sp.ia_bandwidth_sp), ',') as "ia_bandwidth_by_service_provider",
  array_to_string(array_agg(ia_sp.ia_lines_sp), ',') as "ia_lines_by_service_provider",
  array_to_string(array_agg(ia_sp.ia_mrc_sp), ',') as "ia_mrc_by_service_provider",
  array_to_string(array_agg(ia_sp.ia_nrc_sp), ',') as "ia_nrc_by_service_provider",
  array_to_string(array_agg(ia_sp.ia_contract_end_date_sp), ',') as "ia_contract_end_date_by_service_provider"
  
  from ia_sp
  
  GROUP BY ia_sp.district_esh_id) ia_service_providers
  on district_line_items.esh_id=ia_service_providers.district_esh_id
  
  left join lateral (
  select wan_sp.district_esh_id,
  array_to_string(array_agg(wan_sp.service_provider_name), ',') as "wan_service_providers",
  array_to_string(array_agg(wan_sp.wan_lines_sp), ',') as "wan_lines_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_mrc_sp), ',') as "wan_mrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_nrc_sp), ',') as "wan_nrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_contract_end_date_sp), ',') as "wan_contract_end_date_by_service_provider"
  
  from wan_sp
  
  GROUP BY wan_sp.district_esh_id) wan_service_providers
  on district_line_items.esh_id=wan_service_providers.district_esh_id

  ),
  
--Form 471 sub-queries

form_470 as (
select f.entity_id,
array_to_string(array_agg(distinct case when fy2015_form470s."Internet/Telecom Services" is not null 
then fy2015_form470s."Internet/Telecom Services" else 'N/A' end), ',') as "Internet/Telecom Services",
array_to_string(array_agg(distinct case when fy2015_form470s."Internet/Telecom RFP URL" is not null
then fy2015_form470s."Internet/Telecom RFP URL" else 'N/A' end), ',') as "Internet/Telecom RFP URL",
array_to_string(array_agg(distinct case when fy2015_form470s."Internet Access" is not null
then fy2015_form470s."Internet Access" else 'N/A' end), ',') as "Internet Access",
array_to_string(array_agg(distinct case when fy2015_form470s."Internet RFP URL" is not null
then fy2015_form470s."Internet RFP URL" else 'N/A' end), ',') as "Internet RFP URL",
array_to_string(array_agg(distinct case when fy2015_form470s."Number of Sites" is not null
then fy2015_form470s."Number of Sites" else 'N/A' end), ',') as "Number of Sites",
array_to_string(array_agg(distinct case when fy2015_form470s."Details" is not null
then fy2015_form470s."Details" else 'N/A' end), ',') as "Details"

from public.fy2015_form470s

right join lateral (
select e.*,
d.name

from esh_id_mappings e

left join districts d
on e.entity_id=d.esh_id) f

on fy2015_form470s."Applicant Entity Number"=f.ben
where /*"State"='MA'
and */"Applicant Name" NOT LIKE '%LIBRARY%'
GROUP BY f.entity_id),

forms as (
select form_470.entity_id as "esh_id",
q.*,
form_470.*

from form_470

left join lateral (
select li.applicant_id,
array_to_string(array_agg(distinct conn."Application Number"), ',') as "form_471_number",
array_to_string(array_agg(distinct conn."WAN"), ',') as "schools_with_wan_scalable_to_10_gbps",
array_to_string(array_agg(distinct conn."BroadBand Too Slow"), ',') as "broadband_too_slow",
array_to_string(array_agg(distinct conn."Phys Strct"), ',') as "physical_structure_of_buildings",
array_to_string(array_agg(distinct conn."Undep Service"), ',') as "inconsistent_service",
array_to_string(array_agg(distinct conn."Equip Too $"), ',') as "equipment_too_costly",
array_to_string(array_agg(distinct conn."Inadeq LAN"), ',') as "inadequate_lan_or_wiring",
array_to_string(array_agg(distinct conn."Install Too $"), ',') as "installation_too_costly",
array_to_string(array_agg(distinct conn."Lack Train"), ',') as "lack_of_training_tech_support",
array_to_string(array_agg(distinct conn."Other"), ',') as "other",
array_to_string(array_agg(distinct conn."Outdate Equip"), ',') as "outdated_equipment",
array_to_string(array_agg(distinct conn."Comp Suff"), ',') as "schools_comp_suff_lan_wlan",
array_to_string(array_agg(distinct conn."Most Suff"), ',') as "schools_mostly_suff_lan_wlan",
array_to_string(array_agg(distinct conn."Some Suff"), ',') as "schools_sometimes_suff_lan_wlan",
array_to_string(array_agg(distinct conn."Rare Suff"), ',') as "schools_rarely_suff_lan_wlan",
array_to_string(array_agg(distinct conn."Not Suff"), ',') as "schools_not_suff_lan_wlan"

from public.fy2015_connectivity_questions conn

left join line_items li
on conn."Application Number"=li.application_number

GROUP BY applicant_id) q
on form_470.entity_id=q.applicant_id)
  
select districts.esh_id, 
districts.name, 
districts.postal_cd,
districts.city,
demographics_updated.*,
district_providers.applicants,
case when total_lines>fiber_lines then 'Yes'
else 'No' end as "Receives non-fiber circuit",

case when ((total_wan_lines=0 OR total_wan_lines is null) and num_all_schools>1) then 'Yes'
else 'No' end as "No WAN information",
case when total_lines=0 OR total_lines is null
then 'Yes' else 'No' end as "Zero E-rated services",
case when lowfiber_ia_circuit_count>0 and districts.ia_bandwidth_per_student!='Insufficient data' 
and districts.ia_bandwidth_per_student::numeric<1000
then 'Yes' else 'No' end as "low_bandwidth_fiber_IA",

case when lowfiber_wan_circuit_count>0 and lowfiber_wan_circuit_count=fiber_wan_lines
then 'Yes' else 'No' end as "low_bandwidth_fiber_WAN",

criteria.clean_status,
how_cleaned,
case when ia_technology is null then 'Unknown' else ia_technology end as "ia_technology",
case when wan_technology is null then 'Unknown' else wan_technology end as "wan_technology",
--criteria.percentage_fiber,
total_lines,
fiber_lines as "fiber_lines_ia_and_wan",
total_ia_lines,
fiber_ia_lines,
total_wan_lines,
fiber_wan_lines,
lowfiber_circuit_count,

lowfiber_ia_circuit_count,
lowfiber_wan_circuit_count,

total_ia_bandwidth,
fiber_ia_bandwidth,
"non-fiber_ia_bandwidth",
pct_ia_bandwidth_over_fiber,
criteria.ia_cost_per_mbps_monthly,
criteria.ia_bandwidth_per_student,
"100_kbps_goal_status",
"100_kbps_goal_status_w/oversub",
"district_able_to_meet_2014_goal_given_current_circuits",
"district_able_to_meet_2014_goal_given_current_circuits_incl_oversub",
ia_service_providers,
ia_bandwidth_by_service_provider,
ia_lines_by_service_provider,
ia_mrc_by_service_provider,
ia_nrc_by_service_provider,
ia_contract_end_date_by_service_provider,

wan_service_providers,
wan_lines_by_service_provider,
wan_mrc_by_service_provider,
wan_nrc_by_service_provider,
wan_contract_end_date_by_service_provider

from districts

left join criteria
on districts.esh_id=criteria.esh_id

left join demographics_updated
on districts.nces_cd=demographics_updated.district_nces

left join district_providers
on districts.esh_id=district_providers.district_esh_id

where (clean_status='{{clean_status}}' OR 'All'='{{clean_status}}') and
(total_lines>fiber_lines
OR
total_lines=0 
OR
total_lines is null
OR
((total_wan_lines=0 OR total_wan_lines is null) and num_all_schools>1)
OR
(lowfiber_ia_circuit_count>0 and districts.ia_bandwidth_per_student!='Insufficient data' 
and districts.ia_bandwidth_per_student::numeric<1000)
OR
(lowfiber_wan_circuit_count>0 and lowfiber_wan_circuit_count=fiber_wan_lines))

ORDER BY districts.postal_cd, districts.esh_id

{% form %}

state:
  type: text
  default: 'All'
  
bandwidth_less_than_equal_to:
  type: text
  default: '100'
  
clean_status:
  type: select
  default: 'All'
  options: [['All'],
            ['clean'],
            ['dirty']
            ]

{% endform %}