select d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        sc131a."LEAID" as nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        sc131a."LSTREE" as address,
        sc131a."LCITY" as city,
        sc131a."LZIP" as zip,
        sc131a."LSTATE" as postal_cd,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric <= 0 then sc131a."MEMBER"::numeric
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."MEMBER"::numeric - sc131a."PK"::numeric
            else 0
        end as num_students,
        case
          when left(sc131a."ULOCAL",1) = '1' then 'Urban'
          when left(sc131a."ULOCAL",1) = '2' then 'Suburban'
          when left(sc131a."ULOCAL",1) = '3' then 'Town'
          when left(sc131a."ULOCAL",1) = '4' then 'Rural'
            else 'Unknown'
        end as locale,
        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,
        case
          when "TOTFRL"::numeric>0 and sc131a."MEMBER"::numeric > 0
            then sc131a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        ds.campus_id

from public.sc131a
join (select *
      from fy2016_districts_demog
      where postal_cd not in ('MT', 'VT')) d
on sc131a."LEAID" = d.nces_cd
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join ( select distinct school_id, campus_id
            from fy2016.districts_schools ) ds
on eim.entity_id = ds.school_id
left join (
  select distinct flaggable_id
  from fy2016.flags
  where label in ('closed_school', 'non_school', 'charter_school')
  and status = 'open'
) t
on eim.entity_id = t.flaggable_id
where flaggable_id is null

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        sc131a."LSTREE" as address,
        sc131a."LCITY" as city,
        sc131a."LZIP" as zip,
        sc131a."LSTATE" as postal_cd,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric <= 0 then sc131a."MEMBER"::numeric
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."MEMBER"::numeric - sc131a."PK"::numeric
            else 0
        end as num_students,
        case
          when left(sc131a."ULOCAL",1) = '1' then 'Urban'
          when left(sc131a."ULOCAL",1) = '2' then 'Suburban'
          when left(sc131a."ULOCAL",1) = '3' then 'Town'
          when left(sc131a."ULOCAL",1) = '4' then 'Rural'
            else 'Unknown'
        end as locale,
        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,
        case
          when "TOTFRL"::numeric>0 and sc131a."MEMBER"::numeric > 0
            then sc131a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        ds.campus_id

from public.sc131a
join public.ag131a
on sc131a."LEAID" = ag131a."LEAID"
join (select *
      from fy2016_districts_demog
      where postal_cd = 'MT') d
on ag131a."LSTREE" = d.address
and sc131a."LSTATE" = d.postal_cd
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join ( select distinct school_id, campus_id
            from fy2016.districts_schools ) ds
on eim.entity_id = ds.school_id
left join (
  select distinct flaggable_id
  from fy2016.flags
  where label in ('closed_school', 'non_school', 'charter_school')
  and status = 'open'
) t
on eim.entity_id = t.flaggable_id
where flaggable_id is null

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        sc131a."LSTREE" as address,
        sc131a."LCITY" as city,
        sc131a."LZIP" as zip,
        sc131a."LSTATE" as postal_cd,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric <= 0 then sc131a."MEMBER"::numeric
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."MEMBER"::numeric - sc131a."PK"::numeric
            else 0
        end as num_students,
        case
          when left(sc131a."ULOCAL",1) = '1' then 'Urban'
          when left(sc131a."ULOCAL",1) = '2' then 'Suburban'
          when left(sc131a."ULOCAL",1) = '3' then 'Town'
          when left(sc131a."ULOCAL",1) = '4' then 'Rural'
            else 'Unknown'
        end as locale,
        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,
        case
          when "TOTFRL"::numeric>0 and sc131a."MEMBER"::numeric > 0
            then sc131a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        ds.campus_id

from public.sc131a
join (select *
      from fy2016_districts_demog
      where postal_cd = 'VT') d
on sc131a."UNION" = d.union_code
and sc131a."LSTATE" = d.postal_cd
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join ( select distinct school_id, campus_id
            from fy2016.districts_schools ) ds
on eim.entity_id = ds.school_id
left join (
  select distinct flaggable_id
  from fy2016.flags
  where label in ('closed_school', 'non_school', 'charter_school')
  and status = 'open'
) t
on eim.entity_id = t.flaggable_id
where flaggable_id is null

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 9/23/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Schools demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be created.
*/