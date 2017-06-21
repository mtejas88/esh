------------------data sources
with nces_13_14 as (
	select esh_id, 
	postal_cd,
	exclude_from_ia_analysis,
	ia_bw_mbps_total, 
	ia_bandwidth_per_student_kbps as nces_13_14_bw_student,
	current_assumed_unscalable_campuses + current_known_unscalable_campuses  as num_campuses_unscalable,
	num_campuses as nces_13_14_num_campuses
	from public.fy2016_districts_deluxe_matr
	where include_in_universe_of_districts
  and district_type = 'Traditional'
),

nces_14_15 as (
	select esh_id,
	num_students,
	num_campuses
	from public.fy2017_districts_deluxe_matr
    where include_in_universe_of_districts
),

	--subqueries for USAC 2017
school_calc as (
  select  *,
          budget_remaining_c2_2015*c2_discount_rate as budget_remaining_c2_2015_postdiscount,
          budget_remaining_c2_2016*c2_discount_rate as budget_remaining_c2_2016_postdiscount,
          budget_remaining_c2_2017*c2_discount_rate as budget_remaining_c2_2017_postdiscount,
          row_number() over(
            partition by school_esh_id
            order by budget_remaining_c2_2016*c2_discount_rate asc
          ) as filtering_number
  from(
    select *,
            case
              when budget_remaining_c2_2016 < amount_c2_2017
                then 0
              else budget_remaining_c2_2016 - case
                                                when amount_c2_2017 is null
                                                  then 0
                                                else amount_c2_2017
                                              end
            end as budget_remaining_c2_2017

    from (
      select  *,
              case
                when budget_remaining_c2_2015 < amount_c2_2016
                  then 0
                else budget_remaining_c2_2015 - case
                                                  when amount_c2_2016 is null
                                                    then 0
                                                  else amount_c2_2016
                                                end
              end as budget_remaining_c2_2016

      from (
        select  school_esh_id,
                district_esh_id,
                postal_cd,
                entities.ben,
                entity_number,
                entity_type,
                entity_name,
                physical_state,
                user_entered_urban_rural_status,
                number_of_full_time_students,
                total_number_of_part_time_students,
                schools_demog_num_students,
                number_of_nlsp_students,
                cep_percentage,
                alternative_discount_method,
                c2_discount_rate,
                c2_budget,
                c2_budget*c2_discount_rate as c2_budget_postdiscount,
                amount_c2_2015,
                amount_c2_2015_incl_not_funded,
                amount_c2_2016,
                amount_c2_2016_incl_denied,
                amount_c2_2017,
                amount_c2_2017_incl_denied,
                case
                  when c2_budget < amount_c2_2015
                    then 0
                  else c2_budget -  case
                                      when amount_c2_2015 is null
                                        then 0
                                      else amount_c2_2015
                                    end
                end as budget_remaining_c2_2015

        from(
          select distinct
            sd.school_esh_id,
            sd.district_esh_id,
            sd.postal_cd,
            eb.ben,
            entity_number,
            er.entity_type,
            er.entity_name,
            status,
            physical_state,
            user_entered_urban_rural_status,
            number_of_full_time_students::numeric,
            total_number_of_part_time_students::numeric,
            sd.num_students as schools_demog_num_students,
            number_of_nlsp_students::numeric,
            cep_percentage::numeric,
            alternative_discount_method,
        --c2 budgeting from 2016 from: https://www.fundsforlearning.com/blog/2017/03/category-2-budget-caps-adjusted-for-2017
            case
              when eb.ben is null then 0
              when (case  when number_of_full_time_students is null then 0
                          else number_of_full_time_students::numeric end
                    + case  when total_number_of_part_time_students is null then 0
                            else total_number_of_part_time_students::numeric end)*153.47 < 9412.80
                then 9412.80

              --adding this condition because there are some schools that clearly have user entered mistakes for num students.
              --this condition changes the student count that we use for ~630 schools
              when 5 * sd.num_students < (case  when number_of_full_time_students is null then 0
                                              else number_of_full_time_students::numeric end
                                          + case  when total_number_of_part_time_students is null then 0
                                                  else total_number_of_part_time_students::numeric end)
                then  case  when sd.num_students * 153.47 < 9412.80 then 9412.80
                            else sd.num_students * 153.47
                      end
              else (case  when number_of_full_time_students is null then 0
                          else number_of_full_time_students::numeric end
                    + case  when total_number_of_part_time_students is null then 0
                            else total_number_of_part_time_students::numeric end)*153.47
            end as c2_budget,
            case
              when number_of_full_time_students::numeric > 0 then
                case
                  when user_entered_urban_rural_status = 'Urban' then
                    case  when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .01 then .20
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .20 then .40
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .35 then .50
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .50 then .60
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .75 then .80
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric >= .75 then .85
                          else .7
                    end
                  when user_entered_urban_rural_status = 'Rural' then
                    case  when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .01 then .25
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .20 then .50
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .35 then .60
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .50 then .70
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .75 then .80
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric >= .75 then .85
                          else .7
                    end
                  else
                    case  when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .50 then .7
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric < .75 then .80
                          when number_of_nlsp_students::numeric/number_of_full_time_students::numeric >= .75 then .85
                          else .7
                    end
                end
            else .7
          end as c2_discount_rate
          from public.fy2017_schools_demog_matr sd
          left join public.entity_bens eb
          on sd.school_esh_id = eb.entity_id::varchar
          left join fy2016.entity_reports er
          on er.entity_number = eb.ben
          left join public.fy2017_districts_demog_matr dd
          on sd.district_esh_id = dd.esh_id
          where dd.include_in_universe_of_districts_all_charters = true
        ) entities
        left join (
          select
            "BEN",
            sum(case
                  when commitment_status != 'NOT FUNDED'
                  --where total_cost is current, the allocations will be proportionate to the new total cost
                  --where total_cost isn't available, then the allocations will be the total cost
                    then (ae."Cat 2 Cost Alloc"/a.alloc_cat_2_cost)*case
                                                                      when li.total_cost is null
                                                                        then a.alloc_cat_2_cost
                                                                      else li.total_cost
                                                                    end
                  else 0
                end) as amount_c2_2015,
            sum((ae."Cat 2 Cost Alloc"/a.alloc_cat_2_cost)* case
                                                              when li.total_cost is null
                                                                then a.alloc_cat_2_cost
                                                              else li.total_cost
                                                            end) as amount_c2_2015_incl_not_funded
          from public.fy2015_item21_allocations_by_entities ae
          left join public.line_items li
          on concat(ae."FRN",'-',ae."FRN Line Item No") = li.frn_complete
          left join public.funding_requests fr
          on ae."FRN" = fr.frn
          left join (
            select
              concat(ae."FRN",'-',ae."FRN Line Item No") as frn_complete,
              sum(case
                    when "Cat 2 Cost Alloc" > 0
                      then "Cat 2 Cost Alloc"
                    else 0
                  end) as alloc_cat_2_cost
              from public.fy2015_item21_allocations_by_entities ae
              left join public.fy2015_funding_request_key_informations frki
              on ae."FRN" = frki."FRN"
              where "Service Type" ilike '%internal%'
            group by 1
          ) a
          on a.frn_complete = li.frn_complete
          left join public.fy2015_funding_request_key_informations frki
          on ae."FRN" = frki."FRN"
          where "Service Type" ilike '%internal%'
          and alloc_cat_2_cost > 0
          group by 1
        ) c2_allocations_2015
        on entities.ben = c2_allocations_2015."BEN"
        left join (
          select
            ros.ben,
            sum(case
                  when frn_status not in ('Denied', 'Cancelled')
                  --where total_cost is current, the allocations will be proportionate to the new total cost
                  --where total_cost isn't available, then the allocations will be the total cost
                    then (amount::numeric/a.alloc_cat_2_cost)*case
                                                                when li.total_cost is null
                                                                  then a.alloc_cat_2_cost
                                                                else li.total_cost
                                                              end
                  else 0
                end) as amount_c2_2016,
            sum((amount::numeric/a.alloc_cat_2_cost)* case
                                                        when li.total_cost is null
                                                          then a.alloc_cat_2_cost
                                                        else li.total_cost
                                                      end) as amount_c2_2016_incl_denied
          from fy2016.recipients_of_services ros
          left join fy2016.line_items li
          on ros.line_item = li.frn_complete
          left join public.funding_requests_2016_and_later fr
          on ros.frn = fr.frn
          left join (
            select
              line_item,
              sum(case
                    when amount::numeric > 0
                      then amount::numeric
                    else 0
                  end) as alloc_cat_2_cost
              from fy2016.recipients_of_services ros
              left join fy2016.basic_informations bi
              on ros.application_number = bi.application_number
              where bi.category_of_service::numeric = 2
            group by 1
          ) a
          on a.line_item = li.frn_complete
          left join fy2016.basic_informations bi
          on ros.application_number = bi.application_number
          where bi.category_of_service::numeric = 2
          and alloc_cat_2_cost > 0
          group by 1
        ) c2_allocations_2016
        on entities.ben = c2_allocations_2016.ben
        left join (
          select
            ros.ben,
            sum(case
                  when frn_status not in ('Denied', 'Cancelled')
                  --where total_cost is current, the allocations will be proportionate to the new total cost
                  --where total_cost isn't available, then the allocations will be the total cost
                    then (amount::numeric/a.alloc_cat_2_cost)*case
                                                                when li.total_cost is null
                                                                  then a.alloc_cat_2_cost
                                                                else li.total_cost
                                                              end
                  else 0
                end) as amount_c2_2017,
            sum((amount::numeric/a.alloc_cat_2_cost)* case
                                                        when li.total_cost is null
                                                          then a.alloc_cat_2_cost
                                                        else li.total_cost
                                                      end) as amount_c2_2017_incl_denied
          from fy2017.recipients_of_services ros
          left join public.esh_line_items li
          on ros.line_item = li.frn_complete
          and li.funding_year = 2017
          left join public.funding_requests_2016_and_later fr
          on ros.frn = fr.frn
          left join (
            select
              line_item,
              sum(case
                    when amount::numeric > 0
                      then amount::numeric
                    else 0
                  end) as alloc_cat_2_cost
              from fy2017.recipients_of_services ros
              left join fy2017.basic_informations bi
              on ros.application_number = bi.application_number
              where bi.category_of_service::numeric = 2
            group by 1
          ) a
          on a.line_item = li.frn_complete
          left join fy2017.basic_informations bi
          on ros.application_number = bi.application_number
          where bi.category_of_service::numeric = 2
          and alloc_cat_2_cost > 0
          group by 1
        ) c2_allocations_2017
        on entities.ben = c2_allocations_2017.ben
      ) c2_budgeting
    ) c2_remaining_16
  ) c2_remaining_17
),

