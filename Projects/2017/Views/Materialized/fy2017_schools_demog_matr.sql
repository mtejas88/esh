select d.esh_id as district_esh_id,

        case

          when eim.entity_id is null then 'Unknown'

            else eim.entity_id::varchar

        end as school_esh_id,

        sc141a."LEAID" as nces_cd,

        sc141a."NCESSCH" as school_nces_code,

        d.include_in_universe_of_districts as district_include_in_universe_of_districts,

        sc141a."SCHNAM" as name,

        case

          when sc141a."CHARTR" = '1' then 'Charter'

          when d.district_type = 'Other Agency'

            then 'Other School'

          else 'Traditional'

        end as school_type,

        sc141a."LSTREET1" as address,

        sc141a."LCITY" as city,

        sc141a."LZIP" as zip,

        sc141a."LSTATE" as postal_cd,

        case

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric <= 0 then sc141a."MEMBER"::numeric

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric > 0 then sc141a."MEMBER"::numeric - sc141a."PK"::numeric

            else 0

        end as num_students,

        case

          when left(sc141a."ULOCAL",1) = '1' then 'Urban'

          when left(sc141a."ULOCAL",1) = '2' then 'Suburban'

          when left(sc141a."ULOCAL",1) = '3' then 'Town'

          when left(sc141a."ULOCAL",1) = '4' then 'Rural'

            else 'Unknown'

        end as locale,

        case

          when "TOTFRL"::numeric>0

            then "TOTFRL"::numeric

        end as frl_percentage_numerator,

        case

          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0

            then sc141a."MEMBER"::numeric

        end as frl_percentage_denomenator,

        ds.campus_id




from public.sc141a

join (select *

      from public.fy2017_districts_demog_matr /*ag141a*/

      where postal_cd not in ('MT', 'VT')

      and esh_id != '946654') d

on sc141a."LEAID" = d.nces_cd

left join ( select distinct entity_id, nces_code

            from public.entity_nces_codes) eim

on sc141a."NCESSCH" = eim.nces_code

left join ( select distinct esh_id__c, esh_id__c as campus_id

            from salesforce.facilities__c ) ds --per Meghan, campus id will be added to this table

on eim.entity_id = ds.esh_id__c

left join (

  select distinct flaggable_id

  from public.flags --using public flags with funding year filter

  where label in ('closed_school', 'non_school', 'charter_school')

  and status = 'open'
  and funding_year = 2017 --per engineering, funding year is integer data type in all tables

) t

on eim.entity_id = t.flaggable_id

where flaggable_id is null




UNION




select  d.esh_id as district_esh_id,

        case

          when eim.entity_id is null then ‘Unknown’

            else eim.entity_id::varchar

        end as school_esh_id,

        d.nces_cd,

        sc141a."NCESSCH" as school_nces_code,

        d.include_in_universe_of_districts as district_include_in_universe_of_districts,

        sc141a."SCHNAM" as name,

        case

          when sc141a."CHARTR" = '1' then 'Charter'

          when d.district_type = 'Other Agency'

            then 'Other School'

          else 'Traditional'

        end as school_type,

        sc141a."LSTREET1" as address,

        sc141a."LCITY" as city,

        sc141a."LZIP" as zip,

        sc141a."LSTATE" as postal_cd,

        case

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric <= 0 then sc141a."MEMBER"::numeric

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric > 0 then sc141a."MEMBER"::numeric - sc141a."PK"::numeric

            else 0

        end as num_students,

        case

          when left(sc141a."ULOCAL",1) = '1' then 'Urban'

          when left(sc141a."ULOCAL",1) = '2' then 'Suburban'

          when left(sc141a."ULOCAL",1) = '3' then 'Town'

          when left(sc141a."ULOCAL",1) = '4' then 'Rural'

            else 'Unknown'

        end as locale,

        case

          when "TOTFRL"::numeric>0

            then "TOTFRL"::numeric

        end as frl_percentage_numerator,

        case

          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0

            then sc141a."MEMBER"::numeric

        end as frl_percentage_denomenator,

        ds.campus_id




from public.sc141a

join public.ag141a

on sc141a."LEAID" = ag141a."LEAID"

join (select *

      from public.fy2017_districts_demog_matr

      where postal_cd = 'MT') d

on ag141a."LSTREET1" = d.address

and sc141a."LSTATE" = d.postal_cd

left join ( select distinct entity_id, nces_code

            from public.entity_nces_codes) eim

on sc141a."NCESSCH" = eim.nces_code

left join ( select distinct esh_id__c, esh_id__c as campus_id

            from salesforce.facilities__c) ds --assuming the campus ids will be added to this table, per discussion with Meghan at 4:30 pm on May 9, 2017
on eim.entity_id = ds.esh_id__c

left join (

  select distinct flaggable_id

  from public.flags --using public flags with funding year filter

  where label in ('closed_school', 'non_school', 'charter_school')

  and status = 'open'
  and funding_year = 2017

) t

on eim.entity_id = t.flaggable_id

where flaggable_id is null




UNION




