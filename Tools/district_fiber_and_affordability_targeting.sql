/*
Author: Justine Schott
Created On Date: 6/1/2016
Last Modified Date: 6/3/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: To classify districts in our universe to the district team's fiber and affordability prioritizations:
https://docs.google.com/presentation/d/1_Qddumhi2lnYRXzL5QYHYgqFLqA4ZeVUMPP4EczL0f4/edit#slide=id.p4
Methodology: Use services received by districts, charter and BIE districts. Using 2012-2013 NCES data, as well
as 2015 USAC data.
Note: original query located here: https://modeanalytics.com/educationsuperhighway/reports/f3981b94a2ff
*/

--district_lookup: to attach the district id to all school and district recipients
with district_lookup as (
       select esh_id, district_esh_id, postal_cd
        from schools
        where (postal_cd = '{{state}}' or 'All' = '{{state}}')
        union
        select esh_id, esh_id as district_esh_id, postal_cd
        from districts
        where (postal_cd = '{{state}}' or 'All' = '{{state}}')
),
--lines_to_district_by_line_item: to aggregate counts of line items by district recipients
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
--charter_and_bie_agencies: to get identification information for charter and BIE districts
--since they are not on the districts akira table
charter_and_bie_agencies as (
select distinct ag121a.nces_cd,
eim.entity_id,
  ag121a."NAME",
  ag121a."LSTATE",
  ag121a."LCITY",
  ag121a."TYPE"

from ag121a

left join entity_nces_codes eim
on rpad(ag121a.nces_cd,12,'0')=eim.nces_code

where ("TYPE"=7 or "FIPST" = '59') 
and "LSTATE" not in ('PR','AS','GU','VI')),

--dl_ca_1: create district_lookup for charters and BIEs. since they are not on the districts table,
--they may be categorized as consortia and their schools may be categorized as other_locations
dl_ca_1 as (
select esh_id, district_esh_id, postal_cd
        from schools
        where (postal_cd = '{{state}}' or 'All' = '{{state}}')
        union
        select esh_id, district_esh_id, postal_cd
        from other_locations
        where (postal_cd = '{{state}}' or 'All' = '{{state}}')
        union 
        select esh_id, esh_id as district_esh_id, postal_cd
        from consortia
        where (postal_cd = '{{state}}' or 'All' = '{{state}}')),
        
--dl_ca_2: limit dl_ca_1 by those districts in the charter_and_bie_agencies table
dl_ca_2 as (
select dl_ca_1.*
from dl_ca_1
join charter_and_bie_agencies
on dl_ca_1.district_esh_id = charter_and_bie_agencies.entity_id),

--ca_ldli: to aggregate counts of line items by charter and BIE district recipients
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

--combo_ldli: to combine counts of line items by districts for first, districts that are not ID'd as charters, since
--we only want to include schools/districts for those district types, and then for charters and BIEs (already limited)
combo_ldli as (
select district_esh_id,
      line_item_id,
      allocation_lines
        
  from lines_to_district_by_line_item
  where district_esh_id not in (
        select distinct district_esh_id
        from ca_ldli
  )

UNION

select district_esh_id,
      line_item_id,
      allocation_lines
        
  from ca_ldli
),

--ia_sp: aggregating metrics of internet or upstream direct to district services received by distinct 
--district and service provider
ia_sp as (
select ldli.district_esh_id,
li.service_provider_name,
sum(ldli.allocation_lines*li.bandwidth_in_mbps) as "ia_bandwidth_sp",
sum(ldli.allocation_lines) as "ia_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "ia_mrc_sp",
sum(one_time_eligible_cost::numeric) as "ia_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "ia_contract_end_date_sp"

from combo_ldli ldli

join line_items li
  on ldli.line_item_id = li.id
  
where (internet_conditions_met=true OR upstream_conditions_met=true)
and broadband = true
      and consortium_shared=false
      and (not('video_conferencing'=any(open_flags)) or open_flags is null)
      and (not('exclude'=any(open_flags)) or open_flags is null)
      and (not('backbone'=any(open_flags)) or open_flags is null)
  
GROUP BY ldli.district_esh_id,
li.service_provider_name),

