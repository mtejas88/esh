select  dcr.recipient_id,
      dcr.contract_end_date as soonest_contract_end_date,
      dclir.contract_end_date as largest_internet_contract_end_date
from (select  svcs.recipient_id,
            li.contract_end_date,
            row_number() over (partition by svcs.recipient_id order by li.contract_end_date) as rank_order
    from public.services_received_2015 svcs
    join (select *
          from line_items
          where contract_end_date is not null) li
    on svcs.line_item_id = li.id
    where shared_service = 'District-dedicated'
    and svcs.dqs_excluded = false
    order by recipient_id ) dcr
left join (select  svcs.recipient_id,
                 li.contract_end_date,
                 row_number() over (partition by svcs.recipient_id order by svcs.bandwidth_in_mbps desc) as rank_order
         from public.services_received_2015 svcs
         join (select *
               from line_items
               where contract_end_date is not null) li
         on svcs.line_item_id = li.id
where shared_service = 'District-dedicated'
and svcs.dqs_excluded = false
and svcs.internet_conditions_met = true
      
order by recipient_id ) dclir
on dcr.recipient_id = dclir.recipient_id
where (dcr.rank_order = 1 or  dcr.rank_order is null)
and (dclir.rank_order = 1 or dclir.rank_order is null)
and (dcr.contract_end_date is not null
  or dclir.contract_end_date is not null)

