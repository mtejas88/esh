select d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as school_esh_id,
        sc141a."LEAID" as nces_cd,
        sc141a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        f.name as name,
        f.street__c as address,
        f.city__c as city,
        d.postal_cd as postal_cd,
        left(f.zip_code__c, 5) as zip,
        f.num_students__c as num_students,
        
        case 
          when f.locale__c is null
            then 'Unknown'
          when f.locale__c = 'Small Town'
            then 'Town'
          else f.locale__c
        end as locale,

        case
          when f.charter__c = true then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        

        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,

        case
          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0
            then sc141a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        
        f.campus__c as campus_id

from salesforce.facilities__c f

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on f.esh_id__c = eim.entity_id::varchar

left join public.sc141a
on sc141a."NCESSCH" = eim.nces_code

left join salesforce.account a
on a.sfid = f.account__c

join (select *
      from public.fy2017_districts_demog_matr /*ag141a*/
      where postal_cd not in ('MT', 'VT')
      and esh_id != '946654') d
on sc141a."LEAID" = d.nces_cd

where eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */ 
  and a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter')

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd as nces_cd,
        sc141a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        f.name as name,
        f.street__c as address,
        f.city__c as city,
        d.postal_cd as postal_cd,
        left(f.zip_code__c, 5) as zip,
        f.num_students__c as num_students,
        
        case 
          when f.locale__c is null
            then 'Unknown'
          when f.locale__c = 'Small Town'
            then 'Town'
          else f.locale__c
        end as locale,

        case
          when f.charter__c = true then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        

        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,

        case
          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0
            then sc141a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        
        f.campus__c as campus_id

from salesforce.facilities__c f

left join salesforce.account a
on a.sfid = f.account__c

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on f.esh_id__c = eim.entity_id::varchar

left join public.sc141a
on sc141a."NCESSCH" = eim.nces_code

join public.ag141a
on sc141a."LEAID" = ag141a."LEAID"

join (select *
      from public.fy2017_districts_demog_matr
      where postal_cd = 'MT') d
on ag141a."LSTREET1" = d.address
and sc141a."LSTATE" = d.postal_cd

where eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */ 
  and a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter')

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd as nces_cd,
        sc141a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        f.name as name,
        f.street__c as address,
        f.city__c as city,
        d.postal_cd as postal_cd,
        left(f.zip_code__c, 5) as zip,
        f.num_students__c as num_students,
        
        case 
          when f.locale__c is null
            then 'Unknown'
          when f.locale__c = 'Small Town'
            then 'Town'
          else f.locale__c
        end as locale,

        case
          when f.charter__c = true then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        

        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,

        case
          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0
            then sc141a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        
        f.campus__c as campus_id

from salesforce.facilities__c f

left join salesforce.account a
on a.sfid = f.account__c

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on f.esh_id__c = eim.entity_id::varchar

left join public.sc141a
on sc141a."NCESSCH" = eim.nces_code

join (select *
      from public.fy2017_districts_demog_matr
      where postal_cd = 'VT') d
on sc141a."UNION" = d.union_code
and sc141a."LSTATE" = d.postal_cd

where eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */ 
  and a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter')

UNION

select  d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as school_esh_id,
        d.nces_cd as nces_cd,
        sc141af."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        f.name as name,
        f.street__c as address,
        f.city__c as city,
        d.postal_cd as postal_cd,
        left(f.zip_code__c, 5) as zip,
        f.num_students__c as num_students,
        case 
          when f.locale__c is null
            then 'Unknown'
          when f.locale__c = 'Small Town'
            then 'Town'
          else f.locale__c
        end as locale,
        case
          when f.charter__c = true then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,
        case
          when "TOTFRL"::numeric>0 and sc141af."MEMBER"::numeric > 0
            then sc141af."MEMBER"::numeric
        end as frl_percentage_denomenator,
        f.campus__c as campus_id

from salesforce.facilities__c f

left join salesforce.account a
on a.sfid = f.account__c

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on f.esh_id__c = eim.entity_id::varchar

join (
  select sc141a.*
  from public.sc141a
  left join public.ag141a
  on sc141a."LEAID" = ag141a."LEAID"
  where ag141a."LSTATE" = 'NY'
  and ( ag141a."NAME" ilike '%geographic%'
        or ag141a."LEAID" = '3620580')
) sc141af
on sc141af."NCESSCH" = eim.nces_code

left join (select *
      from public.fy2017_districts_demog_matr
      where esh_id = '946654') d
on sc141af."LSTATE" = d.postal_cd

where d.esh_id = '946654'
  and a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter')

/*
Author: Justine Schott
Created On Date: 6/20/2016
Modified Date: 7/7/2017
Name of Modifier: Jeremy - updated demogs to be from salesforce
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
usage of public.flags with funding year
*/