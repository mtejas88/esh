          select
            concat(ae."FRN",'-',ae."FRN Line Item No") as frn_complete,
            sc."Total Cost",
            sum(ae."Cat 2 Cost Alloc") as amount_c2_2015
          from fy2015.current_item21_allocations_by_entities ae
          left join fy2015.current_funding_request_key_informations frki
          on ae."FRN" = frki."FRN"
          left join fy2015.current_item21_services_and_costs sc
          on concat(ae."FRN",'-',ae."FRN Line Item No") = concat(sc."FRN",'-',sc."FRN Line Item No")
          where "Service Type" ilike '%internal%'
          group by 1, 2
          having sum(ae."Cat 2 Cost Alloc") != sc."Total Cost"::numeric
