select  case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as esh_id,
        d."LEAID" as nces_cd,
        d."NAME" as name,
        case
          when "TYPE" = '7' then 'Charter'
          when "FIPST" = '59' then 'BIE'
          when ( --all states except VT include districts of type 1,2 (traditional), or 7 (charter).
                  (case
                      when d."LSTATE" != 'VT' then "TYPE" in ('1', '2', '7')
                      else false
                    end )
                  --in RI and MA we also include 4's with majority type 1 schools.
                  or (d."LSTATE" in ('RI', 'MA')
                      and "TYPE" = '4'
                      and sc.school_type_1_count/sc.school_count::numeric >= .75 )
                  --in NY we also include 3's, in VT we only include 3's
                  or (d."LSTATE" in ('VT', 'NY')
                      and "TYPE" = '3') )
            then 'Traditional'
          else 'Other Agency'
        end as district_type,
        d."LSTREE" as address,
        d."LCITY" as city,
        d."LZIP" as zip,
        d."CONAME" as county,
        d."LSTATE" as postal_cd,
        d."LATCOD" as latitude,
        d."LONCOD" as longitude,
        case
          when d."LSTATE" = 'VT' then case
                                        when sc_VT.student_count - sc_VT.student_pk_count is null
                                          then 0
                                        else sc_VT.student_count - sc_VT.student_pk_count
                                      end
          when d."LSTATE" = 'MT' then case
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
          when d."LSTATE" = 'VT' then case
                                        when sc_VT.school_count is null
                                          then 0
                                        else sc_VT.school_count
                                      end
          when d."LSTATE" = 'MT' then case
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
          when left("ULOCAL",1) = '1' then 'Urban'
          when left("ULOCAL",1) = '2' then 'Suburban'
          when left("ULOCAL",1) = '3' then 'Town'
          when left("ULOCAL",1) = '4' then 'Rural'
            else 'Unknown'
        end as locale,
        case
          when d."LSTATE" = 'VT' then case
                                      when sc_VT.school_count=1 then 'Tiny'
                                      when sc_VT.school_count>1 and sc_VT.school_count<=5 then 'Small'
                                      when sc_VT.school_count>5 and sc_VT.school_count<=15 then 'Medium'
                                      when sc_VT.school_count>15 and sc_VT.school_count<=50 then 'Large'
                                      when sc_VT.school_count>50 then 'Mega'
                                        else 'Unknown'
                                    end
          when d."LSTATE" = 'MT' then case
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
                      when d."LSTATE" != 'VT' then "TYPE" in ('1', '2', '7')
                      else false
                    end )
                  --in RI and MA we also include 4's with majority type 1 schools.
                  or (d."LSTATE" in ('RI', 'MA')
                      and "TYPE" = '4'
                      and sc.school_type_1_count/sc.school_count::numeric >= .75 )
                  --in NY we also include 3's, in VT we only include 3's
                  or (d."LSTATE" in ('VT', 'NY')
                      and "TYPE" = '3') )
          and d."LSTATE" not in ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DD') --don't want to include districts in territories
          and left("ULOCAL",1) in ('1', '2', '3', '4')      --want to include districts with known locales
          and ( sc.student_count - sc.student_pk_count  >0
                or (d."LSTATE" = 'MT' and sc_MT.student_count - sc_MT.student_pk_count  >0)
                or (d."LSTATE" = 'VT' and sc_VT.student_count - sc_VT.student_pk_count  >0) --want to include districts with at least 1 student,
                or (eim.entity_id = '946654' and sc_NY.student_count - sc_NY.student_pk_count  >0)
                or "FIPST" = '59' )                                                        --also, we want to include BIE's without student counts
          and ( (sc.school_count) > 0
                or (d."LSTATE" = 'MT' and (sc_MT.school_count)>0)
                or (d."LSTATE" = 'VT' and (sc_VT.school_count)>0) ) --want to include districts with at least 1 school
                or (eim.entity_id = '946654' and (sc_NY.school_count)>0)
          and "BOUND" != '2' --closed districts
            then  case
                    when "TYPE" != '7' or d."LSTATE" = 'AZ'
                      then true
                    else false
                  end
          else false
        end as include_in_universe_of_districts,
        case
          when ( --all states except VT include districts of type 1,2 (traditional), or 7 (charter).
                  (case
                      when d."LSTATE" != 'VT' then "TYPE" in ('1', '2', '7')
                      else false
                    end )
                  --in RI and MA we also include 4's with majority type 1 schools.
                  or (d."LSTATE" in ('RI', 'MA')
                      and "TYPE" = '4'
                      and sc.school_type_1_count/sc.school_count::numeric >= .75 )
                  --in NY we also include 3's, in VT we only include 3's
                  or (d."LSTATE" in ('VT', 'NY')
                      and "TYPE" = '3') )
          and d."LSTATE" not in ('AE', 'AP', 'AS', 'GU', 'MP', 'PR', 'VI', 'DD') --don't want to include districts in territories
          and left("ULOCAL",1) in ('1', '2', '3', '4')      --want to include districts with known locales
          and ( sc.student_count - sc.student_pk_count  >0
                or (d."LSTATE" = 'MT' and sc_MT.student_count - sc_MT.student_pk_count  >0)
                or (d."LSTATE" = 'VT' and sc_VT.student_count - sc_VT.student_pk_count  >0) --want to include districts with at least 1 student,
                or (eim.entity_id = '946654' and sc_NY.student_count - sc_NY.student_pk_count  >0)
                or "FIPST" = '59' )                                                        --also, we want to include BIE's without student counts
          and ( (sc.school_count) > 0
                or (d."LSTATE" = 'MT' and (sc_MT.school_count)>0)
                or (d."LSTATE" = 'VT' and (sc_VT.school_count)>0) ) --want to include districts with at least 1 school
                or (eim.entity_id = '946654' and (sc_NY.school_count)>0)
          and "BOUND" != '2' --closed districts
            then  true
          else false
        end as include_in_universe_of_districts_all_charters,
        case
          when d."LSTATE" = 'VT' then stf_VT.num_teachers
          when d."LSTATE" = 'MT' then stf_MT.num_teachers
          when eim.entity_id = '946654' then stf_NY.num_teachers
            else  case when "KGTCH" < 0 then 0 else "KGTCH" end
                + case when "ELMTCH" < 0 then 0 else "ELMTCH" end
                + case when "SECTCH" < 0 then 0 else "SECTCH" end
                + case when "UGTCH" < 0 then 0 else "UGTCH" end
        end as num_teachers,
        case
          when d."LSTATE" = 'VT' then stf_VT.num_aides
          when d."LSTATE" = 'MT' then stf_MT.num_aides
          when eim.entity_id = '946654' then stf_NY.num_aides
            else  case when "AIDES" < 0 then 0 else "AIDES" end
        end as num_aides,
        case
          when d."LSTATE" = 'VT' then stf_VT.num_other_staff
          when d."LSTATE" = 'MT' then stf_MT.num_other_staff
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

