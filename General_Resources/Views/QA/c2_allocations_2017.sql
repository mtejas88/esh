          select
            ros.line_item,
            fli.pre_discount_extended_eligible_line_item_cost,
            sum(amount::numeric) as amount_c2_2017
          from fy2016.current_recipients_of_services ros
          left join fy2017.current_basic_informations bi
          on ros.application_number = bi.application_number
          left join fy2017.current_frn_line_items fli
          on ros.line_item = fli.line_item
          where bi.category_of_service::numeric = 2
          group by 1, 2
          having sum(amount::numeric) != fli.pre_discount_extended_eligible_line_item_cost::numeric
