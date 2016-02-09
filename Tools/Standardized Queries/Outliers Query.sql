/*
Author: Greg Kurzhals
Created On Date: 02/08/16
Last Modified Date: 02/09/16
Name of QAing Analyst(s): Justine Schott
Purpose: Identifies districts in clean sample that meet one of six sets of parameters that have been selected 
as indicators of data quality issues/non-representative data:
1) district receives shared IA and does not receive upstream,
2) line items w/zero allocations to district entities,
3) district does not receive every broadband line item for which it applied,
4) district receives at least one "new" USAC-created line items,
5) district receives multiple IA circuits but zero WAN circuits,
6) district is meeting both the $3/mbps per month IA affordability target and the 1 mbps/student 2018 
IA connectivity goal.
Methodology: Using the Services Received sub-queries as a foundation, this query uses a series of sub-queries
designed to isolate districts whose received services fall into one of the identified categories.  In most cases,
all line items are eliminated except for district-dedicated line items where "exclude"=false, with exceptions
for outlier categories that require a determination of whether a district receives consortium_shared services
(see sub-query "district_missing_li".  


Aggregating by state yields the number of districts in the clean sample that are unable to meet each connectivity target.

Notes: Sub-queries "district_lookup" to "af" are taken from existing "Services Received" query
(https://modeanalytics.com/educationsuperhighway/reports/7fe09fee682e) 
*/



with district_lookup as (
       select esh_id, district_esh_id, postal_cd
        from schools
        union
        select esh_id, esh_id as district_esh_id, postal_cd
        from districts
),

--Adds district_esh_id to all entries in allocations table
ad as (
        select district_esh_id, a.*
        from allocations a
        join district_lookup dl
        on dl.esh_id = a.recipient_id
),

--following sub-queries taken from "Dimensioning Clean" query

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

--start of sub-query sequence from "Dimensioning Clean" query

--Groups allocations sub-query by line item and district to create a distinct row for each line item-district pairing
ae as (
      select district_esh_id,
      line_item_id,
      sum(num_lines_to_allocate) as "district_num_lines_received"
      from ad
      GROUP BY district_esh_id,line_item_id
),

district_new_line_items as (
select district_esh_id,
sum(case when 'new_line_item'=any(line_items.open_flags) then 1 else 0 end) as "num_new_li"

from ae

left join line_items
on ae.line_item_id=line_items.id

GROUP BY district_esh_id),


/*Joins "line_items" table to add relevant cost, bandwidth, connection type, and purpose information; joins "districts" table
to add demographic data used in metric calculations*/

--start of sub-query "af"; for clarity, sub-query "af" contains sub-query "z", which contains "y", which contains "b" and "e"