from public.ag131a d
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
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
            from public.sc131a
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as closed_school_count,
                      count(*) as removed_school_count
              from fy2016.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
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
                                        then sc131a."LEAID"
                                    end) as district_count
            from public.sc131a
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from fy2016.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where "LSTATE" = 'VT' --only smushing by UNION for districts in VT
            group by  "UNION",
                      "LSTATE" ) sc_VT
on d."UNION"=sc_VT."UNION"
and d."LSTATE"=sc_VT."LSTATE"

left join ( select  ag131a."LSTREE",
                    ag131a."LCITY",
                    ag131a."LSTATE",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and sc131a."TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or include_students > 0)
                                and sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or include_students > 0)
                                and sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct  case
                                      when flaggable_id is null
                                        then sc131a."LEAID"
                                    end) as district_count
            from public.sc131a
            left join ag131a
            on sc131a."LEAID" = ag131a."LEAID"
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from fy2016.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where sc131a."LSTATE" = 'MT' --only smushing by district LSTREE for districts in MT
            group by  ag131a."LSTREE",
                      ag131a."LCITY",
                      ag131a."LSTATE" ) sc_MT
on d."LSTREE"=sc_MT."LSTREE"
and d."LCITY"=sc_MT."LCITY"
and d."LSTATE"=sc_MT."LSTATE"

