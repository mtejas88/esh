select d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        sc131a."LEAID" as nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
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
        ds.campus_id,
        case
          when applicant_id is not null and sc131a."CHARTR" = '1' 
            then true
          else false
        end as self_procuring_charter

from public.sc131a 
join (select *
      from fy2016_districts_demog
      where postal_cd not in ('MT', 'VT')) d --only want schools in districts universe
on sc131a."LEAID" = d.nces_cd
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join fy2016.districts_schools ds
on eim.entity_id = ds.school_id
left join (
  select distinct taggable_id, label
  from fy2016.tags
  where label = 'closed_school'
  and deleted_at is null
) t
on eim.entity_id = t.taggable_id
left join (
  select distinct applicant_id
  from fy2016.line_items
  where broadband = true
) applicants
on eim.entity_id = applicants.applicant_id
where label is null
and sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4')

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
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
        ds.campus_id,
        case
          when applicant_id is not null and sc131a."CHARTR" = '1' 
            then true
          else false
        end as self_procuring_charter

from public.sc131a 
join public.ag131a
on sc131a."LEAID" = ag131a."LEAID"
join (select *
      from fy2016_districts_demog
      where postal_cd = 'MT') d --only want schools in districts universe
on ag131a."LSTREE" = d.address
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join fy2016.districts_schools ds
on eim.entity_id = ds.school_id
left join (
  select distinct taggable_id, label
  from fy2016.tags
  where label = 'closed_school'
  and deleted_at is null
) t
on eim.entity_id = t.taggable_id
left join (
  select distinct applicant_id
  from fy2016.line_items
  where broadband = true
) applicants
on eim.entity_id = applicants.applicant_id
where label is null
and sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4')
and sc131a."LSTATE" = 'MT'

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        sc131a."SCHNAM" as name,
        case
          when sc131a."CHARTR" = '1' then 'Charter'
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
        ds.campus_id,
        case
          when applicant_id is not null and sc131a."CHARTR" = '1' 
            then true
          else false
        end as self_procuring_charter
        
from public.sc131a 
join (select *
      from fy2016_districts_demog
      where postal_cd = 'VT') d
on sc131a."UNION" = d.union_code
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
left join fy2016.districts_schools ds
on eim.entity_id = ds.school_id
left join (
  select distinct taggable_id, label
  from fy2016.tags
  where label = 'closed_school'
  and deleted_at is null
) t
on eim.entity_id = t.taggable_id
left join (
  select distinct applicant_id
  from fy2016.line_items
  where broadband = true
) applicants
on eim.entity_id = applicants.applicant_id
where label is null
and sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4')
and sc131a."LSTATE" = 'VT'

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 9/06/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Schools demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be created.
*/