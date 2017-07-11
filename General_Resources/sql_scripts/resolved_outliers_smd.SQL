/* Outlier temp table */
with outlier_flags AS (
select flaggable_id as district_id
                      from public.flags 
                      where funding_year = 2017
                      and flaggable_type = 'District'
                      and label like '%outlier%'
                      and status = 'open'
                      
                      union 
                      
                      select sr.recipient_id::numeric as district_id
                      from public.flags a
                      
                      join public.fy2017_services_received_matr sr
                      on a.flaggable_id::numeric = sr.line_item_id::numeric
                      
                      join public.fy2017_districts_deluxe_matr dd
                      on sr.recipient_id=dd.esh_id
                      
                      where a.label like '%outlier%' 
                      and a.funding_year = 2017
                      and a.flaggable_type = 'LineItem'
                      and a.status = 'resolved'
)

SELECT dd.esh_id::numeric,
      CASE WHEN dd.esh_id IS NOT NULL then 'Resolved Outlier' END AS outlier_status
FROM fy2017_districts_deluxe_matr dd

JOIN outlier_flags
ON dd.esh_id::numeric= outlier_flags.district_id