af as (
      select ae.district_esh_id,
      x.name,
      x.postal_cd,
      ae.line_item_id,
      li.consortium_shared,

--classifies circuits as either "Shared IA", "Backbone", or "District-dedicated"
      case when li.consortium_shared=true and ia_conditions_met=true
      then 'Shared IA'
      when li.consortium_shared=true and 'backbone'=any(open_flags)
      then 'Backbone'
      else 'District-dedicated' end as "shared_service",

--limits lines received by district to the total num_lines listed in the line item, unless the line item is allocated to multiple districts
      case when li.consortium_shared=false and ae.district_num_lines_received>=li.num_lines 
      then li.num_lines::varchar
      when li.consortium_shared=true OR 'backbone'=any(open_flags)
      then 'Shared Circuit'
      else ae.district_num_lines_received::varchar end as "quantity_of_lines_received_by_district",

      li.bandwidth_in_mbps,
      li.connect_type,
      li.purpose,
      li.wan,

/*For "District-dedicated circuits", the district share of the line item cost is calculated by multiplying the line item cost by the proportion of the total num_lines allocated to 
the district (see previous comment).  For "Shared IA" and "Backbone" line items, line item cost is divided proportionally between recipient districts based on their number of 
students (e.g. num_students in district/num_students in ALL districts served by line item)*/ 

      case when li.rec_elig_cost!='No data' and li.consortium_shared=false and ae.district_num_lines_received>=li.num_lines and li.total_cost::numeric>0 and li.num_lines!=0 and li.orig_r_months_of_service is not null
      and li.orig_r_months_of_service!=0 
      then li.total_cost::numeric/li.orig_r_months_of_service 
      when li.consortium_shared=false and ae.district_num_lines_received<li.num_lines and li.num_lines!=0 and li.total_cost::numeric>0 
      and li.orig_r_months_of_service is not null and li.orig_r_months_of_service!=0 
      then (ae.district_num_lines_received/li.num_lines)*
      (li.total_cost::numeric/li.orig_r_months_of_service)
      when li.consortium_shared=true OR 'backbone'=any(li.open_flags) then (x.num_students::numeric/z.num_students_served)*(li.total_cost::numeric/li.orig_r_months_of_service)  
      else 0 end as "district_monthly_cost",

--if months of service is null or zero, we assume that the services are in use throughout the entirety of the E-rate cycle

      case when li.orig_r_months_of_service is not null and li.rec_elig_cost!='No data'
      and li.orig_r_months_of_service!=0 then li.total_cost::numeric/li.orig_r_months_of_service 
      else li.total_cost::numeric/12 end as "line_item_total_monthly_cost",

      ae.district_num_lines_received as "cat.1_allocations_to_district",
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
      array_to_string(li.open_flags,', ') as "open_flags",
      
      case when 'exclude'=any(open_flags) then true else false end as "dqs_excluded",
      
      case when x.ia_cost_per_mbps!='Insufficient data' and x.ia_cost_per_mbps!='Infinity' and x.ia_cost_per_mbps!='NaN' 
      then x.ia_cost_per_mbps::numeric/12 else null end as "monthly_ia_cost_per_mbps",

--total IA "backed out" from metrics by multiplying bandwidth per student by num_students
      
      case when x.ia_bandwidth_per_student!='Insufficient data' and x.num_students!='No data' then 
      ((x.ia_bandwidth_per_student::numeric*x.num_students::bigint)/1000)::int
      else null end as "district_total_ia_rounded_to_nearest_mbps",

      x.ia_bandwidth_per_student,
      x.num_students,
      x.num_students_and_staff,
      x.num_schools,
      x.latitude,
      x.longitude,
      x.locale,
      x.district_size,
      x.exclude_from_analysis,
      x.consortium_member

      from ae

      left join line_items li
      on ae.line_item_id=li.id

      left join districts x
      on ae.district_esh_id=x.esh_id

--this sub-query ("z") is currently being used only to obtain the number of students served by each line item, which is used in calculating district cost for shared line items

      left join lateral (

            select y.line_item_id,
            y.num_students_served

--start of "y"

            from (
/*Group by line_item_id to yield students served by each line item (note that most fields in this sub-query are unused, and have been retained in case we want to build them 
into the main query*/

                  select a.line_item_id,
                  max(f.applicant_name) as "applicant_name",
                  max(f.applicant_id) as "applicant_id",
                  max(f.applicant_postal_cd) as "applicant_postal_cd",
                  array_agg(DISTINCT b.district_esh_id::varchar) as "district_esh_id",
                  count(DISTINCT b.district_esh_id) as "num_district_recipients",
                  sum(DISTINCT c.num_students::bigint) as "num_students_served",
                  array_agg(DISTINCT c.name) as "district_name",
                  array_agg(DISTINCT e.district_ben::varchar) as "district_ben"

                  from allocations a

--first sub-query within "y"

                  left join lateral (
                        select esh_id, district_esh_id, postal_cd
                        from schools
                        union
                        select esh_id, esh_id as district_esh_id, postal_cd
                        from districts
                        union
                        select esh_id, district_esh_id, postal_cd
                        from other_locations
                        where district_esh_id is not null) b
                  on a.recipient_id=b.esh_id

                  left join districts c
                  on b.district_esh_id=c.esh_id

--second sub-query within "y"

                  left join lateral (
                        select array_agg(d.ben) as "district_ben",
                        d.entity_id
                        from esh_id_mappings d
                        GROUP BY d.entity_id) e
                        on c.esh_id=e.entity_id

                  left join line_items f
                  on a.line_item_id=f.id

                  where c.num_students!='No data'
                  GROUP BY a.line_item_id)y 
      )z
      on ae.line_item_id=z.line_item_id

      where li.broadband=true and 
      (li.consortium_shared=false OR li.ia_conditions_met=true OR 'backbone'=any(li.open_flags))  
      and x.include_in_universe_of_districts=true 
      and (case when 'exclude'=any(open_flags) then true else false end)=false
),

