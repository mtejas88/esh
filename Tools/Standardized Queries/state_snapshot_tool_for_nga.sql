/*
Author: Justine Schott
Created On Date: 12/29/2015
Last Modified Date: 08/08/2016
Name of QAing Analyst(s):  
Purpose: To display all state snapshot metrics and QA metrics, with addition of state-level broadband spending
Methodology: Each metrics grouping begins with a comment. Any table that begins with "states" is calculating metrics at the state level, then 
all "states" queries are merged in the final query. There are 3 different groups of districts that are used -- universe (ie, clean and dirty); 
clean_goal_fiber (ie, clean), and clean_afford (ie, clean and has cost information).
*/

--state profile metrics
with universe_districts as (
  select *
  from public.districts
  where include_in_universe_of_districts = true
),

states_nces as (
  select
    postal_cd,
    sum(num_students::numeric) as overall_student_count,
    sum(case
          when num_students::numeric*150 < 9200
            then 9200
          else num_students::numeric*150 
        end) as overall_budget_floor,
    sum(case when locale in ('Rural') then num_students::numeric else 0 end) as num_students_rural,
    sum(case when locale in ('Small Town') then num_students::numeric else 0 end) as num_students_town,
    sum(case when locale in ('Suburban') then num_students::numeric else 0 end) as num_students_suburban,
    sum(case when locale in ('Urban') then num_students::numeric else 0 end) as num_students_urban,
    sum(case when locale in ('Rural') then num_schools::numeric else 0 end) as num_schools_rural,
    sum(case when locale in ('Small Town') then num_schools::numeric else 0 end) as num_schools_town,
    sum(case when locale in ('Suburban') then num_schools::numeric else 0 end) as num_schools_suburban,
    sum(case when locale in ('Urban') then num_schools::numeric else 0 end) as num_schools_urban,
    sum(case when locale in ('Rural') then num_campuses else 0 end) as num_campuses_rural,
    sum(case when locale in ('Small Town') then num_campuses else 0 end) as num_campuses_town,
    sum(case when locale in ('Suburban') then num_campuses else 0 end) as num_campuses_suburban,
    sum(case when locale in ('Urban') then num_campuses else 0 end) as num_campuses_urban,
    sum(case when locale in ('Rural') then 1 else 0 end) as num_districts_rural,
    sum(case when locale in ('Small Town') then 1 else 0 end) as num_districts_town,
    sum(case when locale in ('Suburban') then 1 else 0 end) as num_districts_suburban,
    sum(case when locale in ('Urban') then 1 else 0 end) as num_districts_urban

  from universe_districts  
  group by postal_cd
),

--wifi metrics
c2_li as (
  select *
  from public.line_items
  where service_category ilike '%internal%'
),

broadband_li as (
select *
from public.line_items
where broadband=true),

c1_li as (
  select *
  from public.line_items
  where broadband=true OR service_category='VOICE SERVICES'), 

distinct_application_entities as (
  select distinct
    "Application Number",
    postal_cd,
    "Full/Part Count",
    "Cat 2 Disc Rate"

  from public.fy2015_discount_calculations dc

  where "Stud NSLP Perc" != '0' and "Cat 2 Disc Rate"::numeric >0
),

distinct_application_entities_broadband as (
select distinct
    dc."Application Number",
    postal_cd,
    "Full/Part Count",
    "Cat 1 Disc Rate"

  from public.fy2015_discount_calculations dc
  --we want to exclude applications where every FRN is voice services (and thus neither broadband nor C2) 
  left join lateral (
  select "Application Number",
  count(distinct "FRN") as "num_frns",
  sum(case when "FRN Service Type"='VOICE SERVICES'
  then 1 else 0 end) as "num_voice_services_frns"
  
  from public.fy2015_funding_request_key_informations
  
  GROUP BY "Application Number") voice_filter
  on dc."Application Number"=voice_filter."Application Number"

  where "Stud NSLP Perc" != '0' and num_voice_services_frns!=num_frns and "Cat 1 Disc Rate"::numeric >0),
  
distinct_application_entities_c1 as (
select distinct
    dc."Application Number",
    postal_cd,
    "Full/Part Count",
    "Cat 1 Disc Rate"

  from public.fy2015_discount_calculations dc

  where "Stud NSLP Perc" != '0' and "Cat 1 Disc Rate"::numeric >0),

