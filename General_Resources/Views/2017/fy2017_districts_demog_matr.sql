select  case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as esh_id,
        d."LEAID" as nces_cd,
        a.name as name,
        case
          when a.type in ('Public')
            then 'Traditional'
          when a.type = 'Charter'
            then 'Charter'
          when a.type in ('Bureau of Indian Education' ,'Tribal')
            then 'BIE'
          else 'Other Agency'
        end as district_type,
        a.billingstreet as address,
        a.billingcity as city,
        d."CONAME" as county,
        left(billingpostalcode, 5) as zip,
        a.billingstatecode as postal_cd,
        a.billinglatitude as latitude,
        a.billinglongitude as longitude,
        case 
          when sf.num_students is null
            then 0
          else sf.num_students
        end as num_students,
        /* OLD STUDENT COUNT METHOD
        case
          when a.billingstatecode = 'VT' then case
                                        when sc_VT.student_count - sc_VT.student_pk_count is null
                                          then 0
                                        else sc_VT.student_count - sc_VT.student_pk_count
                                      end
          when a.billingstatecode = 'MT' then case
                                        when sc_MT.student_count - sc_MT.student_pk_count is null
                                          then 0
                                        else sc_MT.student_count - sc_MT.student_pk_count
                                      end
          when eim.entity_id = '946654' then case
                                        when sc_NY.student_count - sc_NY.student_pk_count is null
                                          then 0
                                        else sc_NY.student_count - sc_NY.student_pk_count
                                      end
            else  case
                    when sc.student_count - sc.student_pk_count is null
                      then 0
                    else sc.student_count - sc.student_pk_count
                  end
        end as num_students,
        */
        case 
          when sf.num_schools is null
            then 0
          else sf.num_schools
        end as num_schools,
        "ULOCAL" as ulocal,
        case 
          when a.locale__c is null
            then 'Unknown'
          when a.locale__c = 'Small Town'
            then 'Town'
          else a.locale__c
        end as locale,
        case
          when sf.num_schools=1 then 'Tiny'
          when sf.num_schools>1 and sf.num_schools<=5 then 'Small'
          when sf.num_schools>5 and sf.num_schools<=15 then 'Medium'
          when sf.num_schools>15 and sf.num_schools <= 50 then 'Large'
          when sf.num_schools>50 then 'Mega'
          else 'Unknown'
        end as district_size,
        d."UNION" as union_code,
        case
          when sf.include_in_universe_of_districts is null
            then false
          else sf.include_in_universe_of_districts
        end as include_in_universe_of_districts,
        case 
          when sf.include_in_universe_of_districts_all_charters is null
            then false
          else sf.include_in_universe_of_districts_all_charters
        end as include_in_universe_of_districts_all_charters,
        case
          when a.billingstatecode = 'VT' then stf_VT.num_teachers
          when a.billingstatecode = 'MT' then stf_MT.num_teachers
          when eim.entity_id = '946654' then stf_NY.num_teachers
            else  case when "KGTCH" < 0 then 0 else "KGTCH" end
                + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                + case when "SECTCH" < 0 then 0 else "SECTCH" end
                + case when "UGTCH" < 0 then 0 else "UGTCH" end
        end as num_teachers,
        case
          when a.billingstatecode = 'VT' then stf_VT.num_aides
          when a.billingstatecode = 'MT' then stf_MT.num_aides
          when eim.entity_id = '946654' then stf_NY.num_aides
            else  case when "AIDES" < 0 then 0 else "AIDES" end
        end as num_aides,
        case
          when a.billingstatecode = 'VT' then stf_VT.num_other_staff
          when a.billingstatecode = 'MT' then stf_MT.num_other_staff
          when eim.entity_id = '946654' then stf_NY.num_other_staff
            else  case when "CORSUP" < 0 then 0 else "CORSUP" end
                + case when "ELMGUI" < 0 then 0 else "ELMGUI" end
                + case when "SECGUI" < 0 then 0 else "SECGUI" end
                + case when "OTHGUI" < 0 then 0 else "OTHGUI" end
                + case when "TOTGUI" < 0 then 0 else "TOTGUI" end
                + case when "LIBSPE" < 0 then 0 else "LIBSPE" end
                + case when "LIBSUP" < 0 then 0 else "LIBSUP" end
                + case when "LEAADM" < 0 then 0 else "LEAADM" end
                + case when "LEASUP" < 0 then 0 else "LEASUP" end
                + case when "SCHADM" < 0 then 0 else "SCHADM" end
                + case when "SCHSUP" < 0 then 0 else "SCHSUP" end
                + case when "STUSUP" < 0 then 0 else "STUSUP" end
                + case when "OTHSUP" < 0 then 0 else "OTHSUP" end
        end as num_other_staff