district_zero_circuits as (
select district_esh_id,
sum(case when quantity_of_lines_received_by_district::numeric<1 then 1 else 0 end) as "num_li_zero_lines_allocated",
sum(case when internet_conditions_met=true OR upstream_conditions_met=true  
then quantity_of_lines_received_by_district::numeric else 0 end) as "num_ia_upstream_lines",
sum(case when wan_conditions_met=true then quantity_of_lines_received_by_district::numeric else 0 end) as "num_wan_lines" 

from af

where shared_service='District-dedicated'
and exclude=false
and exclude_from_analysis=false

GROUP BY district_esh_id),

district_missing_li as (
select district_esh_id,
sum(case when shared_service='District-dedicated' and upstream_conditions_met=true
and exclude=false and quantity_of_lines_received_by_district::numeric!=0 then 1 else 0 end) as "num_upstream_li",
sum(case when shared_service='Shared IA' then 1 else 0 end) as "num_shared_ia_li",
sum(case when exclude=false then 1 else 0 end) as "num_li_received"

from af

where exclude_from_analysis=false

GROUP BY district_esh_id)

select esh_id,
name,
postal_cd,
case when dc.clean_categorization='verified' 
and dc.totally_verified=true then 'All li verified' 
when dc.clean_categorization='verified'
and dc.totally_verified=false then 'Some li verified'
else 'Not verified' end as "verification_status",
case when (dml."num_shared_ia_li">0 and dml."num_upstream_li"=0)
  then 'Yes' else 'No' end as "Shared IA w/o upstream",
case when (dzc."num_li_zero_lines_allocated">0)
  then 'Yes' else 'No' end as "Line items w/ zero allocations to district",
case when (applied_li."num_li_applied">"num_li_received")
  then 'Yes' else 'No' end as "More line items applied for than received",
case when (dnli."num_new_li">0)
  then 'Yes' else 'No' end as "New USAC line items",
case when (dzc."num_ia_upstream_lines">1 and dzc."num_wan_lines"=0)
  then 'Yes' else 'No' end as "DIA - no WAN",
case when (ia_bandwidth_per_student::numeric>=1000
    and ia_bandwidth_per_student!='Insufficient data'
    and ia_cost_per_mbps::numeric/12<=3
    and ia_cost_per_mbps!='Insufficient data')
  then 'Yes' else 'No' end as "Meeting afford target and 2018 IA goal",

case when ia_cost_per_mbps!='Insufficient data' then ia_cost_per_mbps::numeric/12
else null end as "monthly_ia_cost/mbps",
case when ia_bandwidth_per_student!='Insufficient data' 
then ia_bandwidth_per_student else null end as "ia_bandwidth_per_student",
locale,
district_size,
num_schools,
num_students

from districts

left join district_zero_circuits dzc
on districts.esh_id=dzc.district_esh_id

left join district_missing_li dml
on districts.esh_id=dml.district_esh_id

left join district_new_line_items dnli
on districts.esh_id=dnli.district_esh_id

left join district_contacted dc
on districts.esh_id=dc.district_esh_id

left join lateral (
select applicant_id,
count(*) as "num_li_applied"

from line_items

where broadband=true 

--excludes dirty, DQS-excluded, and consortium_shared line items
and exclude=false

GROUP BY applicant_id) applied_li
on districts.esh_id=applied_li.applicant_id

where include_in_universe_of_districts=true
and exclude_from_analysis=false
--and postal_cd not in ('OR','IL','NH','NM','MN','MI','TX')
and ia_bandwidth_per_student!='Insufficient data'
and ia_cost_per_mbps!='Insufficient data' 
and
  (
    (ia_bandwidth_per_student::numeric>=1000
    and ia_cost_per_mbps::numeric/12<=3)
    
    OR
    
    (dzc."num_li_zero_lines_allocated">0)
    
    OR 
    
    (dml."num_shared_ia_li">0 and dml."num_upstream_li"=0)
    
    OR 
    
    (dnli."num_new_li">0)
    
    OR 
    
    (dzc."num_ia_upstream_lines">1 and dzc."num_wan_lines"=0)
    
    OR 
    
    (applied_li."num_li_applied">"num_li_received")
)
    
      
ORDER BY ia_cost_per_mbps::numeric/12, ia_bandwidth_per_student::numeric DESC
