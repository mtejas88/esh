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
        d."LSTREET1" as address,
        d."LCITY" as city,
        d."LZIP" as zip,
        d."CONAME" as county,
        case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end as postal_cd,
        d."LATCOD" as latitude,
        d."LONCOD" as longitude,
        case
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then case
                                        when sc_VT.student_count - sc_VT.student_pk_count is null
                                          then 0
                                        else sc_VT.student_count - sc_VT.student_pk_count
                                      end
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then case
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
        case
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then case
                                        when sc_VT.school_count is null
                                          then 0
                                        else sc_VT.school_count
                                      end
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then case
                                        when sc_MT.school_count is null
                                          then 0
                                        else sc_MT.school_count
                                      end
          when eim.entity_id = '946654' then case
                                        when sc_NY.school_count is null
                                          then 0
                                        else sc_NY.school_count
                                      end
            else  case
                    when sc.school_count is null
                      then 0
                    else sc.school_count
                  end
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
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then case
                                      when sc_VT.school_count=1 then 'Tiny'
                                      when sc_VT.school_count>1 and sc_VT.school_count<=5 then 'Small'
                                      when sc_VT.school_count>5 and sc_VT.school_count<=15 then 'Medium'
                                      when sc_VT.school_count>15 and sc_VT.school_count<=50 then 'Large'
                                      when sc_VT.school_count>50 then 'Mega'
                                        else 'Unknown'
                                    end
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then case
                                      when sc_MT.school_count=1 then 'Tiny'
                                      when sc_MT.school_count>1 and sc_MT.school_count<=5 then 'Small'
                                      when sc_MT.school_count>5 and sc_MT.school_count<=15 then 'Medium'
                                      when sc_MT.school_count>15 and sc_MT.school_count<=50 then 'Large'
                                      when sc_MT.school_count>50 then 'Mega'
                                        else 'Unknown'
                                    end
          when eim.entity_id = '946654' then case
                                      when sc_NY.school_count=1 then 'Tiny'
                                      when sc_NY.school_count>1 and sc_NY.school_count<=5 then 'Small'
                                      when sc_NY.school_count>5 and sc_NY.school_count<=15 then 'Medium'
                                      when sc_NY.school_count>15 and sc_NY.school_count<=50 then 'Large'
                                      when sc_NY.school_count>50 then 'Mega'
                                        else 'Unknown'
                                    end
            else  case
                    when sc.school_count=1 then 'Tiny'
                    when sc.school_count>1 and sc.school_count<=5 then 'Small'
                    when sc.school_count>5 and sc.school_count<=15 then 'Medium'
                    when sc.school_count>15 and sc.school_count<=50 then 'Large'
                    when sc.school_count>50 then 'Mega'
                      else 'Unknown'
                  end
        end as district_size,
        d."UNION" as union_code,
        case
          when ( --all states except VT include districts of type 1,2 (traditional), or 7 (charter).
                  (case
                      when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end != 'VT' then "TYPE" in ('1', '2', '7')
                      else false
                    end )
                  --in RI and MA we also include 4's with majority type 1 schools.
                  or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end in ('RI', 'MA')
                      and "TYPE" = '4'
                      and sc.school_type_1_count/sc.school_count::numeric >= .75 )
                  --in NY we also include 3's, in VT we only include 3's
                  or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end in ('VT', 'NY')
                      and "TYPE" = '3') )
          and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end not in ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DD') --don't want to include districts in territories
          and left("ULOCAL",1) in ('1', '2', '3', '4')      --want to include districts with known locales
          and ( sc.student_count - sc.student_pk_count  >0
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' and sc_MT.student_count - sc_MT.student_pk_count  >0)
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' and sc_VT.student_count - sc_VT.student_pk_count  >0) --want to include districts with at least 1 student,
                or (eim.entity_id = '946654' and sc_NY.student_count - sc_NY.student_pk_count  >0)
                or "FIPST" = '59' )                                                        --also, we want to include BIE's without student counts
          and ( (sc.school_count) > 0
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' and (sc_MT.school_count)>0)
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' and (sc_VT.school_count)>0) ) --want to include districts with at least 1 school
                or (eim.entity_id = '946654' and (sc_NY.school_count)>0)
          and "BOUND" != '2' --closed districts
            then  case
                    when "TYPE" != '7' or case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'AZ'
                      then true
                    else false
                  end
          else false
        end as include_in_universe_of_districts,
        case
          when ( --all states except VT include districts of type 1,2 (traditional), or 7 (charter).
                  (case
                      when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end != 'VT' then "TYPE" in ('1', '2', '7')
                      else false
                    end )
                  --in RI and MA we also include 4's with majority type 1 schools.
                  or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end in ('RI', 'MA')
                      and "TYPE" = '4'
                      and sc.school_type_1_count/sc.school_count::numeric >= .75 )
                  --in NY we also include 3's, in VT we only include 3's
                  or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end in ('VT', 'NY')
                      and "TYPE" = '3') )
          and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end not in ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DD') --don't want to include districts in territories
          and left("ULOCAL",1) in ('1', '2', '3', '4')      --want to include districts with known locales
          and ( sc.student_count - sc.student_pk_count  >0
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' and sc_MT.student_count - sc_MT.student_pk_count  >0)
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' and sc_VT.student_count - sc_VT.student_pk_count  >0) --want to include districts with at least 1 student,
                or (eim.entity_id = '946654' and sc_NY.student_count - sc_NY.student_pk_count  >0)
                or "FIPST" = '59' )                                                        --also, we want to include BIE's without student counts
          and ( (sc.school_count) > 0
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' and (sc_MT.school_count)>0)
                or (case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' and (sc_VT.school_count)>0) ) --want to include districts with at least 1 school
                or (eim.entity_id = '946654' and (sc_NY.school_count)>0)
          and "BOUND" != '2' --closed districts
            then  true
          else false
        end as include_in_universe_of_districts_all_charters,
        case
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then stf_VT.num_teachers
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then stf_MT.num_teachers
          when eim.entity_id = '946654' then stf_NY.num_teachers
            else  case when "KGTCH" < 0 then 0 else "KGTCH" end
                + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                + case when "SECTCH" < 0 then 0 else "SECTCH" end
                + case when "UGTCH" < 0 then 0 else "UGTCH" end
        end as num_teachers,
        case
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then stf_VT.num_aides
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then stf_MT.num_aides
          when eim.entity_id = '946654' then stf_NY.num_aides
            else  case when "AIDES" < 0 then 0 else "AIDES" end
        end as num_aides,
        case
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' then stf_VT.num_other_staff
          when case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'MT' then stf_MT.num_other_staff
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
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=sc_VT."LSTATE"

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
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=sc_MT."LSTATE"

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
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=sc_NY."LSTATE"

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
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=stf_VT."LSTATE"

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
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=stf_MT."LSTATE"

left join ( select  case
                      when "NAME" ilike '%geographic%' or "LEAID" = '3620580'
                        then true
                      else false
                    end as nyps_indicator,
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
on (eim.entity_id = '946654') = sc_NY.nyps_indicator
and case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end=sc_NY."LSTATE"

where case --only include the HS district when smushing MT districts (exclude the ELEM)
        when sc_MT.district_count > 1
          then --this is the blacklist of NCES IDS for MT districts that were smushed and we dont want to include
          d."LEAID" not in (  '3001710','3002010','3002220','3002430','3003290','3003420',
                              '3003820','3003760','3003870','3004440','3004560','3000006',
                              '3004890','3005010','3005140','3005280','3005880','3025130',
                              '3006112','3000098','3006260','3006320','3006790','3007050',
                              '3007110','3007190','3007330','3007830','3000003','3008860',
                              '3009180','3009670','3010080','3010140','3010210','3011160',
                              '3011240','3011420','3011550','3011820','3012270','3012510',
                              '3012960','3013040','3013310','3013395','3013440','3013560',
                              '3000005','3014340','3015200','3015340','3015360','3015450',
                              '3015990','3016050','3016200','3016490','3016880','3017010',
                              '3017610','3018240','3018410','3018570','3018870','3000096',
                              '3000090','3020040','3020820','3021060','3021240','3021510',
                              '3021720','3021870','3022080','3022230','3022370','3022750',
                              '3022790','3023040','3023370','3023520','3023900',
                              '3023940','3024150','3000932','3024200','3025020','3024300',
                              '3026070','3026160','3026550','3026640','3027060','3027740',
                              '3027810','3028750','3028140','3028590')
        else true
      end
and not(case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'VT' and "TYPE" in ('1', '2')) --only include the TYPE 3 when smushing VT districts
and not(case when d."STABR" = 'BI' then d."LSTATE" else d."STABR" end = 'NY' and "NAME" ilike '%geographic%') --only include the 'geographic' districts in NYPS

and eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */
/*
Author: Justine Schott
Date: 6/20/2016
Last Modified Date: 6/23 - JH - changed postal cd to reference STABR. only changes 11 district postal codes in our universe
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Districts demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET1T for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be applied. Excluded schools have flags to be removed from the population.

Purpose: Refactoring tables for 2017 data
Methodology: Using new tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise.
Usage of public.flags & funding_year clause
*/