left join ( select  case
                      when ag131a."NAME" ilike '%geographic%' or ag131a."LEAID" = '3620580'
                        then true
                      else false
                    end as nyps_indicator,
                    ag131a."LSTATE",
                    sum(case
                            when flaggable_id is null
                              then 1
                            else 0
                          end) as school_count,
                    sum(case
                            when flaggable_id is null and sc131a."TYPE" = '1'
                              then 1
                            else 0
                          end) as school_type_1_count,
                    sum(case
                          when (flaggable_id is null or include_students > 0)
                                and sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  (flaggable_id is null or include_students > 0)
                                and sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct  case
                                      when flaggable_id is null
                                        then sc131a."LEAID"
                                    end) as district_count
            from public.sc131a
            left join ag131a
            on sc131a."LEAID" = ag131a."LEAID"
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select  flaggable_id,
                      count(case
                              when label = 'closed_school'
                                then 1
                            end) as include_students
              from fy2016.flags
              where label in ('closed_school', 'non_school', 'charter_school')
              and status = 'open'
              group by flaggable_id
            ) t
            on eim.entity_id = t.flaggable_id
            where sc131a."LSTATE" = 'NY'
            and (ag131a."NAME" ilike '%geographic%' or ag131a."LEAID" = '3620580')
            group by  case
                        when ag131a."NAME" ilike '%geographic%' or ag131a."LEAID" = '3620580'
                          then true
                        else false
                      end,
                      ag131a."LSTATE" ) sc_NY
on (eim.entity_id = '946654') = sc_NY.nyps_indicator
and d."LSTATE"=sc_NY."LSTATE"

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

            from public.ag131a
            where "LSTATE" = 'VT' --only smushing by UNION for districts in VT
            group by  "UNION",
                      "LSTATE" ) stf_VT
on d."UNION"=stf_VT."UNION"
and d."LSTATE"=stf_VT."LSTATE"

left join ( select  ag131a."LSTREE",
                    ag131a."LCITY",
                    ag131a."LSTATE",
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
            from ag131a
            where "LSTATE" = 'MT' --only smushing by district LSTREE for districts in MT
            group by  "LSTREE",
                      "LCITY",
                      "LSTATE" ) stf_MT
on d."LSTREE"=stf_MT."LSTREE"
and d."LCITY"=stf_MT."LCITY"
and d."LSTATE"=stf_MT."LSTATE"

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
            from ag131a
            where "LSTATE" = 'NY'
            and ("NAME" ilike '%geographic%' or "LEAID" = '3620580')
            group by  case
                        when "NAME" ilike '%geographic%' or "LEAID" = '3620580'
                          then true
                        else false
                      end,
                      "LSTATE" ) stf_NY
on (eim.entity_id = '946654') = sc_NY.nyps_indicator
and d."LSTATE"=sc_NY."LSTATE"

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
and not(d."LSTATE" = 'VT' and "TYPE" in ('1', '2')) --only include the TYPE 3 when smushing VT districts
and not(d."LSTATE" = 'NY' and "NAME" ilike '%geographic%') --only include the 'geographic' districts in NYPS

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 3/21/2017 --  MT smush to smush by both address AND city, not just address
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Districts demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be created. Excluded schools have flags to be removed from the population.
*/