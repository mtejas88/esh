with esh_calc as (
  select  *,
          budget_remaining_c2_2016*c2_discount_rate as budget_remaining_c2_2016_postdiscount
  from(
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
              physical_state,
              user_entered_urban_rural_status,
              number_of_full_time_students,
              total_number_of_part_time_students,
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
          status,
          physical_state,
          user_entered_urban_rural_status,
          number_of_full_time_students::numeric,
          total_number_of_part_time_students::numeric,
          number_of_nlsp_students::numeric,
          cep_percentage::numeric,
          alternative_discount_method,
      --c2 budgeting from 2016 from: https://www.fundsforlearning.com/blog/2017/03/category-2-budget-caps-adjusted-for-2017
          case
            when (number_of_full_time_students::numeric+total_number_of_part_time_students::numeric)*151.50 < 9292
              then 9292
            else (number_of_full_time_students::numeric+total_number_of_part_time_students::numeric)*151.50
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
        from public.fy2016_schools_demog_matr sd
        left join public.entity_bens eb
        on sd.school_esh_id = eb.entity_id::varchar
        left join fy2016.entity_reports er
        on er.entity_number = eb.ben
        where sd.district_include_in_universe_of_districts = true
        --removing duplicate BEN matches
--        and (eb.ben not in ('16066179', '16051537', '95372', '95348', '204335', '95071') or eb.ben is null)
    --to-do: this only includes schools in districts included in our universe. we will want to analyze the other schools at a later date.
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
    ) c2_budgeting
  ) c2_remaining
),

single_entities as (
  select school_esh_id
  from esh_calc
  group by school_esh_id
  having count(*) = 1
),

comparison as (
  select
    postal_cd,
    district_esh_id,
    esh_calc.ben,
    case
      when esh_calc.c2_budget is null
        then 0
      else esh_calc.c2_budget
    end as esh_c2_budget,
    case
      when c2_budgets.c2_budget is null
        then 0
      else c2_budgets.c2_budget
    end as usac_c2_budget,
    case
      when esh_calc.c2_budget is null
        then 0
      else esh_calc.c2_budget
    end - case
            when c2_budgets.c2_budget is null
              then 0
            else c2_budgets.c2_budget
          end as budget_diff,
    case
      when esh_calc.budget_remaining_c2_2016 is null
        then 0
      else esh_calc.budget_remaining_c2_2016
    end as esh_remaining_balance,
    case
      when c2_budgets.remaining_balance is null
        then 0
      else c2_budgets.remaining_balance
    end as usac_remaining_balance,
    case
      when esh_calc.budget_remaining_c2_2016 is null
        then 0
      else esh_calc.budget_remaining_c2_2016
    end - case
            when c2_budgets.remaining_balance is null
              then 0
            else c2_budgets.remaining_balance
          end as remaining_diff
  from esh_calc
  inner join c2_budgets
  on esh_calc.ben = c2_budgets.ben::varchar
  inner join single_entities
  on esh_calc.school_esh_id = single_entities.school_esh_id
  where year = 2016
  and c2_budgets.c2_budget is not null
)

select 'national' as state,
sum(esh_remaining_balance) as esh_remaining_balance,
sum(usac_remaining_balance) as usac_remaining_balance,
median(usac_remaining_balance) as median_usac_remaining_balance,
sum(remaining_diff) as sum_remaining_diff,
median(remaining_diff) as median_remaining_diff,
median(case
          when remaining_diff != 0
            then abs(remaining_diff)
        end) as median_remaining_diff_abs_non0,
median(case
          when remaining_diff != 0 and usac_remaining_balance > 0
            then abs(remaining_diff)/usac_remaining_balance
        end) as median_pct_remaining_diff_abs_non0,
count(*) as schools,
sum(case
      when remaining_diff = 0
        then 1
      else 0
    end) as schools_0_remaining_diff,
sum(case
      when remaining_diff = 0
        then 1
      else 0
    end)/count(*)::numeric as pct_schools_0_remaining_diff,
sum(case
      when usac_remaining_balance > 0 and abs(remaining_diff)/usac_remaining_balance > .1
        then 1
      else 0
    end) as schools_gt10pct_remaining_diff,
sum(case
      when usac_remaining_balance > 0 and abs(remaining_diff)/usac_remaining_balance > .1
        then 1
      else 0
    end)/count(*)::numeric as pct_schools_gt10pct_remaining_diff
from comparison

UNION

select postal_cd as state,
sum(esh_remaining_balance) as esh_remaining_balance,
sum(usac_remaining_balance) as usac_remaining_balance,
median(usac_remaining_balance) as median_usac_remaining_balance,
sum(remaining_diff) as sum_remaining_diff,
median(remaining_diff) as median_remaining_diff,
median(case
          when remaining_diff != 0
            then abs(remaining_diff)
        end) as median_remaining_diff_abs_non0,
median(case
          when remaining_diff != 0 and usac_remaining_balance > 0
            then abs(remaining_diff)/usac_remaining_balance
        end) as median_pct_remaining_diff_abs_non0,
count(*) as schools,
sum(case
      when remaining_diff = 0
        then 1
      else 0
    end) as schools_0_remaining_diff,
sum(case
      when remaining_diff = 0
        then 1
      else 0
    end)/count(*)::numeric as pct_schools_0_remaining_diff,
sum(case
      when usac_remaining_balance > 0 and abs(remaining_diff)/usac_remaining_balance > .1
        then 1
      else 0
    end) as schools_gt10pct_remaining_diff,
sum(case
      when usac_remaining_balance > 0 and abs(remaining_diff)/usac_remaining_balance > .1
        then 1
      else 0
    end)/count(*)::numeric as pct_schools_gt10pct_remaining_diff
from comparison
group by 1