--wan_sp: aggregating metrics of wan services direct to district services received by distinct 
--district and service provider
wan_sp as (
select ldli.district_esh_id,
li.service_provider_name,
sum(ldli.allocation_lines) as "wan_lines_sp",
sum(case when rec_elig_cost!='No data' then rec_elig_cost::numeric else 0 end) as "wan_mrc_sp",
sum(one_time_eligible_cost::numeric) as "wan_nrc_sp",
array_to_string(array_agg(LEFT(contract_end_date,9)), ',') as "wan_contract_end_date_sp"

from combo_ldli ldli

join line_items li
  on ldli.line_item_id = li.id
  
where wan_conditions_met=true
and broadband = true
      and consortium_shared=false
      and (not('video_conferencing'=any(open_flags)) or open_flags is null)
      and (not('exclude'=any(open_flags)) or open_flags is null)
      and (not('backbone'=any(open_flags)) or open_flags is null)

GROUP BY ldli.district_esh_id,
li.service_provider_name),

--district_line_items: aggregating metrics of all services direct to district services received by distinct district
district_line_items as (
  select  ldli.district_esh_id as esh_id,       
          sum(case when ldli.allocation_lines is not null
          then ldli.allocation_lines else 0 end) as total_lines,
          sum(case when ldli.allocation_lines is not null
          and isp_conditions_met = true
          then ldli.allocation_lines else 0 end) as isp_lines,
          sum(case
              when li.connect_category = 'Fiber'
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_lines,
          sum(case
              when li.connect_category = 'Fiber'
              and number_of_dirty_line_item_flags = 0
                then ldli.allocation_lines
                else 0
            end
          ) as clean_fiber_lines,
          sum(case when (internet_conditions_met=true OR upstream_conditions_met=true)
          then ldli.allocation_lines else 0 end) as total_ia_lines,
          sum(case
              when li.connect_category = 'Fiber' and (internet_conditions_met = true or upstream_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_ia_lines,
          sum(case
              when li.connect_category = 'Fiber' and (wan_conditions_met = true)
                then ldli.allocation_lines
                else 0
            end
          ) as fiber_wan_lines,
          sum(case when wan_conditions_met=true
          then ldli.allocation_lines else 0 end) as total_wan_lines,
          array_agg(distinct case when (internet_conditions_met=true OR upstream_conditions_met=true)
          then connect_category
          else null end) as "ia_technology",
          array_agg(distinct case when wan_conditions_met=true then connect_category
          else null end) as "wan_technology",
          sum(case
              when li.connect_category = 'Fiber' 
             and (internet_conditions_met=true OR upstream_conditions_met=true)
              and li.bandwidth_in_mbps < 100
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_ia_circuit_count,
          sum(case
              when li.connect_category = 'Fiber' and wan_conditions_met=true
              and li.bandwidth_in_mbps < 100
                then ldli.allocation_lines
                else 0
            end
          ) as lowfiber_wan_circuit_count,
          sum(case
              when li.isp_conditions_met = true and exclude = true
                then ldli.allocation_lines
                else 0
            end
          ) as dirty_isp,
          sum(case
              when 'product_bandwidth' = any(li.open_flags) or 'unknown_conn_type' = any(li.open_flags)
                then ldli.allocation_lines
                else 0
            end
          ) as dirty_conn_type,
          array_to_string(array_agg(distinct li.applicant_name),',') as "applicants",
          min(to_timestamp(contract_end_date, 'MM/DD/YYYY HH:MI:SS AM')) as soonest_contract_end_date

  from combo_ldli ldli
  join line_items li
  on ldli.line_item_id = li.id

  where broadband = true
      and consortium_shared=false
      and (not('video_conferencing'=any(open_flags)) or open_flags is null)
      and (not('exclude'=any(open_flags)) or open_flags is null)
      and (not('backbone'=any(open_flags)) or open_flags is null)

  group by  ldli.district_esh_id
          
),

--district_ia_prices: service and cost information of clean services received for determining if there is
--more bw available at a similar price 
district_ia_prices as (
select  district_esh_id,
        postal_cd,
        bandwidth_in_mbps,
        internet_conditions_met,
        upstream_conditions_met,
        case
          when connect_type = 'Cable Modem'
            then 'Cable'
          when connect_category = 'Cable / DSL'
            then 'Copper'
          when connect_type = 'Dark Fiber Service'
            then 'Dark Fiber'
          else
            connect_category
        end as connect_category,
        total_cost::numeric/num_lines::numeric as cost_per_circuit
        
from combo_ldli ldli
join line_items li
on ldli.line_item_id = li.id
where exclude = false
and (internet_conditions_met = true or upstream_conditions_met = true)
and not (internet_conditions_met = true and upstream_conditions_met = true)
and total_cost::numeric > 0
),

--district_ia_prices_pct: calculating by service received, the percent of other services in the state that are within
--20% of the cost of that service for more bandwidth than that service 
district_ia_prices_pct as (
  select  district_esh_id,
          postal_cd,
          concat(connect_category,' ', bandwidth_in_mbps, ' mbps', 
                      case 
                        when internet_conditions_met = true then ' internet'
                        when upstream_conditions_met = true then ' upstream'
                      end--, ' from ', service_provider_name
                      ) as service_type,
          connect_category,
          bandwidth_in_mbps,
          internet_conditions_met,
          cost_per_circuit,
          case
            when ( select count(*)
                    from district_ia_prices as fiap_all
                    where fiap_all.internet_conditions_met = fiap.internet_conditions_met
                    and fiap_all.postal_cd = fiap.postal_cd
                    and fiap_all.connect_category = fiap.connect_category
                    and fiap_all.cost_per_circuit<=fiap.cost_per_circuit*1.2
                    and fiap_all.cost_per_circuit>=fiap.cost_per_circuit*.8 ) = 0
                then -1
            else
              (   select count(*)
                  from district_ia_prices as fiap_all
                  where fiap_all.internet_conditions_met = fiap.internet_conditions_met
                  and fiap_all.postal_cd = fiap.postal_cd
                  and fiap_all.connect_category = fiap.connect_category
                  and fiap_all.cost_per_circuit<=fiap.cost_per_circuit*1.2
                  and fiap_all.cost_per_circuit>=fiap.cost_per_circuit*.8
                  and fiap_all.bandwidth_in_mbps > fiap.bandwidth_in_mbps
              )/( select count(*)
                  from district_ia_prices as fiap_all
                  where fiap_all.internet_conditions_met = fiap.internet_conditions_met
                  and fiap_all.postal_cd = fiap.postal_cd
                  and fiap_all.connect_category = fiap.connect_category
                  and fiap_all.cost_per_circuit<=fiap.cost_per_circuit*1.2
                  and fiap_all.cost_per_circuit>=fiap.cost_per_circuit*.8
              )::numeric 
          end as pct_dists_same_cost_more_bw

  from district_ia_prices fiap
),

--district_ia_prices_pct_rank: calculating by service received, the rank order of the percent of other services in the 
--state that are within 20% of the cost of that service for more bandwidth than that service, so that the highest percentage
--can be picked for determining if a similar costing service for more BW exists
district_ia_prices_pct_rank as (
  select  *,
          row_number() over (partition by district_esh_id order by pct_dists_same_cost_more_bw desc) as rank_order
  from district_ia_prices_pct
),

--revised_demographics: need to include charter schools and students for traditional districts since the districts table
--doesn't include them. excluding VT and MT since there is a smush in districts that makes it difficult to get counts from 
--sc121a by district.
revised_demographics as (
  select case 
      when "FIPST"<10 
        then concat('0',LEFT("NCESSCH",6)) 
      else 
        LEFT("NCESSCH",7) 
      end as "district_nces",
      count(*) as "num_all_schools",
      sum(case 
          when "CHARTR"='1' 
            then 1 
          else 0 
        end) as "num_charter_schools",
      sum(case
          when "MEMBER"::numeric<0
            then 0
          when "PK"::numeric<0
            then "MEMBER"::numeric
          else "MEMBER"::numeric-"PK"::numeric
        end) as "num_students_all_schools"

  from sc121a

  where "LSTATE"!='VT'
  and "LSTATE" != 'MT'
  and "GSHI" != 'PK'

  GROUP BY case 
      when "FIPST"<10 
        then concat('0',LEFT("NCESSCH",6)) 
      else 
        LEFT("NCESSCH",7) 
      end
),

--revised_demographics_VT: need to include charter schools and students for traditional districts since the districts table
--doesn't include them. VT is separate because the smush was done by UNION code.
revised_demographics_VT as (
  select  ag121a."LEAID",
      ag121a."UNION",
      su."num_all_schools",
      su."num_charter_schools",
      su."num_students_all_schools"

  from ag121a

  left join lateral (
    select  "UNION",
        count(*) as "num_all_schools",
        sum(case when "CHARTR"='1' then 1 else 0 end) as "num_charter_schools",
        sum(case
          when "MEMBER"::numeric<0
            then 0
          when "PK"::numeric<0
            then "MEMBER"::numeric
          else "MEMBER"::numeric-"PK"::numeric
        end) as "num_students_all_schools"

    from sc121a

    where "LSTATE"='VT'
    and "GSHI" != 'PK'

    GROUP BY "UNION") su
  on ag121a."UNION"=su."UNION"

  where "LSTATE"='VT' and "TYPE"=3),

--revised_demographics_MT: need to include charter schools and students for traditional districts since the districts table
--doesn't include them. MT is separate because the smush was done manually, but it is confirmed that there are no charters
--in MT.
revised_demographics_MT as (
  select  nces_cd,
      num_schools::numeric,
      num_students::numeric

  from districts
  where postal_cd='MT' 
  and include_in_universe_of_districts=true),

--demographics_updated: need to include charter schools and students for traditional districts; all previous tables merged
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
from revised_demographics_VT
union
select revised_demographics_MT.nces_cd as "district_nces",
revised_demographics_MT.num_schools as "num_all_schools",
0 as "num_charter_schools",
revised_demographics_MT.num_students as "num_students_all_schools"
from revised_demographics_MT
),

--ca_demo: demographics for charter and BIE entities since they are not on the districts table
ca_demo as (
  select charter_and_bie_agencies.entity_id,
  charter_and_bie_agencies.nces_cd,
  ag121a."NAME",
  ag121a."LSTATE",
  ag121a."LCITY",
  su.num_all_schools,
  su.num_all_students,
  ag121a."TYPE"
  from charter_and_bie_agencies
  left join ag121a
  on charter_and_bie_agencies.nces_cd=ag121a.nces_cd
  left join lateral (
    select  nces_cd,
        count(*) as "num_all_schools",
        sum(case
          when "MEMBER"::numeric<0
            then 0
          when "PK"::numeric<0
            then "MEMBER"::numeric
          else "MEMBER"::numeric-"PK"::numeric
        end) as "num_all_students"

    from sc121a

    where "GSHI" != 'PK'

    GROUP BY nces_cd) su
  on charter_and_bie_agencies.nces_cd=su.nces_cd

),

--districts_charters: new districts table with charters and BIEs and revised demographics to include charter school and students
districts_charters as (
          select  esh_id, 
                  exclude_from_analysis::varchar, 
                  name, 
                  postal_cd, 
                  city,
                  district_nces,
                  num_campuses+num_charter_schools as num_campuses,
                  num_all_schools,
                  num_charter_schools,
                  num_students_all_schools,
                  ia_bandwidth_per_student
          from districts
          left join demographics_updated
          on districts.nces_cd=demographics_updated.district_nces
          where include_in_universe_of_districts = true
          and (postal_cd = '{{state}}' or 'All' = '{{state}}')
          UNION
          select  entity_id as esh_id, 
                  case
                    when "TYPE" = '7'
                      then 'unknown - charter' 
                    else
                      'unknown - bie'
                  end as exclude_from_analysis, 
                  "NAME" as name, 
                  "LSTATE" as postal_cd, 
                  "LCITY" as city,
                  nces_cd as district_nces,
                  num_all_schools as num_campuses,
                  num_all_schools as num_all_schools,
                  num_all_schools as num_charter_schools,
                  num_all_students as num_students_all_schools,
                  'Insufficient data' as ia_bandwidth_per_student
          from ca_demo
          where ("LSTATE" = '{{state}}' or 'All' = '{{state}}')
),

--clean categorization sub-queries
--ad: table of traditional and charter districts and the broadband services it received
ad as (
        select district_esh_id, line_item_id
        from combo_ldli ldli
        join line_items li
        on ldli.line_item_id = li.id
        where broadband = true
      ),

--version_order: assign row_number by version_id because we want to know the most recent contacted
--status of the line item, also excluding notes that were done "auto-magically"
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

--most_recent: limiting contacted and assumed status of a line item by most recent, for all district recipients
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
   
--district_counts: aggregating all services received's most recent status             
district_counts as (
                    select district_esh_id,
                          count(case when contacted = 'true' then 1 end) as true_count,
                          count(case when contacted = 'false' then 1 end) as false_count,
                          count(case when contacted is null and assumed_flags = true then 1 end) as null_assumed_count,
                          count(case when contacted is null and assumed_flags = false then 1 end) as null_untouched_count
                    
                    from most_recent
                    
                    group by district_esh_id
),

--district_contacted: contacted status as defined here:   
--https://educationsuperhighway.atlassian.net/wiki/display/EDS/Dimensioning+Clean        
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

--criteria: combining demographic info, services received info, and verification status
criteria as (

  select  dc.esh_id,
          case 
            when dc.exclude_from_analysis = 'unknown - charter'
            then 'Charter'
            when dc.exclude_from_analysis = 'unknown - bie'
            then 'Bureau of Indian Education'
            else 'Public'
          end as trad_or_chart_or_bie,
          dc.name,
          dc.postal_cd,
          dc.city,
          dc.district_nces,
          dc.num_campuses,
          dc.num_all_schools,
          dc.num_charter_schools,
          dc.num_students_all_schools,
          dc.ia_bandwidth_per_student,
          case 
            when exclude_from_analysis ilike 'false' 
            then 'clean' 
            when exclude_from_analysis ilike 'true'
            then 'dirty'
            else exclude_from_analysis 
          end as "clean_status",
          case 
            when exclude_from_analysis ilike 'false' 
            then clean_categorization
            when exclude_from_analysis ilike 'true' 
            then 'dirty' 
            else exclude_from_analysis
          end as "how_cleaned",
          array_to_string(ia_technology, ', ') as "ia_technology",
          array_to_string(wan_technology, ', ') as "wan_technology",
          total_lines,
          isp_lines,
          fiber_lines,
          clean_fiber_lines,
          total_ia_lines,
          fiber_ia_lines,
          total_wan_lines,
          fiber_wan_lines,
          lowfiber_ia_circuit_count,
          lowfiber_wan_circuit_count,
          dirty_isp,
          dirty_conn_type,
          soonest_contract_end_date,
          ia_service_providers.*,
          wan_service_providers.*,
          district_line_items.applicants,
          district_ia_prices_pct_max.pct_dists_same_cost_more_bw, 
          "NAME", 
          "PHONE", 
          "MSTREE", 
          "MCITY", 
          "MSTATE", 
          "MZIP", 
          "LSTREE", 
          "LCITY", 
          "LSTATE", 
          "LZIP"

  from districts_charters dc
  left join ag121a
  on dc.district_nces = ag121a.nces_cd

  left join district_line_items
  on dc.esh_id=district_line_items.esh_id
  
  left join district_contacted
  on dc.esh_id=district_contacted.district_esh_id
  
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
  on dc.esh_id=ia_service_providers.district_esh_id
  
  left join lateral (
  select wan_sp.district_esh_id,
  array_to_string(array_agg(wan_sp.service_provider_name), ',') as "wan_service_providers",
  array_to_string(array_agg(wan_sp.wan_lines_sp), ',') as "wan_lines_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_mrc_sp), ',') as "wan_mrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_nrc_sp), ',') as "wan_nrc_by_service_provider",
  array_to_string(array_agg(wan_sp.wan_contract_end_date_sp), ',') as "wan_contract_end_date_by_service_provider"
  
  from wan_sp
  
  GROUP BY wan_sp.district_esh_id) wan_service_providers
  on dc.esh_id=wan_service_providers.district_esh_id

  left join (
    select *
    from district_ia_prices_pct_rank
    where rank_order = 1) district_ia_prices_pct_max
  on dc.esh_id = district_ia_prices_pct_max.district_esh_id

  where case
        when dc.exclude_from_analysis = 'unknown - charter'
          then num_all_schools > 0
        else
          true
      end

  ),
  
--before_prior: creating fields which will help define the fiber priorities, as defined here:
--https://docs.google.com/presentation/d/1_Qddumhi2lnYRXzL5QYHYgqFLqA4ZeVUMPP4EczL0f4/edit#slide=id.p4
--renaming fields to make import into salesforce more streamlined
before_prior as (
  select  criteria.esh_id as esh_id__c,
          criteria.trad_or_chart_or_bie as type, 
          initcap(criteria.name) as account_name,
          criteria.postal_cd as billingstatecode,
          null as billingstate,
          criteria.city,
          criteria.district_nces as ncesid__c,
          criteria.num_campuses,
          criteria.num_all_schools,
          criteria.num_charter_schools,
          criteria.num_students_all_schools,
          case when total_lines-isp_lines>fiber_lines then 'Yes'
          else 'No' end as "Receives non-fiber circuit",
          case when dirty_isp + dirty_conn_type > 0 then 'Yes'
          else 'No' end as "Receives circuit with unknown connection",
          case when ((total_wan_lines=0 OR total_wan_lines is null) and num_all_schools>1) then 'Yes'
          else 'No' end as "No WAN information",
          case when total_lines=0 OR total_lines is null
          then 'Yes' else 'No' end as "Zero E-rated services",
          case when lowfiber_ia_circuit_count>0 and ia_bandwidth_per_student!='Insufficient data' 
          and ia_bandwidth_per_student::numeric<1000
          then 'Yes' else 'No' end as "low_bandwidth_fiber_IA",
          case when lowfiber_wan_circuit_count>0 and lowfiber_wan_circuit_count=fiber_wan_lines
          then 'Yes' else 'No' end as "low_bandwidth_fiber_WAN",
          case when clean_fiber_lines<num_campuses
          then 'Yes' else 'No' end as more_campuses_than_clean_fiber,
          criteria.clean_status,
          how_cleaned,
          case when ia_technology is null then 'Unknown' else ia_technology end as "ia_technology",
          case when wan_technology is null then 'Unknown' else wan_technology end as "wan_technology",
          total_lines-isp_lines as total_lines,
          ia_service_providers,
          wan_service_providers,
          case
            when ia_bandwidth_per_student = 'Insufficient data'
              then 'Unknown for 2015'
            when ia_bandwidth_per_student::numeric >= 100
              then 'Meeting'
            else 'Not meeting'
          end as goal_status,
          case
            when soonest_contract_end_date is null
              then 'Unknown for 2015'
            when soonest_contract_end_date <= to_timestamp('06/30/2017', 'MM/DD/YYYY')
              then 'true'
            else 'false'
          end as contract_expiration,
          case
            when pct_dists_same_cost_more_bw = -1 or pct_dists_same_cost_more_bw is null
              then 'Unknown for 2015'
            when pct_dists_same_cost_more_bw = 0
              then 'false'
            else 'true'
          end as similar_priced_service_for_more_bw, 
          "NAME", 
          "PHONE", 
          "MSTREE", 
          "MCITY", 
          "MSTATE", 
          "MZIP", 
          "LSTREE", 
          "LCITY", 
          "LSTATE", 
          "LZIP"


  from criteria
),

--before_status: creating fiber prioritization fields, which will help define the fiber status
before_status as (
  select *,
    case
      when "Receives non-fiber circuit"='Yes' and how_cleaned='verified'
          then 'Priority 1'
      when "Receives non-fiber circuit"='Yes' and clean_status='clean'and NOT(how_cleaned='verified')
          then 'Priority 3'
      when "Receives non-fiber circuit"='Yes' and more_campuses_than_clean_fiber = 'Yes' and NOT(clean_status='clean')
          then 'Priority 5'
      when ("Receives non-fiber circuit"='No' and "Receives circuit with unknown connection" = 'Yes' and NOT(clean_status='clean'))
      or ("No WAN information"='Yes' and num_campuses>3 and total_lines<num_campuses)
          then 'Priority 6'
      when "Zero E-rated services"='Yes'
      or NOT(clean_status='clean')  
          then 'Priority 7'
--P10 has been updated to be the prioritization for all remaining clean line items         
      else
          'Priority 10'
    end as priority_status__c_f,
    case
      when goal_status = 'Meeting'
        then null
      when contract_expiration = 'true' and similar_priced_service_for_more_bw = 'true' and goal_status = 'Not meeting'
        then 'A1'
      when contract_expiration = 'true' and similar_priced_service_for_more_bw = 'true' and goal_status = 'Unknown for 2015'
        then 'A2'
      when contract_expiration = 'true' and similar_priced_service_for_more_bw != 'true' and goal_status = 'Not meeting'
        then 'A3'
      when contract_expiration = 'true' and similar_priced_service_for_more_bw != 'true' and goal_status = 'Unknown for 2015'
        then 'A4'
      when contract_expiration != 'true' and similar_priced_service_for_more_bw = 'true' and goal_status = 'Not meeting'
        then 'A5'
      when contract_expiration != 'true' and similar_priced_service_for_more_bw = 'true' and goal_status = 'Unknown for 2015'
        then 'A6'
      when contract_expiration != 'true' and similar_priced_service_for_more_bw != 'true' and goal_status = 'Not meeting'
        then 'A7'
      when contract_expiration != 'true' and similar_priced_service_for_more_bw != 'true' and goal_status = 'Unknown for 2015'
        then 'A8'
    end as priority_status__c_a,
    case
      when contract_expiration = 'true'
        then true
      else false
    end as contract_expiring__c  
  from before_prior
)

--creating fiber status and external communications lines, and more fields to streamline salesforce import
select  esh_id__c,
        type,
        account_name,
        billingstatecode,
        billingstate,
        city,
        ncesid__c,
        num_campuses,
        num_all_schools,
        num_charter_schools,
        num_students_all_schools,
        ia_technology,
        wan_technology,
        ia_service_providers,
        wan_service_providers,
        priority_status__c_f,
        case
          when right(priority_status__c_f,1) in ('1','3')
            then 'Target'
          when right(priority_status__c_f,1) in ('5','6','7') or right(priority_status__c_f,2) = '10'
            then 'Potential Target'
          else null
        end as status__c_f,
        case
          when right(priority_status__c_f,1) in ('1','3')
            then 'We know they need fiber'
          when right(priority_status__c_f,1) in ('5','6')
            then 'We think they need fiber and need to verify'
          when right(priority_status__c_f,1) ='7'
            then 'We dont have data and need to verify'
          when right(priority_status__c_f,2) ='10'
            then 'They have fiber and do not need support'
          else null
        end as fiber_external_communications,
        priority_status__c_a,
        case
          when right(priority_status__c_a,1) in ('1','2','3')
            then 'Target'
          when right(priority_status__c_a,1) in ('4','5','6','7','8')
            then 'Potential Target'
          else null
        end as status__c_a,
        case
          when right(priority_status__c_a,1) in ('1','3')
            then 'Contract expiring'
          when right(priority_status__c_a,1) in ('2','4')
            then 'Contract expiring but need to verify'
          when right(priority_status__c_a,1) in ('5','6','7','8')
            then 'Contract not expiring but need to verify'
          else null
        end as afford_external_communications,
        contract_expiring__c,
        case
          when priority_status__c_a is null
            then null
          when contract_expiring__c = true
          or (contract_expiring__c = false
              and clean_status = 'clean'
              and priority_status__c_f is not null
            )
            then '012E0000000NJE4'
          else
            '012E000000066Rk' 
        end as "RecordTypeID_A",
        '012E0000000VjCc' as "RecordTypeID_F",
        case
          when priority_status__c_a is not null
            then concat('2016 Affordability ',account_name) 
        end as "Opportunity Name_A",
        concat('2016 Target Fiber ',account_name) as "Opportunity Name_F",
        '06/01/2017' as "CloseDate",
        case
          when priority_status__c_f is null
            then 'Closed Lost' 
        end as "StageName_F",
        case
          when priority_status__c_f is null
            then 'Already on Fiber' 
        end as "Reason__c",
        case
          when priority_status__c_f is null
            then 'determined already on fiber pre-import' 
        end as "Reason_explanation__c",
        case
          when priority_status__c_a is null
            then null
          when contract_expiring__c = true
          or (contract_expiring__c = false
              and clean_status = 'clean'
              and priority_status__c_f is not null
            )
            then 'Open'
          else
            'DQT Review Needed' 
        end as "StageName_A",
        null as ownerid,
        null as batch__c, 
        "NAME", 
        "PHONE", 
        "MSTREE", 
        "MCITY", 
        "MSTATE", 
        "MZIP", 
        "LSTREE", 
        "LCITY", 
        "LSTATE", 
        "LZIP"

        
from before_status

ORDER BY billingstatecode, account_name

{% form %}

state:
  type: text
  default: 'All'

{% endform %}
