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
  select  entity_number,
          entity_type,
          parent_entity_number,
          parent_entity_type,
          physical_state,
          user_entered_urban_rural_status,
          number_of_full_time_students::numeric,
          total_number_of_part_time_students::numeric,
          number_of_nlsp_students::numeric,
          cep_percentage::numeric,
          alternative_discount_method,
          c2_budget,
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
      entity_number,
      entity_type,
      parent_entity_number,
      parent_entity_type,
      status,
      physical_state,
      user_entered_urban_rural_status,
      number_of_full_time_students::numeric,
      total_number_of_part_time_students::numeric,
      number_of_nlsp_students::numeric,
      cep_percentage::numeric,
      alternative_discount_method,
      bie,
      charter_school,
      dormitory,
      esa_school,
      esa_school_district_with_no_schools,
      head_start,
      juvenile_justice,
      new_construction_school,
      pre_k,
      private_school,
      public_school,
      tribal_school,
      adult_education,
  --c2 budgeting from 2016 from: https://www.fundsforlearning.com/blog/2017/03/category-2-budget-caps-adjusted-for-2017
      case
        when (number_of_full_time_students::numeric+(total_number_of_part_time_students::numeric))*151.50 < 9292
          then 9292
        else (number_of_full_time_students::numeric+(total_number_of_part_time_students::numeric))*151.50
      end as c2_budget

    from fy2016.entity_reports er
    --to-do: check diffs in school counts from our universe
    where physical_state in ('KS','WY')
    and status = 'Active'
    and entity_type = 'School'
  ) ks_wy_entities
  left join (
    select
      "BEN",
    --to-do: update to be proportionately equal to line item cost
      sum(case
            when commitment_status = 'NOT FUNDED'
              then "Cat 2 Cost Alloc"
            else 0
          end) as amount_c2_2015,
      sum("Cat 2 Cost Alloc") as amount_c2_2015_incl_not_funded
    from public.fy2015_item21_allocations_by_entities ae
    left join public.funding_requests fr
    on ae."FRN" = fr.frn
    --to-do: update to accurate set of c2 data (there are some with c1 and c2 entries)
    where "Cat 2 Cost Alloc" is not null
    group by 1
  ) c2_allocations_2015
  on ks_wy_entities.entity_number = c2_allocations_2015."BEN"
  left join (
    select
      ros.ben,
    --to-do: update to be proportionately equal to line item cost
      sum(case
            when frn_status = 'Denied'
              then amount::numeric
            else 0
          end) as amount_c2_2016,
      sum(amount::numeric) as amount_c2_2016_incl_denied
    from fy2016.recipients_of_services ros
    left join public.funding_requests_2016_and_later fr
    on ros.frn = fr.frn
    --to-do: update to accurate set of c2 data
    where amount is not null
    group by 1
  ) c2_allocations_2016
  on ks_wy_entities.entity_number = c2_allocations_2016.ben
) c2_budgeting