select  d.esh_id as district_esh_id,

        case

          when eim.entity_id is null then 'Unknown '

            else eim.entity_id::varchar

        end as school_esh_id,

        d.nces_cd,

        sc141a."NCESSCH" as school_nces_code,

        d.include_in_universe_of_districts as district_include_in_universe_of_districts,

        sc141a."SCHNAM" as name,

        case

          when sc141a."CHARTR" = '1' then 'Charter'

          when d.district_type = 'Other Agency'

            then 'Other School'

          else 'Traditional'

        end as school_type,

        sc141a."LSTREET1" as address,

        sc141a."LCITY" as city,

        sc141a."LZIP" as zip,

        sc141a."LSTATE" as postal_cd,

        case

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric <= 0 then sc141a."MEMBER"::numeric

          when sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric > 0 then sc141a."MEMBER"::numeric - sc141a."PK"::numeric

            else 0

        end as num_students,

        case

          when left(sc141a."ULOCAL",1) = '1' then 'Urban'

          when left(sc141a."ULOCAL",1) = '2' then 'Suburban'

          when left(sc141a."ULOCAL",1) = '3' then 'Town'

          when left(sc141a."ULOCAL",1) = '4' then 'Rural'

            else 'Unknown'

        end as locale,

        case

          when "TOTFRL"::numeric>0

            then "TOTFRL"::numeric

        end as frl_percentage_numerator,

        case

          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0

            then sc141a."MEMBER"::numeric

        end as frl_percentage_denomenator,

        ds.campus_id




from public.sc141a

join (select *

      from public.fy2017_districts_demog_matr

      where postal_cd = 'VT') d

on sc141a."UNION" = d.union_code

and sc141a."LSTATE" = d.postal_cd

left join ( select distinct entity_id, nces_code

            from public.entity_nces_codes) eim

on sc141a."NCESSCH" = eim.nces_code

left join ( select distinct esh_id__c, esh_id__c as campus_id

            from salesforce.facilities__c ) ds
--per discussion with Meghan at 4:30 pm on May 9, 2017, the campus id field will be added to salesforce.facilities__c table


on eim.entity_id = ds.esh_id__c

left join (

  select distinct flaggable_id

  from public.flags --using public flags with funding year filter

  where label in ('closed_school', 'non_school', 'charter_school')

  and status = 'open'
  and funding_year = 2017

) t

on eim.entity_id = t.flaggable_id

where flaggable_id is null




UNION




select  d.esh_id as district_esh_id,

        case

          when eim.entity_id is null then 'Unknown'

            else eim.entity_id::varchar

        end as school_esh_id,

        d.nces_cd,

        sc141af."NCESSCH" as school_nces_code,

        d.include_in_universe_of_districts as district_include_in_universe_of_districts,

       sc141af."SCHNAM" as name,

        case

          when sc141af."CHARTR" = '1' then 'Charter'

          when d.district_type = 'Other Agency'

            then 'Other School'

          else 'Traditional'

        end as school_type,

         sc141af."LSTREET1" as address,

         sc141af."LCITY" as city,

         sc141af."LZIP" as zip,

         sc141af."LSTATE" as postal_cd,

        case

          when sc141af."MEMBER"::numeric > 0 and sc141af."PK"::numeric <= 0 then sc141af."MEMBER"::numeric

          when sc141af."MEMBER"::numeric > 0 and sc141af."PK"::numeric > 0 then sc141af."MEMBER"::numeric - sc141af."PK"::numeric

            else 0

        end as num_students,

        case

          when left(sc141af."ULOCAL",1) = '1' then 'Urban'

          when left(sc141af."ULOCAL",1) = '2' then 'Suburban'

          when left(sc141af."ULOCAL",1) = '3' then 'Town'

          when left(sc141af."ULOCAL",1) = '4' then 'Rural'

            else 'Unknown'

        end as locale,

        case

          when "TOTFRL"::numeric>0

            then "TOTFRL"::numeric

        end as frl_percentage_numerator,

        case

          when "TOTFRL"::numeric>0 and sc141af."MEMBER"::numeric > 0

            then sc141af."MEMBER"::numeric

        end as frl_percentage_denomenator,

        ds.campus_id




from (

  select sc141a.*

  from public.sc141a

  left join public.ag141a

  on sc141a."LEAID" = ag141a."LEAID"

  where ag141a."LSTATE" = 'NY'

  and ( ag141a."NAME" ilike '%geographic%'

        or ag141a."LEAID" = '3620580')

) sc141af

left join (select *

      from public.fy2017_districts_demog_matr

      where esh_id = '946654') d

on sc141af."LSTATE" = d.postal_cd

left join ( select distinct entity_id, nces_code

            from public.entity_nces_codes) eim

on sc141af."NCESSCH" = eim.nces_code

left join ( select distinct esh_id__c, esh_id__c as campus_id

            from salesforce.facilities__c) ds --per Meghan, campus id will be added to this table

on eim.entity_id = ds.esh_id__c

left join (

  select distinct flaggable_id

  from public.flags --using public flags with funding year filter

  where label in ('closed_school', 'non_school', 'charter_school')

  and status = 'open'
  and funding_year = 2017

) t

on eim.entity_id = t.flaggable_id

where flaggable_id is null




/*

Author: Justine Schott

Created On Date: 6/20/2016

Last Modified Date: 10/26/2016

Name of QAing Analyst(s): Greg Kurzhals

Purpose: Schools demographics of those in the universe

Methodology: Smushing by UNION for VT and district LSTREET1T for MT. Otherwise, metrics taken mostly from NCES. Done before

metrics aggregation so school-district association can be created.

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
usage of public.flags with funding year
district_schools vs salesforce.facilities__c don’t match
*/