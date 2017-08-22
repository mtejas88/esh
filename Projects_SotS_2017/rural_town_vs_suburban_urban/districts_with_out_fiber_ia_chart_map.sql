

select esh_id, name,
case when locale in ('Rural','Town') then 'Rural/Town' else 'Suburban/Urban' end as locale,
longitude, latitude,
case when hierarchy_ia_connect_category != 'Fiber' then 'Without Fiber IA' else 'Fiber IA' end as fiber_ia
 from public.fy2017_districts_deluxe_matr del
where  del.exclude_from_ia_analysis=false
and include_in_universe_of_districts
and district_type = 'Traditional'


/* mode report with charts/pivot: https://modeanalytics.com/editor/educationsuperhighway/reports/436ba3cbbfa1
"Rural/Town vs. S/U: Chart showing districts without fiber IA; map"
*/