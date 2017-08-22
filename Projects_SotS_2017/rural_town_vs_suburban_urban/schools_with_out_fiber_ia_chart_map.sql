select l.school_esh_id as school_id, l.name, l.school_type,
case when l.locale in ('Rural','Town') then 'Rural/Town' else 'Suburban/Urban' end as locale,
l.zip::numeric,
case when hierarchy_ia_connect_category != 'Fiber' then 'Without Fiber IA' else 'Fiber IA' end as fiber_ia
 from public.fy2017_districts_deluxe_matr del
 join public.fy2017_schools_demog_matr l on del.esh_id::numeric=l.district_esh_id::numeric
where  del.exclude_from_ia_analysis=false
and del.include_in_universe_of_districts
and del.district_type = 'Traditional'

/* mode report with charts/pivot: https://modeanalytics.com/editor/educationsuperhighway/reports/436ba3cbbfa1
"Rural/Town vs. S/U: Chart showing schools without fiber IA; map"
*/