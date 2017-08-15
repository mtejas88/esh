with school_calc as (
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
                amount_c2_2016,
                amount_c2_2017,
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
              when eb.ben is null
                then  case  when sd.num_students * 153.47 < 9412.80 then 9412.80
                            else sd.num_students * 153.47
                      end
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
            sum(ae."Cat 2 Cost Alloc") as amount_c2_2015
          from fy2015.current_item21_allocations_by_entities ae
          left join fy2015.current_funding_request_key_informations frki
          on ae."FRN" = frki."FRN"
          where "Service Type" ilike '%internal%'
          group by 1
        ) c2_allocations_2015
        on entities.ben = c2_allocations_2015."BEN"
        left join (
--note: allocations are source of truth

--example line item 1699013358.008 has less allocations than total cost
--this was because only half was allocated to BEN 72917 in current data, where half could have been
--  allocated to BEN 72918 like all the other line items in the FRN
--even the committed_amount on the funding_requests table shows a committed amount that would include that other half
--however, the usac budget tool doesn't care that more was committed than was allocated. it only looks at allocations

--example line item 1699010222.001 has more allocations than total cost
--this was because the original requested amount aligns with the allocations, but only part of that was funded.
--however, the usac budget tool doesn't care that less was committed than was allocated. it only looks at allocations
          select
            ros.ben,
            sum(amount::numeric) as amount_c2_2016
          from fy2016.current_recipients_of_services ros
          left join fy2016.current_basic_informations bi
          on ros.application_number = bi.application_number
          where bi.category_of_service::numeric = 2
          group by 1
        ) c2_allocations_2016
        on entities.ben = c2_allocations_2016.ben
        left join (
          select
            ros.ben,
            sum(amount::numeric) as amount_c2_2017
          from fy2017.current_recipients_of_services ros
          left join fy2017.current_basic_informations bi
          on ros.application_number = bi.application_number
          where bi.category_of_service::numeric = 2
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

)

select
  district_esh_id as esh_id,
  sum(c2_budget) as c2_budget,
  sum(c2_budget_postdiscount) as c2_budget_postdiscount,
  sum(budget_remaining_c2_2015) as budget_remaining_c2_2015,
  sum(budget_remaining_c2_2016) as budget_remaining_c2_2016,
  sum(budget_remaining_c2_2017) as budget_remaining_c2_2017,
  sum(budget_remaining_c2_2015_postdiscount) as budget_remaining_c2_2015_postdiscount,
  sum(budget_remaining_c2_2016_postdiscount) as budget_remaining_c2_2016_postdiscount,
  sum(budget_remaining_c2_2017_postdiscount) as budget_remaining_c2_2017_postdiscount,
  sum(c2_budget_haircut) as c2_budget_haircut,
  sum(c2_budget_postdiscount_haircuit) as c2_budget_postdiscount_haircuit,
  sum(budget_remaining_c2_2015_haircut) as budget_remaining_c2_2015_haircut,
  sum(budget_remaining_c2_2016_haircut) as budget_remaining_c2_2016_haircut,
  sum(budget_remaining_c2_2017_haircut) as budget_remaining_c2_2017_haircut,
  sum(budget_remaining_c2_2015_postdiscount_haircut) as budget_remaining_c2_2015_postdiscount_haircut,
  sum(budget_remaining_c2_2016_postdiscount_haircut) as budget_remaining_c2_2016_postdiscount_haircut,
  sum(budget_remaining_c2_2017_postdiscount_haircut) as budget_remaining_c2_2017_postdiscount_haircut,
  case
    when sum(c2_budget) > sum(budget_remaining_c2_2015)
      then true
    else false
  end as received_c2_15,
  case
    when sum(budget_remaining_c2_2015) > sum(budget_remaining_c2_2016)
      then true
    else false
  end as received_c2_16,
  case
    when sum(budget_remaining_c2_2016) > sum(budget_remaining_c2_2017)
      then true
    else false
  end as received_c2_17,
  case
    when sum(budget_remaining_c2_2015) = 0
      then true
    else false
  end as budget_used_c2_15,
  case
    when sum(budget_remaining_c2_2016) = 0
      then true
    else false
  end as budget_used_c2_16,
  case
    when sum(budget_remaining_c2_2017) = 0
      then true
    else false
  end as budget_used_c2_17

from
  schools

group by
  district_esh_id

/*
Author: Jeremy Holtzman
Created On Date: 5/30/2017
Last Modified Date: 6/23/2017 - JH got rid of rounded c2
Name of QAing Analyst(s):
Purpose: 2015 and 2016 line item data for c2 aggregated to determine remaining budget.
Methodology: Same methodology as 2015 and 2016, but we applied a 90% haircut to the budget and remaining budget given the fact
that the C2 remaining budget does not always match USAC
*/