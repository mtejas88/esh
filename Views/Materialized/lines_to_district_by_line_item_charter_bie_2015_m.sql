select district_esh_id,
      line_item_id,
      allocation_lines

  from public.lines_to_district_by_line_item_2015_m
  where district_esh_id not in (
        select distinct district_esh_id
        from (
            select dl_ca_2.district_esh_id,
                     c.line_item_id,
                     count(distinct ec.circuit_id) as allocation_lines

              from public.entity_circuits ec
              join public.circuits c
              on ec.circuit_id = c.id
              join (
                select dl_ca_1.*
                from (
                    --dl_ca_1: district_lookup for charters and BIEs. since they are not on the districts table,
                    --they may be categorized as consortia and their schools may be categorized as other_locations
                    select esh_id, district_esh_id, postal_cd
                            from public.schools
                            union
                            select esh_id, district_esh_id, postal_cd
                            from public.other_locations
                            union
                            select esh_id, esh_id as district_esh_id, postal_cd
                            from public.consortia) dl_ca_1
                join (
                    --charter_and_bie_agencies: to get identification information for charter and BIE districts
                    --since they are not on the districts akira table
                    select distinct ag121a.nces_cd,
                    eim.entity_id,
                      ag121a."NAME",
                      ag121a."LSTATE",
                      ag121a."LCITY",
                      ag121a."TYPE"

                    from ag121a

                    left join public.entity_nces_codes eim
                    on rpad(ag121a.nces_cd,12,'0')=eim.nces_code

                    where ("TYPE"=7 or "FIPST" = '59')
                    and "LSTATE" not in ('PR','AS','GU','VI')) charter_and_bie_agencies
                on dl_ca_1.district_esh_id = charter_and_bie_agencies.entity_id) dl_ca_2
              on ec.entity_id = dl_ca_2.esh_id

              group by  district_esh_id,
                     line_item_id
            ) ca_ldli
  )

UNION

select district_esh_id,
      line_item_id,
      allocation_lines

  from (
          select dl_ca_2.district_esh_id,
                 c.line_item_id,
                 count(distinct ec.circuit_id) as allocation_lines

          from public.entity_circuits ec
          join public.circuits c
          on ec.circuit_id = c.id
          join (
            select dl_ca_1.*
            from (
                --dl_ca_1: district_lookup for charters and BIEs. since they are not on the districts table,
                --they may be categorized as consortia and their schools may be categorized as other_locations
                select esh_id, district_esh_id, postal_cd
                        from public.schools
                        union
                        select esh_id, district_esh_id, postal_cd
                        from public.other_locations
                        union
                        select esh_id, esh_id as district_esh_id, postal_cd
                        from public.consortia) dl_ca_1
            join (
                --charter_and_bie_agencies: to get identification information for charter and BIE districts
                --since they are not on the districts akira table
                select distinct ag121a.nces_cd,
                eim.entity_id,
                  ag121a."NAME",
                  ag121a."LSTATE",
                  ag121a."LCITY",
                  ag121a."TYPE"

                from ag121a

                left join public.entity_nces_codes eim
                on rpad(ag121a.nces_cd,12,'0')=eim.nces_code

                where ("TYPE"=7 or "FIPST" = '59')
                and "LSTATE" not in ('PR','AS','GU','VI')) charter_and_bie_agencies
            on dl_ca_1.district_esh_id = charter_and_bie_agencies.entity_id) dl_ca_2
          on ec.entity_id = dl_ca_2.esh_id

          group by  district_esh_id,
                 line_item_id
        ) ca_ldli


/*
Author:                     Justine Schott
Created On Date:            6/1/2016
Last Modified Date:         12/5/2016
Name of QAing Analyst(s):   Greg Kurzhals
Purpose:                    To feed into priority_status query only
Methodology:                to combine counts of line items by districts for first, districts that are not ID'd
as charters, since we only want to include schools/districts for those district types, and then for charters and
BIEs (already limited)
Note:                       original query located here:
https://modeanalytics.com/educationsuperhighway/reports/f3981b94a2ff
*/