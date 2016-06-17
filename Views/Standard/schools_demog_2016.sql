 select d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        sc131a."LEAID" as nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        case when sc131a."TYPE" = '1' then 1 end as school_type_1_indicator,
        case
          when sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
            else 0
        end as student_count,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
            else 0
        end as student_pk_count
from public.sc131a 
join (select *
      from districts_demog_2016
      where postal_cd not in ('MT', 'VT')) d --only want schools in districts universe
on ag131a."LEAID" = d.nces_cd
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
where sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4') --research is still outstanding to determine if type 4 schools should be included; 5's were decidedly excluded

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        case when sc131a."TYPE" = '1' then 1 end as school_type_1_indicator,
        case
          when sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
            else 0
        end as student_count,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
            else 0
        end as student_pk_count
from public.sc131a 
join public.ag131a
on sc131a."LEAID" = ag131a."LEAID"
join (select *
      from districts_demog_2016
      where postal_cd = 'MT') d --only want schools in districts universe
on ag131a."LSTREE" = d.address
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
where sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4') --research is still outstanding to determine if type 4 schools should be included; 5's were decidedly excludeda

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd,
        sc131a."NCESSCH" as school_nces_code,
        case when sc131a."TYPE" = '1' then 1 end as school_type_1_indicator,
        case
          when sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
            else 0
        end as student_count,
        case
          when sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
            else 0
        end as student_pk_count
from public.sc131a 
join (select *
      from districts_demog_2016
      where postal_cd = 'VT') d
on sc131a."UNION" = d.union_code
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on sc131a."NCESSCH" = eim.nces_code
where sc131a."GSHI" != 'PK' 
and sc131a."STATUS" != '2' --closed schools
and sc131a."VIRTUALSTAT" != 'VIRTUALYES'
and sc131a."TYPE" in ('1','2','3','4') --research is still outstanding to determine if type 4 schools should be included; 5's were decidedly excludeda