schools as (

select district_esh_id,
school_esh_id,
filtering_number,
postal_cd,
ben,
entity_type,
entity_name,
number_of_full_time_students,
total_number_of_part_time_students,
schools_demog_num_students,
c2_discount_rate,
c2_budget,
c2_budget_postdiscount,
budget_remaining_c2_2015,
budget_remaining_c2_2016,
budget_remaining_c2_2017,
budget_remaining_c2_2015_postdiscount,
budget_remaining_c2_2016_postdiscount,
budget_remaining_c2_2017_postdiscount,
.9 * c2_budget as c2_budget_haircut,
.9 * c2_budget_postdiscount as c2_budget_postdiscount_haircuit,
.9 * budget_remaining_c2_2015 as budget_remaining_c2_2015_haircut,
.9 * budget_remaining_c2_2016 as budget_remaining_c2_2016_haircut,
.9 * budget_remaining_c2_2017 as budget_remaining_c2_2017_haircut,
.9 * budget_remaining_c2_2015_postdiscount as budget_remaining_c2_2015_postdiscount_haircut,
.9 * budget_remaining_c2_2016_postdiscount as budget_remaining_c2_2016_postdiscount_haircut,
.9 * budget_remaining_c2_2016_postdiscount as budget_remaining_c2_2017_postdiscount_haircut,
case
  when (c2_budget) > (budget_remaining_c2_2015)
    then true
  else false
end as received_c2_15,
case
  when (budget_remaining_c2_2015) > (budget_remaining_c2_2016)
    then true
  else false
end as received_c2_16,
case
  when (budget_remaining_c2_2016) > (budget_remaining_c2_2017)
    then true
  else false
end as received_c2_17,
case
  when (budget_remaining_c2_2015) = 0
    then true
  else false
end as budget_used_c2_15,
case
  when (budget_remaining_c2_2016) = 0
    then true
  else false
end as budget_used_c2_16,
case
  when (budget_remaining_c2_2017) = 0
    then true
  else false
end as budget_used_c2_17

from school_calc

where filtering_number = 1

order by budget_remaining_c2_2016_postdiscount desc

),