states_application_discount_rate as (
  select
    postal_cd,
    round(sum("Full/Part Count"::numeric * "Cat 2 Disc Rate"::numeric)/sum("Full/Part Count"::numeric),0) as agg_c2_discount_rate

  from distinct_application_entities

  group by postal_cd
),

states_application_discount_rate_broadband as (
  select
    postal_cd,
    round(sum("Full/Part Count"::numeric * "Cat 1 Disc Rate"::numeric)/sum("Full/Part Count"::numeric),0) as agg_broadband_discount_rate

  from distinct_application_entities_broadband
  
  where "Cat 1 Disc Rate"::numeric >0

  group by postal_cd
),

states_application_discount_rate_c1 as (
select
    postal_cd,
    round(sum("Full/Part Count"::numeric * "Cat 1 Disc Rate"::numeric)/sum("Full/Part Count"::numeric),0) as agg_c1_discount_rate

  from distinct_application_entities_c1
  
  where "Cat 1 Disc Rate"::numeric >0

  group by postal_cd),

ad as (
  select
    a.line_item_id,
    dl.district_esh_id,
    a.cat_2_cost
  from public.allocations a
  left join public.district_lookup_2015 dl
  on a.recipient_id = dl.esh_id
  where exists (select 1 from c2_li where c2_li.id = a.line_item_id)
  and district_esh_id is not null
),
ali as (
  select
    line_item_id,
    sum(cat_2_cost) as cat_2_cost,
    count(distinct district_esh_id) as cat_2_district_count
  from ad
  group by line_item_id
),

ad_broadband as (
  select
    a.line_item_id,
    dl.district_esh_id
  from public.allocations a
  left join public.district_lookup_2015 dl
  on a.recipient_id = dl.esh_id
  where exists (select 1 from broadband_li where broadband_li.id = a.line_item_id)
  and district_esh_id is not null),
  
ad_c1 as (
select
    a.line_item_id,
    dl.district_esh_id
  from public.allocations a
  left join public.district_lookup_2015 dl
  on a.recipient_id = dl.esh_id
  where exists (select 1 from c1_li where c1_li.id = a.line_item_id)
  and district_esh_id is not null),

districts_c2 as (
  select *
  from universe_districts sd
  where exists (select 1 from ad where ad.district_esh_id = sd.esh_id)
),
districts_c2_cost as (
  select  d.postal_cd,
          ad.district_esh_id,
          sum((case
                when ali.cat_2_cost = 0
                  then 1/cat_2_district_count::numeric
                  else ad.cat_2_cost/ali.cat_2_cost::numeric
              end)*
              (case 
                when c2_li.total_cost is null
                  then 0
                  else c2_li.total_cost
              end)) as assumed_cat_2_cost,
          d.num_students::numeric * 150 as cat_2_budget

  from ad
  join ali
  on ad.line_item_id = ali.line_item_id
  join c2_li
  on ad.line_item_id = c2_li.id
  join districts_c2 d
  on ad.district_esh_id = d.esh_id

  group by d.postal_cd, ad.district_esh_id, d.num_students
),
districts_broadband as (
  select *
  from universe_districts sd
  where exists (select 1 from ad_broadband where ad_broadband.district_esh_id = sd.esh_id)),
  
districts_c1 as (
select *
  from universe_districts sd
  where exists (select 1 from ad_c1 where ad_c1.district_esh_id = sd.esh_id)),

states_c2_applicant as (
  select
    applicant_postal_cd as postal_cd,
    sum(total_cost) as c2_cost
  from c2_li
  group by applicant_postal_cd
),

states_broadband_applicant as (
  select
    applicant_postal_cd as postal_cd,
    sum(total_cost) as broadband_cost
  from broadband_li
  group by applicant_postal_cd
),

states_c1_applicant as (
select
    applicant_postal_cd as postal_cd,
    sum(total_cost) as c1_cost
  from c1_li
  group by applicant_postal_cd
),

states_c2_recipient as (
  select
    postal_cd,
    count(*)::numeric / (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_c2_cost.postal_cd
    )::numeric as pct_receiving_c2,
    count(case 
            when cat_2_budget <= assumed_cat_2_cost
              then 1 
          end)::numeric / (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_c2_cost.postal_cd
    )::numeric as pct_exceeding_c2_budget,
    (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_c2_cost.postal_cd
    ) as count_districts    
  from districts_c2_cost
  group by postal_cd
),

