/*Author: Greg Kurzhals
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

charter_agencies as (
select distinct ag121a.nces_cd,
esh_id_mappings.entity_id

from ag121a

left join esh_id_mappings
on ag121a.nces_cd=LEFT(esh_id_mappings.nces_code,7)

where "TYPE"=7 and "MSTATE" not in ('PR','AS','GU','VI')),

dl_ca_1 as (
select esh_id, district_esh_id, postal_cd
        from schools
        union
        select esh_id, district_esh_id, postal_cd
        from other_locations
        union 
        select esh_id, esh_id as district_esh_id, postal_cd
        from consortia),
        
dl_ca_2 as (
select *
from dl_ca_1
where district_esh_id in (
select entity_id
from charter_agencies)),

ca_ldli as (
select dl_ca_2.district_esh_id,
         c.line_item_id,
         count(distinct ec.circuit_id) as allocation_lines
        
  from entity_circuits ec
  join circuits c
  on ec.circuit_id = c.id
  join dl_ca_2
  on ec.entity_id = dl_ca_2.esh_id
  
  group by  district_esh_id,
         line_item_id
),

ca_providers as (
select district_esh_id,
array_to_string(array_agg(distinct line_items.applicant_name),',') as "applicants"

from ca_ldli

left join line_items
on ca_ldli.line_item_id=line_items.id

where broadband=true
and consortium_shared=false 
and not('videoconferencing'=any(open_flags))
and not('exclude'=any(open_flags))

GROUP BY district_esh_id),

ia_sp as (
select ca_ldli.district_esh_id,
li.service_provider_name,
sum(ca_ldli.allocation_lines*li.bandwidth_in_mbps) as "ia_bandwidth_sp",
sum(ca_ldli.allocation_lines) as "ia_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "ia_mrc_sp",
sum(one_time_eligible_cost::numeric) as "ia_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "ia_contract_end_date_sp"

from ca_ldli

left join line_items li
  on ca_ldli.line_item_id = li.id
  
where (internet_conditions_met=true OR upstream_conditions_met=true)
and broadband = true
and consortium_shared=false
and not('videoconferencing'=any(open_flags))
and not('exclude'=any(open_flags))
  
GROUP BY ca_ldli.district_esh_id,
li.service_provider_name),

wan_sp as (
select ca_ldli.district_esh_id,
li.service_provider_name,
sum(ca_ldli.allocation_lines) as "wan_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "wan_mrc_sp",
sum(one_time_eligible_cost::numeric) as "wan_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "wan_contract_end_date_sp"

from ca_ldli

left join
      line_items li
  on ca_ldli.line_item_id = li.id

where wan_conditions_met=true
and broadband = true
and consortium_shared=false
and not('videoconferencing'=any(open_flags))
and not('exclude'=any(open_flags))


GROUP BY ca_ldli.district_esh_id,
li.service_provider_name),

ca_line_items as (
  select ca_ldli.district_esh_id,
  ca_demo.nces_cd,
  ca_demo."NAME" as "name",
  ca_demo."MSTATE" as "state",
  ca_demo."MCITY" as "city",
  ca_demo."SCH" as "num_schools",
  ca_demo."MEMBER" as "num_students",
  case when ca_demo."ULOCAL" in (11,12,13)
  then 'Urban'
  when ca_demo."ULOCAL" in (23,21,22)
  then 'Suburban'
  when ca_demo."ULOCAL" in (33,31,32)
  then 'Small Town'
  when ca_demo."ULOCAL" in (43,41,42) 
  then 'Rural'
  else 'Unknown' end as "locale",
  
  
  case 
            when "SCH">0 and "SCH"<=5 
              then 1
            when "SCH">5 and "SCH"<=15
              then 1.5
            when "SCH">15 and "SCH"<=49 
              then 1.75
          else 2.25 end as ia_oversub_factor,
          
          sum(case when ca_ldli.allocation_lines is not null
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ca_ldli.allocation_lines else 0 end) as total_lines,
          
          sum(case
              when li.connect_category = 'Fiber'
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as fiber_lines,
          
          
          sum(case when (internet_conditions_met=true OR upstream_conditions_met=true)
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ca_ldli.allocation_lines else 0 end) as total_ia_lines,
          
          sum(case
              when li.connect_category = 'Fiber' 
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags)) 
              and (internet_conditions_met = true or upstream_conditions_met = true)
                then ca_ldli.allocation_lines
                else 0
            end
          ) as fiber_ia_lines,
          
          sum(case
              when li.connect_category = 'Fiber' and (wan_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as fiber_wan_lines,
          
              
          
          sum(case when wan_conditions_met=true 
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))
          then ca_ldli.allocation_lines else 0 end) as total_wan_lines,
          
          array_agg(distinct case when (internet_conditions_met=true OR upstream_conditions_met=true)
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags)) 
          then connect_category
          else null end) as "ia_technology",
          
          array_agg(distinct case when wan_conditions_met=true 
          and not('videoconferencing'=any(open_flags))
          and not('exclude'=any(open_flags))then connect_category
          else null end) as "wan_technology",
          
          
          sum(case
              when li.connect_category = 'Fiber' 
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
              and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ca_ldli.allocation_lines
                else 0
            end
          ) as lowfiber_circuit_count,
          
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met=true OR upstream_conditions_met=true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
              and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ca_ldli.allocation_lines
                else 0
            end
          ) as lowfiber_ia_circuit_count,
          
          sum(case
              when li.connect_category = 'Fiber' and wan_conditions_met=true
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
              and li.bandwidth_in_mbps < {{bandwidth_less_than_equal_to}}
                then ca_ldli.allocation_lines
                else 0
            end
          ) as lowfiber_wan_circuit_count,
          
          
          
          sum(case
              when li.connect_type = 'Cable Modem' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as cable_ia_count,
          sum(case
              when li.connect_type = 'Digital Subscriber Line (DSL)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as dsl_ia_count,
          sum(case
              when li.connect_type = 'DS-1 (T-1)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as t1_ia_count,
          sum(case
              when li.connect_type = 'DS-3 (T-3)' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as t3_ia_count,
          sum(case
              when li.connect_category = 'Fixed Wireless' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines
                else 0
            end
          ) as fixedwireless_ia_count,
          
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as fiber_ia_bandwidth,

          sum(case
              when li.connect_category != 'Fiber' 
              and (internet_conditions_met = true or upstream_conditions_met = true)
              and not('videoconferencing'=any(open_flags))
              and not('exclude'=any(open_flags))
                   
                then ca_ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as "non-fiber_ia_bandwidth",
          
          sum(case
              when li.connect_category != 'Fiber' 
                  and connect_type not in ('DS-3 (T-3)', 'DS-1 (T-1)', 'Digital Subscriber Line (DSL)', 'Cable Modem') 
                  and (internet_conditions_met = true or upstream_conditions_met = true)
                  and not('videoconferencing'=any(open_flags))
                  and not('exclude'=any(open_flags))
                then ca_ldli.allocation_lines*li.bandwidth_in_mbps
                else 0
            end
          ) as other_ia_bandwidth

  from ca_ldli
  
  left join lateral(
  select charter_agencies.entity_id,
  ag121a.*
  from charter_agencies
  left join ag121a
  on charter_agencies.nces_cd=ag121a.nces_cd) ca_demo
  on ca_ldli.district_esh_id=ca_demo.entity_id
  
  left join 
      line_items li 
  on ca_ldli.line_item_id = li.id

  where ca_demo."MSTATE" = '{{state}}' or 'All' = '{{state}}' and "SCH">0
  and broadband = true
  and consortium_shared=false

  group by ca_ldli.district_esh_id,
  ca_demo.nces_cd,
  ca_demo."NAME",
  ca_demo."MSTATE",
  ca_demo."MCITY",
  ca_demo."SCH",
  ca_demo."MEMBER",
  case when ca_demo."ULOCAL" in (11,12,13)
  then 'Urban'
  when ca_demo."ULOCAL" in (23,21,22)
  then 'Suburban'
  when ca_demo."ULOCAL" in (33,31,32)
  then 'Small Town'
  when ca_demo."ULOCAL" in (43,41,42) 
  then 'Rural'
  else 'Unknown' end,
  case 
            when "SCH">0 and "SCH"<=5 
              then 1
            when "SCH">5 and "SCH"<=15
              then 1.5
            when "SCH">15 and "SCH"<49 
              then 1.75
          else 2.25 end
          
),

criteria as (

  select  ca_line_items.district_esh_id,
  ca_line_items."name",
  ca_line_items."state",
  ca_line_items."city",
  ca_line_items."num_schools",
  ca_line_items."num_students",
  ca_line_items.nces_cd,
  ca_line_items.locale,
  ca_line_items.ia_oversub_factor,

          'unknown - charter agency' as "clean_status",
          'unknown - charter agency' as "how_cleaned",
          array_to_string(ia_technology, ', ') as "ia_technology",
          array_to_string(wan_technology, ', ') as "wan_technology",
          'unknown - charter agency' as num_campuses,
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
          
          'unknown - charter agency' as "ia_cost_per_mbps_monthly",
          case when num_students<=0 OR fiber_ia_bandwidth+"non-fiber_ia_bandwidth"=0
          then null
          else
          (fiber_ia_bandwidth+"non-fiber_ia_bandwidth")*1000.0/(num_students::numeric) end as "ia_bandwidth_per_student",
          
          
        case when num_students<=0 OR fiber_ia_bandwidth+"non-fiber_ia_bandwidth"=0
        then 'unknown'
        when (fiber_ia_bandwidth+"non-fiber_ia_bandwidth")*1000.0/(num_students::numeric)<100
        then 'not meeting'
        else 'meeting' end as "100_kbps_goal_status",
        
        case when num_students<=0 OR fiber_ia_bandwidth+"non-fiber_ia_bandwidth"=0
        then 'unknown'
        when ((fiber_ia_bandwidth+"non-fiber_ia_bandwidth")*1000.0*ia_oversub_factor::numeric)/(num_students::numeric)<100
        then 'not meeting'
        else 'meeting' end as "100_kbps_goal_status_w/oversub",
          
          case when total_ia_lines=0 
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
          
          case when total_ia_lines=0 
          then 'unknown'
        
            when fiber_ia_lines > 0 
                  or (num_students::numeric*.1 <= --2014 bw goal
                              ((cable_ia_count*150) +
                              (dsl_ia_count*50) +
                              (t1_ia_count*1.5) +
                              (t3_ia_count*45) +
                              (fixedwireless_ia_count*1000) +
                              other_ia_bandwidth
                      )*ia_oversub_factor::numeric)
                    then 'Yes'
                    else 'No'
          end as "district_able_to_meet_2014_goal_given_current_circuits_incl_oversubscription",
          
          
          
          
          ia_service_providers.ia_service_providers,
          ia_bandwidth_by_service_provider,
          "ia_lines_by_service_provider",
          "ia_mrc_by_service_provider",
          "ia_nrc_by_service_provider",
          "ia_contract_end_date_by_service_provider",
          "wan_service_providers",
          "wan_lines_by_service_provider",
          "wan_mrc_by_service_provider",
          "wan_nrc_by_service_provider",
          "wan_contract_end_date_by_service_provider"

  from ca_line_items
  /*
  left join district_contacted
  on district_line_items.esh_id=district_contacted.district_esh_id
  */
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
  on ca_line_items.district_esh_id=ia_service_providers.district_esh_id
  
  left join lateral (
  select wan_sp.district_esh_id,
  array_to_string(array_agg(wan_sp.service_provider_name), ',') as "wan_service_providers",
  array_to_string(array_agg(wan_sp.wan_lines_sp), ',') as "wan_lines_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_mrc_sp), ',') as "wan_mrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_nrc_sp), ',') as "wan_nrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_contract_end_date_sp), ',') as "wan_contract_end_date_by_service_provider"
  
  from wan_sp
  
  GROUP BY wan_sp.district_esh_id) wan_service_providers
  on ca_line_items.district_esh_id=wan_service_providers.district_esh_id
),

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
select e.*