usac_2017 as (
select
district_esh_id as esh_id,
sum(number_of_full_time_students) as num_students,
count(distinct
   case
      when campus_id is null or campus_id = 'Unknown'
          then address
      else campus_id
  end) as num_campuses
from schools
left join ( select distinct s.esh_id__c, s.campus__c as campus_id, street__c as address
          from salesforce.facilities__c s
          left join salesforce.account d
          on s.account__c = d.sfid
          where s.out_of_business__c = false --not closed
          and s.recordtypeid = '01244000000DHd0AAG' --string for schools
          and (s.charter__c = false or d.type = 'Charter')) ds  -- not charters in regular districts
on schools.school_esh_id::varchar = ds.esh_id__c
group by 1
),

sfdc as (
	select esh_id__c as esh_id,
	district_num_students__c as num_students,
	num_campuses__c as num_campuses
	from salesforce.account
),

--creating Solomon's "merged" dataset: use NCES 2014-2015 as the base; if there is a match with USAC, replace with USAC's # students and campuses, then finally if there is a match with SFDC, update with SFDC # students and campuses
--1. merge nces_14_15 with sfdc and identify where the # students and campuses are the SAME (since SFDC already uses NCES 2014-2015 as the base)
merge1 as (
select a.* from nces_14_15 a
join sfdc b 
on a.esh_id=b.esh_id
and a.num_students=b.num_students
and a.num_campuses=b.num_campuses
),

