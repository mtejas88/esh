with current_16 as (SELECT
          COUNT("ID"),
         -- postal_cd,
          parent_wifi
      FROM
      (SELECT
          DISTINCT 
          ci.parent_entity_number AS "ID",
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi
      FROM 
          fy2016.connectivity_informations ci,
          public.entity_bens eb_parent,
          public.fy2016_districts_demog_matr ddm,
          public.fy2016_districts_deluxe_matr dd
      WHERE
          ci.parent_entity_number = eb_parent.ben AND
          eb_parent.entity_id = ddm.esh_id::text::INT AND
          dd.esh_id = ddm.esh_id AND
          ci.parent_wifi IS NOT NULL  AND
          dd.include_in_universe_of_districts = TRUE
          
      GROUP BY
          ci.parent_entity_number,
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi,
          ci.child_entity_name,
          ci.child_wifi
      UNION
      SELECT
          DISTINCT 
          ci.child_entity_number AS "ID",
          ci.postal_cd,
          ci.child_entity_name,
          ci.child_wifi
      FROM 
          fy2016.connectivity_informations ci,
          public.entity_bens eb_parent,
          public.fy2016_districts_demog_matr ddm,
          public.fy2016_districts_deluxe_matr dd
      WHERE
          ci.parent_entity_number = eb_parent.ben AND
          eb_parent.entity_id = ddm.esh_id::text::INT AND
          dd.esh_id = ddm.esh_id AND
          ci.parent_wifi IS NULL AND
          dd.include_in_universe_of_districts = TRUE
      GROUP BY
          ci.child_entity_number,    
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi,
          ci.child_entity_name,
          ci.child_wifi) answers
      GROUP BY
      parent_wifi),
current_16_agg as (select
      2016 as year,
      sum(case
        when (current_16.parent_wifi = 'Sometimes'  or current_16.parent_wifi = 'Never')
        then current_16.count 
        end)/
      sum(case
        when (current_16.parent_wifi = 'Sometimes'  or current_16.parent_wifi = 'Never'
          or current_16.parent_wifi = 'Completely' or current_16.parent_wifi = 'Mostly')
        then current_16.count
        end)
      as percent_schools_insuff
      from current_16
),
current_16_s as (
  select 
  2016 as year,
  sum(num_schools) as total_schools
  from public.fy2016_districts_deluxe_matr
  where include_in_universe_of_districts = true
  and district_type = 'Traditional'),
current_17 as (SELECT
          COUNT("ID"),
         -- postal_cd,
          parent_wifi
      FROM
      (SELECT
          DISTINCT 
          ci.parent_entity_number AS "ID",
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi
      FROM 
          fy2017.connectivity_informations ci,
          public.entity_bens eb_parent,
          public.fy2017_districts_demog_matr ddm,
          public.fy2017_districts_deluxe_matr dd
      WHERE
          ci.parent_entity_number = eb_parent.ben AND
          eb_parent.entity_id = ddm.esh_id::text::INT AND
          dd.esh_id = ddm.esh_id AND
          ci.parent_wifi IS NOT NULL  AND
          dd.include_in_universe_of_districts = TRUE
          
      GROUP BY
          ci.parent_entity_number,
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi,
          ci.child_entity_name,
          ci.child_wifi
      UNION
      SELECT
          DISTINCT 
          ci.child_entity_number AS "ID",
          ci.postal_cd,
          ci.child_entity_name,
          ci.child_wifi
      FROM 
          fy2017.connectivity_informations ci,
          public.entity_bens eb_parent,
          public.fy2017_districts_demog_matr ddm,
          public.fy2017_districts_deluxe_matr dd
      WHERE
          ci.parent_entity_number = eb_parent.ben AND
          eb_parent.entity_id = ddm.esh_id::text::INT AND
          dd.esh_id = ddm.esh_id AND
          ci.parent_wifi IS NULL AND
          dd.include_in_universe_of_districts = TRUE
      GROUP BY
          ci.child_entity_number,    
          ci.postal_cd,
          ci.parent_entity_name,
          ci.parent_wifi,
          ci.child_entity_name,
          ci.child_wifi) answers
      GROUP BY
      parent_wifi),
current_17_agg as (select
      2017 as year, 
      sum(case
        when (current_17.parent_wifi = 'Sometimes'  or current_17.parent_wifi = 'Never')
        then current_17.count 
        end)/
      sum(case
        when (current_17.parent_wifi = 'Sometimes'  or current_17.parent_wifi = 'Never'
          or current_17.parent_wifi = 'Completely' or current_17.parent_wifi = 'Mostly')
        then current_17.count
        end)
      as percent_schools_insuff
      from current_17
),
current_17_s as (select 2017 as year,
  sum(num_schools) as total_schools
  from public.fy2017_districts_deluxe_matr
  where include_in_universe_of_districts = true
  and district_type = 'Traditional')

select 'SotS 2013' as year,
  .25 as percent_schools_sufficient,
  null as num_schools_insufficient

  from public.fy2016_districts_deluxe_matr

  union

  select 'SotS 2015' as year,
  .64 as percent_schools_sufficient,
  31959 as num_schools_insufficient

  from public.fy2016_districts_deluxe_matr

  union

  select 'SotS 2016' as year,
  .83 as percent_schools_sufficient,
  15092 as num_schools_insufficient

  union

  select 'Current 2016' as year,
  (1-percent_schools_insuff) as percent_schools_sufficient,
  (percent_schools_insuff*total_schools)
  as num_schools_insufficient

  from current_16_agg
  join current_16_s
  on current_16_s.year = current_16_agg.year

union

  select 'Current 2017' as year,
  (1-percent_schools_insuff) as percent_schools_sufficient,
  (percent_schools_insuff*total_schools)
  as num_schools_insufficient

  from current_17_agg
  join current_17_s
  on current_17_s.year = current_17_agg.year