from salesforce.account a

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on a.esh_id__c = eim.entity_id::varchar

left join public.ag141a d
on RPAD(d."LEAID",12,'0')=eim.nces_code

left join (
  select 
    a.esh_id__c as district_esh_id,
    count(f.esh_id__c) as num_schools,
    sum(f.num_students__c) as num_students,
    case
      when count(f.esh_id__c) > 0
       and sum(f.num_students__c) > 0
       and count(distinct f.campus__c) > 0
       and (a.type != 'Charter' or a.billingstatecode = 'AZ')
        then true
      else false
    end as include_in_universe_of_districts,
    case
      when count(f.esh_id__c) > 0
       and sum(f.num_students__c) > 0
       and count(distinct f.campus__c) > 0
        then true
      else false
    end as include_in_universe_of_districts_all_charters

  from salesforce.account a

  left join salesforce.facilities__c f
  on a.sfid = f.account__c

  where a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter')


  group by 
    a.esh_id__c,
    a.type,
    a.billingstatecode
) sf
on a.esh_id__c = sf.district_esh_id

/*
--OLD SCHOOL METHOD
left join ( select  "LEAID",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and "TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or closed_school_count = removed_school_count)
                                and "MEMBER"::numeric > 0 then "MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or closed_school_count = removed_school_count)
                                and "MEMBER"::numeric > 0 and "PK"::numeric > 0 then "PK"::numeric
                            else 0
                        end) as student_pk_count
            from public.sc141a
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc141a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as closed_school_count,
                      count(*) as removed_school_count
              from public.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
  and funding_year = 2017 --adding funding year filter for public flags
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            group by "LEAID" ) sc
on d."LEAID"=sc."LEAID"


left join ( select  "UNION",
                    "LSTATE",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and "TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or include_students > 0)
                                and "MEMBER"::numeric > 0 then "MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or include_students > 0)
                                and "MEMBER"::numeric > 0 and "PK"::numeric > 0 then "PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct  case
                                      when flaggable_id is null
                                        then sc141a."LEAID"
                                    end) as district_count
            from public.sc141a
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc141a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from public.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
  and funding_year = 2017 --adding funding year filter for public flags
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where "LSTATE" = 'VT' --only smushing by UNION for districts in VT
            group by  "UNION",
                      "LSTATE" ) sc_VT
on d."UNION"=sc_VT."UNION"
and a.billingstatecode=sc_VT."LSTATE"

left join ( select  ag141a."LSTREET1",
                    ag141a."LCITY",
                    ag141a."LSTATE",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and sc141a."TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or include_students > 0)
                                and sc141a."MEMBER"::numeric > 0 then sc141a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or include_students > 0)
                                and sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric > 0 then sc141a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct  case
                                      when flaggable_id is null
                                        then sc141a."LEAID"
                                    end) as district_count
            from public.sc141a
            left join ag141a
            on sc141a."LEAID" = ag141a."LEAID"
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc141a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from public.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
  and funding_year = 2017 --adding funding year filter for public flags
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where sc141a."LSTATE" = 'MT' --only smushing by district LSTREET1 for districts in MT
            group by  ag141a."LSTREET1",
                      ag141a."LCITY",
                      ag141a."LSTATE" ) sc_MT
on d."LSTREET1"=sc_MT."LSTREET1"
and d."LCITY"=sc_MT."LCITY"
and a.billingstatecode=sc_MT."LSTATE"

left join ( select  case
                      when ag141a."NAME" ilike '%geographic%' or ag141a."LEAID" = '3620580'
                        then true
                      else false
                    end as nyps_indicator,
                    ag141a."LSTATE",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and sc141a."TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or include_students > 0)
                                and sc141a."MEMBER"::numeric > 0 then sc141a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or include_students > 0)
                                and sc141a."MEMBER"::numeric > 0 and sc141a."PK"::numeric > 0 then sc141a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct  case
                                      when flaggable_id is null
                                        then sc141a."LEAID"
                                    end) as district_count
            from public.sc141a
            left join ag141a
            on sc141a."LEAID" = ag141a."LEAID"
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc141a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from public.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
  and funding_year = 2017 --adding funding year filter for public flags
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where sc141a."LSTATE" = 'NY'
            and (ag141a."NAME" ilike '%geographic%' or ag141a."LEAID" = '3620580')
            group by  case
                        when ag141a."NAME" ilike '%geographic%' or ag141a."LEAID" = '3620580'
                          then true
                        else false
                      end,
                      ag141a."LSTATE" ) sc_NY
on (eim.entity_id = '946654') = sc_NY.nyps_indicator
and a.billingstatecode=sc_NY."LSTATE"

*/