states_broadband_recipient as (
  select
    postal_cd,
    count(*)::numeric / (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_broadband.postal_cd
    )::numeric as pct_receiving_broadband,
    (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_broadband.postal_cd
    ) as count_districts    
  from districts_broadband
  group by postal_cd
),

states_c1_recipient as (
select
    postal_cd,
    count(*)::numeric / (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_c1.postal_cd
    )::numeric as pct_receiving_c1,
    (
      select count(*)
      from universe_districts sd
      where sd.postal_cd = districts_c1.postal_cd
    ) as count_districts    
  from districts_c1
  group by postal_cd
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
),

states_goals as (
  select postal_cd,
      sum(case when ia_bandwidth_per_student::numeric >= 100 then num_students::numeric else 0 end)/
        sum(num_students::numeric)::numeric as pct_students_meeting_current_goal_unadj,
      sum(case when ia_bandwidth_per_student::numeric >= 100 then 1 else 0 end)/
        sum(1)::numeric as pct_districts_meeting_current_goal_unadj,
      sum(case when ia_bandwidth_per_student::numeric >= 1000 then num_students::numeric else 0 end)/
        sum(num_students::numeric)::numeric as pct_students_meeting_2018_goal_unadj,
      sum(case when ia_bandwidth_per_student::numeric >= 1000 then 1 else 0 end)/
        sum(1)::numeric as pct_districts_meeting_2018_goal_unadj,
      sum(case when adj_ia_bandwidth_per_student >= 1000 then num_students::numeric else 0 end)/
        sum(num_students::numeric)::numeric as pct_students_meeting_2018_goal,
      sum(case when adj_ia_bandwidth_per_student >= 1000 then 1 else 0 end)/
        sum(1)::numeric as pct_districts_meeting_2018_goal,
      sum(case when adj_ia_bandwidth_per_student >= 100 then num_students::numeric else 0 end)/
        sum(num_students::numeric)::numeric as pct_students_meeting_current_goal,
      sum(case when adj_ia_bandwidth_per_student >= 100 then 1 else 0 end)/
        sum(1)::numeric as pct_districts_meeting_current_goal,
      sum(num_students::numeric)::numeric as sample_students,
      sum(num_schools::numeric)::numeric as sample_schools,
      sum(num_campuses)::numeric as sample_campuses,
      count(*) as sample_districts,
      count(case when wan_bandwidth_low = 'Insufficient data' then 1 end) as sample_districts_without_wan,
      sum(case when locale = 'Rural' then num_students::numeric end)::numeric as rural_sample_students,
      sum(case when locale = 'Small Town' then num_students::numeric end)::numeric as town_sample_students,
      sum(case when locale = 'Suburban' then num_students::numeric end)::numeric as suburban_sample_students,
      sum(case when locale = 'Urban' then num_students::numeric end)::numeric as urban_sample_students,
      sum(case when locale = 'Rural' then num_schools::numeric end)::numeric as rural_sample_schools,
      sum(case when locale = 'Small Town' then num_schools::numeric end)::numeric as town_sample_schools,
      sum(case when locale = 'Suburban' then num_schools::numeric end)::numeric as suburban_sample_schools,
      sum(case when locale = 'Urban' then num_schools::numeric end)::numeric as urban_sample_schools,
      sum(case when locale = 'Rural' then 1 end)::numeric as rural_sample_districts,
      sum(case when locale = 'Small Town' then 1 end)::numeric as town_sample_districts,
      sum(case when locale = 'Suburban' then 1 end)::numeric as suburban_sample_districts,
      sum(case when locale = 'Urban' then 1 end)::numeric as urban_sample_districts,
      sum(case when locale in ('Rural') then num_campuses else 0 end) as rural_sample_campuses,
      sum(case when locale in ('Small Town') then num_campuses else 0 end) as town_sample_campuses,
      sum(case when locale in ('Suburban') then num_campuses else 0 end) as suburban_sample_campuses,
      sum(case when locale in ('Urban') then num_campuses else 0 end) as urban_sample_campuses
  from clean_goal_fiber_districts
  group by postal_cd
),

