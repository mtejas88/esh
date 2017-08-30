/*STEPS
2. Find total $ in SR
3. Find total $ in SR in AK
5. Find total $ in SR not in AK (2 - 3)
*/

with lines as (

  select (dd.postal_cd = 'AK') as postal_cd_AK,
    line_item_id,
    recipient_id,
    line_item_district_mrc_unless_null

  from public.fy2017_services_received_matr sr

  join public.fy2017_districts_deluxe_matr dd
  on sr.recipient_id = dd.esh_id

  where inclusion_status != 'dqs_excluded'
  and dd.include_in_universe_of_districts = true
  and dd.district_type = 'Traditional'

)
 
select postal_cd_AK,
round(sum(line_item_district_mrc_unless_null * 12),0) as total_costs

from lines
group by 1

/* Methodology 
0. Find % clean SR $ that are IA in AK
1. Find % clean SR $ that are IA not in AK
2. Find total $ in SR
3. Find total $ in SR in AK
4. Find extrap $ IA in AK (0 * 3)
5. Find total $ in SR not in AK (2 - 3)
6. Find extrap $ IA not in AK (5 * 1)
7. Find wtd avg bw/student in AK in 0
8. Find wtd avg bw/student not in AK in 1
9. Find 1 Mbps cost, bw/student not in AK
10. Find 1 Mbps bw/student in AK
11. Find change in cost, change in BW not in AK (6,8,9)
12. Find change in BW in AK (7, 10)
13. Find 1 Mbps cost in AK (4, 11, 12)
14. Find WAN for everyone
*/