from esh_id_mappings e

where e.entity_id in (
select entity_id
from charter_agencies)) f

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

select ag121a.nces_cd,
criteria.district_esh_id as "esh_id", 
criteria.name, 
criteria.state as "postal_cd",
criteria.city,
criteria.num_schools as "num_all_schools",
criteria.num_schools as "num_charter_schools",
criteria.num_students as "num_students_all_schools",
ca_providers.applicants,

case when total_lines=0 OR total_lines is null then 'Yes'
          else 'No' end as "Zero E-rated services",
          
          case when total_lines>fiber_lines then 'Yes'
          else 'No' end as "Receives non-fiber circuit",
          
          case when (total_wan_lines=0 OR total_wan_lines is null) and num_schools>1 then 'Yes'
          else 'No' end as "No WAN information",
--criteria."locale",

case when lowfiber_ia_circuit_count>0
and (criteria.total_ia_bandwidth::numeric*1000.0/num_students::numeric)<1000
then 'Yes' else 'No' end as "low_bandwidth_fiber_IA",

case when lowfiber_wan_circuit_count>0 and lowfiber_wan_circuit_count=fiber_wan_lines
then 'Yes' else 'No' end as "low_bandwidth_fiber_WAN",

criteria.clean_status,
criteria.how_cleaned,
case when ia_technology is null then 'unknown' else ia_technology end as "ia_technology",
case when wan_technology is null then 'unknown' else wan_technology end as "wan_technology",
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

from ag121a

left join criteria
on ag121a.nces_cd=criteria.nces_cd

left join ca_providers
on criteria.district_esh_id=ca_providers.district_esh_id
/*
left join demographics_updated
on districts.nces_cd=demographics_updated.district_nces
*/
where
(total_lines=0 
OR
total_lines is null
OR
total_lines>fiber_lines
OR
((total_wan_lines=0 OR total_wan_lines is null) and num_schools>1)
OR
(lowfiber_ia_circuit_count>0
and (criteria.total_ia_bandwidth::numeric*1000.0/num_students::numeric)<1000)
OR
(lowfiber_wan_circuit_count>0 and lowfiber_wan_circuit_count=fiber_wan_lines))
and ag121a."TYPE"=7 and ag121a."MSTATE" not in ('PR','AS','GU','VI')

ORDER BY criteria.state, criteria.district_esh_id





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