--2. update merge1 with USAC 2017 values
merge1_usac as (
select a.esh_id,
case when a.esh_id=b.esh_id and b.num_students > 0 then b.num_students else a.num_students end as num_students,
case when a.esh_id=b.esh_id and b.num_campuses > 0 then b.num_campuses else a.num_campuses end as num_campuses
from merge1 a
left join usac_2017 b
on a.esh_id=b.esh_id
),

--3. update the rest of nces_14_15 with sfdc values that are different
merge2 as (
select a.esh_id,
case when a.esh_id=b.esh_id and b.num_students > 0 then b.num_students else a.num_students end as num_students,
case when a.esh_id=b.esh_id and b.num_campuses > 0 then b.num_campuses else a.num_campuses end as num_campuses
from nces_14_15 a
left join sfdc b
on a.esh_id=b.esh_id
where a.esh_id not in (select esh_id from merge1_usac)
),

--4. final merge
merge as(
select * from merge1_usac
union 
select * from merge2),

--final base table that computes the bw/student using the new data sources
nces_13_14_plus as (
 select a.*, 
 a.ia_bw_mbps_total/NULLIF(nces_14_15.num_students,0) * 1000 as nces_14_15_bw_student,
 a.ia_bw_mbps_total/NULLIF(usac_2017.num_students,0) * 1000 as usac_2017_bw_student,
 a.ia_bw_mbps_total/NULLIF(sfdc.num_students,0) * 1000 as sfdc_bw_student,
 a.ia_bw_mbps_total/NULLIF(merge.num_students,0) * 1000 as merge_bw_student
 from nces_13_14 a
 left join nces_14_15 on a.esh_id=nces_14_15.esh_id
 left join usac_2017 on a.esh_id=usac_2017.esh_id
 left join sfdc on a.esh_id=sfdc.esh_id
 left join merge on a.esh_id=merge.esh_id)

