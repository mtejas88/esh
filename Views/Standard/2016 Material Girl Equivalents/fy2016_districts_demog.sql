select  case
          when eim.entity_id is null then 'Unknown for 2015'
            else eim.entity_id::varchar
        end as esh_id,
        d."LEAID" as nces_cd,
        d."NAME" as name,
        case
          when "TYPE" = '7' then 'Charter'
          when "FIPST" = '59' then 'BIE'
          else 'Traditional'
        end as district_type,
        d."LSTREE" as address,
        d."LCITY" as city,
        d."LZIP" as zip,
        d."CONAME" as county,
        d."LSTATE" as postal_cd,
        d."LATCOD" as latitude,
        d."LONCOD" as longitude,
        case 
          when d."LSTATE" = 'VT' then sc_VT.student_count - sc_VT.student_pk_count 
          when d."LSTATE" = 'MT' then sc_MT.student_count - sc_MT.student_pk_count
            else sc.student_count - sc.student_pk_count 
        end as num_students,
        case
          when d."LSTATE" = 'VT' then sc_VT.school_count
          when d."LSTATE" = 'MT' then sc_MT.school_count
            else sc.school_count
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
            else  case
                    when sc.school_count=1 then 'Tiny'
                    when sc.school_count>1 and sc.school_count<=5 then 'Small'
                    when sc.school_count>5 and sc.school_count<=15 then 'Medium'
                    when sc.school_count>15 and sc.school_count<=50 then 'Large'
                    when sc.school_count>50 then 'Mega'
                      else 'Unknown'
                  end
        end as district_size,
        d."UNION" as union_code
        
from public.ag131a d
left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on RPAD(d."LEAID",12,'0')=eim.nces_code

left join ( select  "LEAID",
                    count(*) as school_count,
                    count(case when "TYPE" = '1' then 1 end) as school_type_1_count,
                    sum(case
                          when  "MEMBER"::numeric > 0 then "MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  "MEMBER"::numeric > 0 and "PK"::numeric > 0 then "PK"::numeric
                            else 0
                        end) as student_pk_count
            from public.sc131a 
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select distinct taggable_id, label
              from fy2016.tags
              where label in ('closed_school', 'non_school', 'charter_school')
              and deleted_at is null
            ) t
            on eim.entity_id = t.taggable_id
            where label is null
            group by "LEAID" ) sc
on d."LEAID"=sc."LEAID"
left join ( select  "UNION",
                    "LSTATE",
                    count(*) as school_count,
                    count(case when sc131a."TYPE" = '1' then 1 end) as school_type_1_count,
                    sum(case
                          when  sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct sc131a."LEAID") as district_count
            from public.sc131a 
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select distinct taggable_id, label
              from fy2016.tags
              where label in ('closed_school', 'non_school', 'charter_school')
              and deleted_at is null
            ) t
            on eim.entity_id = t.taggable_id
            where label is null
            and "LSTATE" = 'VT' --only smushing by UNION for districts in VT
            group by  "UNION",
                      "LSTATE" ) sc_VT
on d."UNION"=sc_VT."UNION"
and d."LSTATE"=sc_VT."LSTATE"

left join ( select  ag131a."LSTREE",
                    ag131a."LSTATE",
                    count(*) as school_count,
                    count(case when sc131a."TYPE" = '1' then 1 end) as school_type_1_count,
                    sum(case
                          when  sc131a."MEMBER"::numeric > 0 then sc131a."MEMBER"::numeric
                            else 0
                        end) as student_count,
                    sum(case
                          when  sc131a."MEMBER"::numeric > 0 and sc131a."PK"::numeric > 0 then sc131a."PK"::numeric
                            else 0
                        end) as student_pk_count,
                    count(distinct sc131a."LEAID") as district_count
            from public.sc131a 
            left join public.ag131a
            on sc131a."LEAID" = ag131a."LEAID"
            left join ( select distinct entity_id, nces_code
                        from public.entity_nces_codes) eim
            on sc131a."NCESSCH" = eim.nces_code
            left join (
              select distinct taggable_id, label
              from fy2016.tags
              where label in ('closed_school', 'non_school', 'charter_school')
              and deleted_at is null
            ) t
            on eim.entity_id = t.taggable_id
            where label is null
            and sc131a."LSTATE" = 'MT' --only smushing by district LSTREE for districts in MT
            group by  ag131a."LSTREE",
                      ag131a."LSTATE" ) sc_MT
on d."LSTREE"=sc_MT."LSTREE"
and d."LSTATE"=sc_MT."LSTATE"

where ( --all states except VT include districts of type 1,2 (traditional), or 7 (charter).
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
      or "FIPST" = '59' )                                                        --also, we want to include BIE's without student counts 
and ( (sc.school_count) > 0 
      or (d."LSTATE" = 'MT' and (sc_MT.school_count)>0)  
      or (d."LSTATE" = 'VT' and (sc_VT.school_count)>0) ) --want to include districts with at least 1 school 
and "BOUND" != '2' --closed districts
and case --only include the HS district when smushing MT districts (exclude the ELEM)
      when sc_MT.district_count > 1
        then  right(d."NAME",3) =' HS'
              or right(d."NAME",4) =' H S'
              or right(d."NAME",12) =' HIGH SCHOOL'
              or right(d."NAME",13) = ' K-12 SCHOOLS'
      else true
    end

/*
Author: Justine Schott
Created On Date: 6/20/2016
Last Modified Date: 9/16/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: Districts demographics of those in the universe
Methodology: Smushing by UNION for VT and district LSTREET for MT. Otherwise, metrics taken mostly from NCES. Done before
metrics aggregation so school-district association can be created.
Aligned with ENG until school flags implemented.
*/