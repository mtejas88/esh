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
    --and f.charter__c = true
    --and (f.charter__c = false or a.type = 'Charter')

),

charters_in_districts as (

  select distinct d.esh_id,
  s.school_esh_id,
  s.school_type
  
  from schools_demog_adj s
  
  join public.fy2017_districts_deluxe_matr d
  on s.district_esh_id = d.esh_id
  and d.include_in_universe_of_districts = true
  and d.district_type = 'Traditional'

),

district_lookup_adj as (
  select 
    esh_id as district_esh_id,
    school_esh_id as esh_id,
    school_type

  from charters_in_districts
  
  union
  
  select 
    esh_id as district_esh_id,
    esh_id as esh_id,
    'District' as school_type
    
  from public.fy2017_districts_demog_matr 
),

lines_to_districts as (

  select distinct a.line_item_id,
  dl.*,
  t.open_tags,
  f.open_flags
  
  from public.esh_line_items li
  
  join public.esh_allocations a
  on li.id = a.line_item_id
  
  left join (
    select 
      taggable_id,
      array_agg(label) as open_tags
    from public.tags 
    where funding_year = 2017
    and deleted_at is null
    and taggable_type = 'LineItem'
    group by 1
  ) t
  on li.id = t.taggable_id
  
  left join (
    select 
      flaggable_id,
      array_agg(label) as open_flags
    from public.flags 
    where funding_year = 2017
    and status = 'open'
    and flaggable_type = 'LineItem'
    group by 1
  ) f
  on li.id = f.flaggable_id
  
  left join public.entity_bens eb
  on a.recipient_ben = eb.ben
  
  join district_lookup_adj dl
  on eb.entity_id::varchar = dl.esh_id
  
  join public.fy2017_districts_deluxe_matr d
  on dl.district_esh_id = d.esh_id
  and d.district_type = 'Traditional'
  and d.include_in_universe_of_districts = true
  
  where li.funding_year = 2017
  and li.broadband = true
  and (li.upstream_conditions_met = true or li.internet_conditions_met = true or li.wan_conditions_met = true)
  --and the line item is not excluded or charter service
  and (not('charter_service' = any(t.open_tags)) or
       t.open_tags is null)
  and (not('exclude' = any(f.open_flags)) or 
       f.open_flags is null)
  and a.num_lines_to_allocate is not null
  and a.num_lines_to_allocate > 0

)


select 
  line_item_id,
  district_esh_id,
  count(case when school_type = 'Charter' then esh_id end) as num_charter_recips,
  count(case when school_type != 'Charter' then esh_id end) as num_non_charter_recips

from lines_to_districts

group by 1,2
  
having count(case when school_type = 'Charter' then esh_id end) > 0
and (count(case when school_type != 'Charter' then esh_id end) is null
  or count(case when school_type != 'Charter' then esh_id end) = 0)