left join ( select  "UNION",
                    "LSTATE",
                    sum(  case when "KGTCH" < 0 then 0 else "KGTCH" end
                        + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                        + case when "SECTCH" < 0 then 0 else "SECTCH" end
                        + case when "UGTCH" < 0 then 0 else "UGTCH" end) as num_teachers,
                    sum(  case when "AIDES" < 0 then 0 else "AIDES" end) as num_aides,
                    sum(  case when "CORSUP" < 0 then 0 else "CORSUP" end
                        + case when "ELMGUI" < 0 then 0 else "ELMGUI" end
                        + case when "SECGUI" < 0 then 0 else "SECGUI" end
                        + case when "OTHGUI" < 0 then 0 else "OTHGUI" end
                        + case when "TOTGUI" < 0 then 0 else "TOTGUI" end
                        + case when "LIBSPE" < 0 then 0 else "LIBSPE" end
                        + case when "LIBSUP" < 0 then 0 else "LIBSUP" end
                        + case when "LEAADM" < 0 then 0 else "LEAADM" end
                        + case when "LEASUP" < 0 then 0 else "LEASUP" end
                        + case when "SCHADM" < 0 then 0 else "SCHADM" end
                        + case when "SCHSUP" < 0 then 0 else "SCHSUP" end
                        + case when "STUSUP" < 0 then 0 else "STUSUP" end
                        + case when "OTHSUP" < 0 then 0 else "OTHSUP" end)  as num_other_staff

            from public.ag141a
            where "LSTATE" = 'VT' --only smushing by UNION for districts in VT
            group by  "UNION",
                      "LSTATE" ) stf_VT
on d."UNION"=stf_VT."UNION"
and a.billingstatecode=stf_VT."LSTATE"

