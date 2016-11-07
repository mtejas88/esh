select  esh_id,
        c2_cost_budget as c2_prediscount_budget_15,
        c2_cost_remaining_2015 as c2_prediscount_remaining_15,
        c2_cost_budget - c2_cost_remaining_2015 as c2_pre_discount_spent_15,
        c2_cost_remaining_2016 as c2_prediscount_remaining_16,
        c2_cost_remaining_2015 - c2_cost_remaining_2016 as c2_pre_discount_spent_16,
        c2_cost_remaining_2015*c2_discount_rate_for_remaining_budget as c2_postdiscount_remaining_15,
        c2_cost_remaining_2016*c2_discount_rate_for_remaining_budget as c2_postdiscount_remaining_16,
        case
          when c2_cost_budget > c2_cost_remaining_2015
            then true
          else false
        end as received_c2_15,
        case
          when c2_cost_remaining_2015 > c2_cost_remaining_2016
            then true
          else false
        end as received_c2_16,
        case
          when c2_cost_remaining_2015 = 0
            then true
          else false
        end as budget_used_c2_15,
        case
          when c2_cost_remaining_2016 = 0
            then true
          else false
        end as budget_used_c2_16
from (
  select
    districts_2015.esh_id,
    districts_2015.postal_cd,
    districts_2015.c2_cost_budget,
    districts_2015.weighted_avg_dr as district_dr_2015,
    round(districts_c2_recipient_2016.proportionate_c2_funding::numeric/
            districts_c2_recipient_2016.proportionate_c2_cost::numeric,2) as district_dr_2016,
    case
      when round(districts_c2_recipient_2016.proportionate_c2_funding::numeric/
                  districts_c2_recipient_2016.proportionate_c2_cost::numeric,2) is null
        then  case
                when districts_2015.weighted_avg_dr is null
                  then round(state_agg_c2_dr::numeric,2)
                else districts_2015.weighted_avg_dr
              end
      else round(districts_c2_recipient_2016.proportionate_c2_funding::numeric/
                  districts_c2_recipient_2016.proportionate_c2_cost::numeric,2)
    end as c2_discount_rate_for_remaining_budget,
    districts_2015.proportionate_c2_cost as c2_cost_2015,
    districts_c2_recipient_2016.proportionate_c2_cost as c2_cost_2016,
    districts_2015.proportionate_c2_funding as c2_funding_2015,
    districts_c2_recipient_2016.proportionate_c2_funding as c2_funding_2016,
    c2_cost_remaining as c2_cost_remaining_2015,
    case
      when districts_c2_recipient_2016.proportionate_c2_cost is null
        then c2_cost_remaining
      when c2_cost_remaining < districts_c2_recipient_2016.proportionate_c2_cost
        then 0
      else c2_cost_remaining - districts_c2_recipient_2016.proportionate_c2_cost
    end as c2_cost_remaining_2016

  from (
    select
      esh_id,
      postal_cd,
      c2_cost_budget,
      round(proportionate_c2_funding/proportionate_c2_cost,2) as weighted_avg_dr,
      proportionate_c2_cost,
      proportionate_c2_funding,
      case
        when proportionate_c2_cost is null
          then c2_cost_budget
        when c2_cost_budget < proportionate_c2_cost
          then 0
        else c2_cost_budget - proportionate_c2_cost
      end as c2_cost_remaining

    from (
      select esh_id,
            dd.postal_cd,
            sum(case
              when sd.num_students*150 < 9200
                then 9200
              else sd.num_students*150
            end) as c2_cost_budget
      from public.fy2016_districts_demog_matr dd
      left join public.fy2016_schools_demog_matr sd
      on dd.esh_id = sd.district_esh_id
      where include_in_universe_of_districts = true
      group by  esh_id,
                dd.postal_cd
    ) universe_districts
    left join (
      select
        district_esh_id,
        sum((ad_2015.cat_2_cost/a_2015.alloc_cat_2_cost)*case
                                                when c2_li_2015.total_cost is null
                                                  then a_2015.alloc_cat_2_cost
                                                else c2_li_2015.total_cost
                                              end) as proportionate_c2_cost,
        sum((ad_2015.cat_2_cost/a_2015.alloc_cat_2_cost)*case
                                                when c2_li_2015.total_cost is null
                                                  then a_2015.alloc_cat_2_cost
                                                else c2_li_2015.total_cost
                                              end*(case
                                                    when "Discount" is null
                                                      then 70
                                                    else "Discount"
                                                  end/100)) as proportionate_c2_funding
      from (
        select
          a.line_item_id,
          dl.district_esh_id,
          a.cat_2_cost
          from public.allocations a
          left join public.fy2016_district_lookup_matr dl
          on a.recipient_id::varchar = dl.esh_id
          left join (
            select esh_id,
                  dd.postal_cd,
                  sum(case
                    when sd.num_students*150 < 9200
                      then 9200
                    else sd.num_students*150
                  end) as c2_cost_budget
            from public.fy2016_districts_demog_matr dd
            left join public.fy2016_schools_demog_matr sd
            on dd.esh_id = sd.district_esh_id
            where include_in_universe_of_districts = true
            group by  esh_id,
                      dd.postal_cd
          ) dd
          on dl.district_esh_id = dd.esh_id
          where dl.district_esh_id is not null
          and a.cat_2_cost > 0
      ) ad_2015
      left join (
        select *
        from public.line_items
        where service_category ilike '%internal%'
      ) c2_li_2015
      on c2_li_2015.id = ad_2015.line_item_id
      left join (
        select
          a.line_item_id,
          sum(a.cat_2_cost) as alloc_cat_2_cost
          from public.allocations a
          where a.cat_2_cost > 0
        group by a.line_item_id
      ) a_2015
      on a_2015.line_item_id = ad_2015.line_item_id
      left join public.fy2015_funding_request_key_informations frki
      on c2_li_2015.frn = frki."FRN"

      group by district_esh_id
    ) districts_c2_recipient_2015
    on universe_districts.esh_id = districts_c2_recipient_2015.district_esh_id::varchar
  ) districts_2015
  left join (
    select
      district_esh_id,
      sum((ad_2016.cat_2_cost/case
                          when a_2016.alloc_cat_2_cost>0
                            then a_2016.alloc_cat_2_cost
                          else c2_li_2016.total_cost
                        end) * case
                                  when c2_li_2016.total_cost is null
                                  then a_2016.alloc_cat_2_cost
                                  else c2_li_2016.total_cost
                               end) as proportionate_c2_cost,
      sum((ad_2016.cat_2_cost/case
                          when a_2016.alloc_cat_2_cost>0
                            then a_2016.alloc_cat_2_cost
                          else c2_li_2016.total_cost
                        end)*case
                                when c2_li_2016.total_cost is null
                                  then a_2016.alloc_cat_2_cost
                                else c2_li_2016.total_cost
                              end*(case
                                      when discount_rate is null
                                        then 70
                                      else discount_rate::numeric
                                    end/100)) as proportionate_c2_funding
    from (
      select
        a.line_item_id,
        dl.district_esh_id,
        a.cat_2_cost
        from fy2016.allocations a
        left join public.fy2016_district_lookup_matr dl
        on a.recipient_id::varchar = dl.esh_id
        left join (
          select esh_id,
                dd.postal_cd,
                sum(case
                  when sd.num_students*150 < 9200
                    then 9200
                  else sd.num_students*150
                end) as c2_cost_budget
          from public.fy2016_districts_demog_matr dd
          left join public.fy2016_schools_demog_matr sd
          on dd.esh_id = sd.district_esh_id
          where include_in_universe_of_districts = true
          group by  esh_id,
                    dd.postal_cd
        ) dd
        on dl.district_esh_id = dd.esh_id
        where dl.district_esh_id is not null
        and a.cat_2_cost > 0
    ) ad_2016
    left join (
      select *
      from fy2016.line_items
      where service_category = '2.0'
    ) c2_li_2016
    on c2_li_2016.id = ad_2016.line_item_id
    left join (
      select
        a.line_item_id,
        sum(a.cat_2_cost) as alloc_cat_2_cost
        from fy2016.allocations a
        where a.cat_2_cost > 0
      group by a.line_item_id
    ) a_2016
    on a_2016.line_item_id = ad_2016.line_item_id
    left join fy2016.frns
    on c2_li_2016.frn = frns.frn

    group by district_esh_id
  ) districts_c2_recipient_2016
  on districts_2015.esh_id = districts_c2_recipient_2016.district_esh_id
  left join (
    select
      postal_cd,
      sum(proportionate_c2_funding)/sum(proportionate_c2_cost) as state_agg_c2_dr
    from (
      select
        district_esh_id,
        sum((ad_2016.cat_2_cost/case
                            when a_2016.alloc_cat_2_cost>0
                              then a_2016.alloc_cat_2_cost
                            else c2_li_2016.total_cost
                          end) * case
                                    when c2_li_2016.total_cost is null
                                    then a_2016.alloc_cat_2_cost
                                    else c2_li_2016.total_cost
                                 end) as proportionate_c2_cost,
        sum((ad_2016.cat_2_cost/case
                            when a_2016.alloc_cat_2_cost>0
                              then a_2016.alloc_cat_2_cost
                            else c2_li_2016.total_cost
                          end)*case
                                  when c2_li_2016.total_cost is null
                                    then a_2016.alloc_cat_2_cost
                                  else c2_li_2016.total_cost
                                end*(case
                                        when discount_rate is null
                                          then 70
                                        else discount_rate::numeric
                                      end/100)) as proportionate_c2_funding
      from (
        select
          a.line_item_id,
          dl.district_esh_id,
          a.cat_2_cost
          from fy2016.allocations a
          left join public.fy2016_district_lookup_matr dl
          on a.recipient_id::varchar = dl.esh_id
          left join (
            select esh_id,
                  dd.postal_cd,
                  sum(case
                    when sd.num_students*150 < 9200
                      then 9200
                    else sd.num_students*150
                  end) as c2_cost_budget
            from public.fy2016_districts_demog_matr dd
            left join public.fy2016_schools_demog_matr sd
            on dd.esh_id = sd.district_esh_id
            where include_in_universe_of_districts = true
            group by  esh_id,
                      dd.postal_cd
          ) dd
          on dl.district_esh_id = dd.esh_id
          where dl.district_esh_id is not null
          and a.cat_2_cost > 0
      ) ad_2016
      left join (
        select *
        from fy2016.line_items
        where service_category = '2.0'
      ) c2_li_2016
      on c2_li_2016.id = ad_2016.line_item_id
      left join (
        select
          a.line_item_id,
          sum(a.cat_2_cost) as alloc_cat_2_cost
          from fy2016.allocations a
          where a.cat_2_cost > 0
        group by a.line_item_id
      ) a_2016
      on a_2016.line_item_id = ad_2016.line_item_id
      left join fy2016.frns
      on c2_li_2016.frn = frns.frn

      group by district_esh_id
    ) districts_c2_recipient_2016
    left join (
      select esh_id,
            dd.postal_cd,
            sum(case
              when sd.num_students*150 < 9200
                then 9200
              else sd.num_students*150
            end) as c2_cost_budget
      from public.fy2016_districts_demog_matr dd
      left join public.fy2016_schools_demog_matr sd
      on dd.esh_id = sd.district_esh_id
      where include_in_universe_of_districts = true
      group by  esh_id,
                dd.postal_cd
    ) universe_districts
    on districts_c2_recipient_2016.district_esh_id = universe_districts.esh_id
    where proportionate_c2_cost > 0
    group by postal_cd
  ) agg_dr_2016
  on districts_2015.postal_cd = agg_dr_2016.postal_cd
) district_cost

/*
Author: Justine Schott
Created On Date: 10/14/2016
Last Modified Date: 11/7/2016 -- for crusher structure
Name of QAing Analyst(s): Jess Seok
Purpose: 2015 and 2016 line item data for c2 aggregated to determine remaining budget
Methodology:
*/