--fiber metrics
cd as (
select dl.district_esh_id,
         c.line_item_id,
         count(distinct circuit_id) as allocation_lines
        
  from public.entity_circuits ec
  join public.circuits c
  on ec.circuit_id = c.id
  join public.district_lookup_2015 dl
  on ec.entity_id = dl.esh_id
  
  where entity_type in ('School', 'District')
  and exclude_from_reporting = false
  and district_esh_id is not null
  
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
        sum(case when li.connect_category = 'Fiber' 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as fiber_lines,
        sum(case when li.connect_type = 'Cable Modem' or li.connect_category = 'Fiber' 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as cable_equiv_lines,
        sum(case when li.connect_type != 'Cable Modem' and li.connect_category in ('Copper', 'Cable / DSL') 
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as copper_dsl_lines,
        sum(case when li.wan_conditions_met = true and exclude = false and (not('backbone'=any(open_flags)) or open_flags is null)
              then case when cd.allocation_lines < li.num_lines 
                    then cd.allocation_lines
                    else li.num_lines 
                  end
              else 0
            end) as wan_lines
            
        from clean_goal_fiber_districts cgfd
        left join cd
        on cd.district_esh_id = cgfd.esh_id
        left join public.line_items li
        on cd.line_item_id = li.id
        
        group by cgfd.esh_id, cgfd.num_students, cgfd.num_schools, cgfd.postal_cd, cgfd.locale, cgfd.num_campuses
),
cdd_calc as (
    select *,
    case
      when num_campuses < fiber_lines 
        then num_campuses 
        else fiber_lines 
    end as known_scalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 
          case 
            when num_campuses > fiber_lines 
              then num_campuses - fiber_lines 
              else 0
          end
        else 0
    end as assumed_scalable_campuses,
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
    end as known_unscalable_campuses,
    case 
      when num_schools > 5 and wan_lines = 0 
        then 0 
        else 
          case
            when num_campuses < (fiber_lines + copper_dsl_lines)
              then 0
              else num_campuses - (fiber_lines + copper_dsl_lines)
          end
    end as assumed_unscalable_campuses
  
  from cdd
),
states_fiber as (
  select postal_cd,
         1-(
             sum(known_scalable_campuses+assumed_scalable_campuses)/
              sum(num_campuses)::numeric
            ) as "STUS: % of campuses that do not have fiber connections (or an equivalent)",
         case 
          when sum(known_unscalable_campuses + assumed_unscalable_campuses) = 0 then -1
          else
            sum(case 
                  when locale in ('Small Town','Rural') 
                    then known_unscalable_campuses + assumed_unscalable_campuses 
                    else 0 
                end)/
            sum(known_unscalable_campuses + assumed_unscalable_campuses)::numeric 
         end as "OPPR: % of Rural & Small Town schools of those that do not have fiber connections",
         sum(known_scalable_campuses) as known_scalable_campuses,
         sum(assumed_scalable_campuses) as assumed_scalable_campuses,
         sum(known_unscalable_campuses) as known_unscalable_campuses,
         sum(assumed_unscalable_campuses) as assumed_unscalable_campuses
        
  from cdd_calc

  group by postal_cd
),

--afford metrics
clean_afford_districts as (
  select *,
  ia_bandwidth_per_student::numeric * case when ia_cost_per_mbps::numeric/12 <= 3 then 1
    else ( (ia_cost_per_mbps::numeric / 12) / 3 ) 
    end as hypothetical_ia_bandwidth_per_student
  from clean_goal_fiber_districts
-- exclude those without cost info for afford metrics
  where ia_cost_per_mbps not in ('Insufficient data', 'Infinity') 
),
states_afford as (
  select postal_cd,
      sum(case when ia_cost_per_mbps::numeric/12 <= 3 then 1 else 0 end)/count(*)::numeric 
        as pct_districts_meeting_ia_affordability_target,
      sum(case when ia_bandwidth_per_student::numeric >= 100 then num_students::numeric else 0 end)/
        sum(num_students::numeric)::numeric as pct_students_meeting_current_goal_unadj,
      sum(case when hypothetical_ia_bandwidth_per_student::numeric >= 100 then num_students::numeric else 0 end)/
         sum(num_students::numeric)::numeric as hypothetical_pct_students_meeting_current_goal_unadj,
      sum(ia_cost_per_mbps::numeric * ia_bandwidth_per_student::numeric * num_students::numeric / 1000) as sample_ia_cost,
      sum(ia_cost_per_mbps::numeric * ia_bandwidth_per_student::numeric * num_students::numeric / 1000) / sum(num_students::numeric) / 12 
        as sample_ia_cost_per_student_month,
      sum(ia_cost_per_mbps::numeric * ia_bandwidth_per_student::numeric * num_students::numeric / 1000) / sum(ia_bandwidth_per_student::numeric * num_students::numeric / 1000) / 12 
        as sample_ia_cost_per_mbps_month,
      sum(case when hypothetical_ia_bandwidth_per_student::numeric >= 100 then num_students::numeric else 0 end) 
        as hypothetical_students_meeting_current_goal_unadj,
      sum(case when ia_cost_per_mbps::numeric/12 > 3 and ia_bandwidth_per_student::numeric < 100
              then num_students::numeric
              else 0
           end)/sum(num_students::numeric) as pct_students_under_connectivity_and_affordability_targets,
      sum(case when ia_cost_per_mbps::numeric/12 > 3 and ia_bandwidth_per_student::numeric < 100
              then num_students::numeric
              else 0
           end) as sample_students_under_connectivity_and_affordability_targets
  from clean_afford_districts
  group by postal_cd
)

select
  sn.postal_cd,
--Broadband/Wifi metrics   
  (((sn.overall_budget_floor) - sap.c2_cost)/1000000)*(sadr.agg_c2_discount_rate/100) as "$M remaining E-Rate funds to support Wi-Fi and other internal connectivity equipment purchases",
  sr.pct_receiving_c2 as "% of districts that have requested any funding for Wi-Fi and other internal connectivity equipment this year",
--goals metric
  sg.pct_districts_meeting_current_goal_unadj,
--fiber metrics
  1- sf."STUS: % of campuses that do not have fiber connections (or an equivalent)" as "STUS: % of campuses that have fiber connections (or an equivalent)",
  sf."OPPR: % of Rural & Small Town schools of those that do not have fiber connections",
--affordability metrics
  sa.pct_districts_meeting_ia_affordability_target as "% meet the IA affordability target",
  round((sa.hypothetical_pct_students_meeting_current_goal_unadj-sa.pct_students_meeting_current_goal_unadj)*sn.overall_student_count,0) 
    as "# of additional students meeting 100 kbps per student target without oversubscription if district met IA affordability target",
--sample metrics
  sg.sample_students,
  sg.sample_schools,
  sg.sample_districts,
--state profile metrics
  sn.num_students_rural+sn.num_students_town+sn.num_students_suburban+sn.num_students_urban as pop_students,
  sn.num_schools_rural+sn.num_schools_town+sn.num_schools_suburban+sn.num_schools_urban as pop_schools,
  sn.num_districts_rural+sn.num_districts_town+sn.num_districts_suburban+sn.num_districts_urban as pop_districts

--state profile metrics
from states_nces sn
--wifi metrics
left join states_c2_recipient sr
on sn.postal_cd = sr.postal_cd

left join states_broadband_recipient sb
on sn.postal_cd=sb.postal_cd

left join states_c1_recipient sc1
on sn.postal_cd=sc1.postal_cd



left join states_c2_applicant sap
on sn.postal_cd = sap.postal_cd

left join states_broadband_applicant sba
on sn.postal_cd=sba.postal_cd

left join states_c1_applicant sc1a
on sn.postal_cd=sc1a.postal_cd


left join states_application_discount_rate sadr
on sn.postal_cd = sadr.postal_cd

left join states_application_discount_rate_broadband sadrb
on sn.postal_cd=sadrb.postal_cd

left join states_application_discount_rate_c1 sadrc1
on sn.postal_cd=sadrc1.postal_cd


--goals metrics and sample metrics
left join states_goals sg
on sg.postal_cd = sn.postal_cd
--goals metrics and sample metrics
left join states_fiber sf
on sf.postal_cd = sn.postal_cd
--goals metrics and sample metrics
left join states_afford sa
on sa.postal_cd = sn.postal_cd

where sn.postal_cd != 'DC'

order by postal_cd