left join ( select  ag141a."LSTREET1",
                    ag141a."LCITY",
                    ag141a."LSTATE",
                    sum(  case when "KGTCH" < 0 then 0 else "KGTCH" end
                        + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                        + case when "SECTCH" < 0 then 0 else "SECTCH" end
                        + case when "UGTCH" < 0 then 0 else "UGTCH" end) as num_teachers,
                    sum(  case when "AIDES" < 0 then 0 else "AIDES" end) as num_aides,
                    sum(  case when "CORSUP" < 0 then 0 else "CORSUP" end
                        + case when "ELMGUI" < 0 then 0 else "ELMGUI" end
                        + case when "SECGUI" < 0 then 0 else "SECGUI" end
                        + case when "OTHGUI" < 0 then 0 else "OTHGUI" end
                        + case when "TOTGUI" < 0 then 0 else "TOTGUI" end
                        + case when "LIBSPE" < 0 then 0 else "LIBSPE" end
                        + case when "LIBSUP" < 0 then 0 else "LIBSUP" end
                        + case when "LEAADM" < 0 then 0 else "LEAADM" end
                        + case when "LEASUP" < 0 then 0 else "LEASUP" end
                        + case when "SCHADM" < 0 then 0 else "SCHADM" end
                        + case when "SCHSUP" < 0 then 0 else "SCHSUP" end
                        + case when "STUSUP" < 0 then 0 else "STUSUP" end
                        + case when "OTHSUP" < 0 then 0 else "OTHSUP" end)  as num_other_staff
            from ag141a
            where "LSTATE" = 'MT' --only smushing by district LSTREET1 for districts in MT
            group by  "LSTREET1",
                      "LCITY",
                      "LSTATE" ) stf_MT
on d."LSTREET1"=stf_MT."LSTREET1"
and d."LCITY"=stf_MT."LCITY"
and a.billingstatecode=stf_MT."LSTATE"

left join ( select  case
                      when "NAME" ilike '%geographic%' or "LEAID" = '3620580'
                        then true
                      else false
                    end as nyps_indicator,
                    946654 as esh_id,
                    "LSTATE",

                    sum(  case when "KGTCH" < 0 then 0 else "KGTCH" end
                        + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                        + case when "SECTCH" < 0 then 0 else "SECTCH" end
                        + case when "UGTCH" < 0 then 0 else "UGTCH" end) as num_teachers,
                    sum(  case when "AIDES" < 0 then 0 else "AIDES" end) as num_aides,
                    sum(  case when "CORSUP" < 0 then 0 else "CORSUP" end
                        + case when "ELMGUI" < 0 then 0 else "ELMGUI" end
                        + case when "SECGUI" < 0 then 0 else "SECGUI" end
                        + case when "OTHGUI" < 0 then 0 else "OTHGUI" end
                        + case when "TOTGUI" < 0 then 0 else "TOTGUI" end
                        + case when "LIBSPE" < 0 then 0 else "LIBSPE" end
                        + case when "LIBSUP" < 0 then 0 else "LIBSUP" end
                        + case when "LEAADM" < 0 then 0 else "LEAADM" end
                        + case when "LEASUP" < 0 then 0 else "LEASUP" end
                        + case when "SCHADM" < 0 then 0 else "SCHADM" end
                        + case when "SCHSUP" < 0 then 0 else "SCHSUP" end
                        + case when "STUSUP" < 0 then 0 else "STUSUP" end
                        + case when "OTHSUP" < 0 then 0 else "OTHSUP" end)  as num_other_staff
            from ag141a
            where "LSTATE" = 'NY'
            and ("NAME" ilike '%geographic%' or "LEAID" = '3620580')
            group by  case
                        when "NAME" ilike '%geographic%' or "LEAID" = '3620580'
                          then true
                        else false
                      end,
                      "LSTATE" ) stf_NY
on stf_NY.esh_id = eim.entity_id 

where a.recordtypeid = '012E0000000NE6DIAW'
and a.out_of_business__c = false
and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
and d."LEAID" is not null
/*
Author: Justine Schott
Date: 6/20/2016
Last Modified Date: 7/7 -Jeremy - updated demogs to be from salesforce
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Districts demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET1T for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be applied. Excluded schools have flags to be removed from the population.

Purpose: Refactoring tables for 2017 data
Methodology: Using new tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise.
Usage of public.flags & funding_year clause
*/