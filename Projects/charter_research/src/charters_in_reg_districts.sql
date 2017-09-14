with schools_demog_adj as (

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
          f.num_students__c::integer as num_students,
          
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
        from public.fy2017_districts_demog_matr) d
  on d.esh_id = a.esh_id__c::varchar
  
  where eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */ 
    and a.recordtypeid = '012E0000000NE6DIAW'
    and a.out_of_business__c = false
    and f.recordtypeid = '01244000000DHd0AAG'
    and f.out_of_business__c = false
    and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
    and f.charter__c = true
    --and (f.charter__c = false or a.type = 'Charter')

)

select distinct s.school_esh_id

from schools_demog_adj s

join public.fy2017_districts_deluxe_matr d
on s.district_esh_id = d.esh_id
and d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'

where s.school_type = 'Charter'