------------------------------------------ 
/*quantify the following diffs for each metric using the new dataset from NCES 2013-2014, nationally and by state:

% districts >100 kbps/student
% campuses unscalable
*/

--state level
 select 
 postal_cd,
 count(case when  exclude_from_ia_analysis = FALSE and nces_13_14_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as nces_13_14_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=nces_14_15.esh_id and exclude_from_ia_analysis = FALSE and nces_14_15_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=nces_14_15.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as nces_14_15_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=usac_2017.esh_id and exclude_from_ia_analysis = FALSE and usac_2017_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=usac_2017.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as usac_2017_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=sfdc.esh_id and exclude_from_ia_analysis = FALSE and sfdc_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=sfdc.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as sfdc_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=merge.esh_id and exclude_from_ia_analysis = FALSE and merge_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=merge.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as merge_pct_d_g100kpbs,
 
 sum(num_campuses_unscalable)/NULLIF(sum(nces_13_14_num_campuses),0) as nces_13_14_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(nces_14_15.num_campuses),0) as nces_14_15_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(usac_2017.num_campuses),0) as usac_2017_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(sfdc.num_campuses),0) as sfdc_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(merge.num_campuses),0) as merge_pct_campuses_unsc
 
 from nces_13_14_plus
 left join nces_14_15 on nces_13_14_plus.esh_id=nces_14_15.esh_id
 left join usac_2017 on nces_13_14_plus.esh_id=usac_2017.esh_id
 left join sfdc on nces_13_14_plus.esh_id=sfdc.esh_id
 left join merge on nces_13_14_plus.esh_id=merge.esh_id
 group by 1
 union
 --national level
 select 'National' as postal_cd,
 count(case when  exclude_from_ia_analysis = FALSE and nces_13_14_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as nces_13_14_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=nces_14_15.esh_id and exclude_from_ia_analysis = FALSE and nces_14_15_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=nces_14_15.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as nces_14_15_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=usac_2017.esh_id and exclude_from_ia_analysis = FALSE and usac_2017_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=usac_2017.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as usac_2017_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=sfdc.esh_id and exclude_from_ia_analysis = FALSE and sfdc_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=sfdc.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as sfdc_pct_d_g100kpbs,
 count(case when nces_13_14_plus.esh_id=merge.esh_id and exclude_from_ia_analysis = FALSE and merge_bw_student > 100 then nces_13_14_plus.esh_id end)::float/
 count(case when nces_13_14_plus.esh_id=merge.esh_id and exclude_from_ia_analysis = FALSE then nces_13_14_plus.esh_id end)::float as merge_pct_d_g100kpbs,
 
 sum(num_campuses_unscalable)/NULLIF(sum(nces_13_14_num_campuses),0) as nces_13_14_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(nces_14_15.num_campuses),0) as nces_14_15_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(usac_2017.num_campuses),0) as usac_2017_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(sfdc.num_campuses),0) as sfdc_pct_campuses_unsc,
 sum(num_campuses_unscalable)/NULLIF(sum(merge.num_campuses),0) as merge_pct_campuses_unsc
 
 from nces_13_14_plus
 left join nces_14_15 on nces_13_14_plus.esh_id=nces_14_15.esh_id
 left join usac_2017 on nces_13_14_plus.esh_id=usac_2017.esh_id
 left join sfdc on nces_13_14_plus.esh_id=sfdc.esh_id
 left join merge on nces_13_14_plus.esh_id=merge.esh_id
 group by 1