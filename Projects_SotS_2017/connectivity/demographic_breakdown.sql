with districts as (
  select *,
  case
    when "AM"::numeric > 0
      then num_students*"AM"::numeric/"MEMBER"::numeric
    else 0
  end as am_students,
  case
    when "AS"::numeric > 0 
      then num_students*"AS"::numeric/"MEMBER"::numeric
    else 0
  end as as_students,
  case
    when "HI"::numeric > 0
      then num_students*"HI"::numeric/"MEMBER"::numeric
    else 0
  end as hi_students,
  case
    when "BL"::numeric > 0
      then num_students*"BL"::numeric/"MEMBER"::numeric
    else 0
  end as bl_students,
  case
    when "WH"::numeric > 0
      then num_students*"WH"::numeric/"MEMBER"::numeric
    else 0
  end as wh_students,
  case
    when "HP"::numeric > 0
      then num_students*"HP"::numeric/"MEMBER"::numeric
    else 0
  end as hp_students,
  case
    when "TR"::numeric > 0
      then num_students*"TR"::numeric/"MEMBER"::numeric
    else 0
  end as tr_students
  from fy2017_districts_deluxe_matr dd
  left join public.fy2014_fy2015_districts_membership mem 
  on dd.nces_cd = mem."LEAID" 
  where "MEMBER"::numeric > 0
  and "MEMBER"::numeric = "AM"::numeric + "AS"::numeric + "HI"::numeric + "BL"::numeric + "WH"::numeric + 
  "HP"::numeric + "TR"::numeric 
  and dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
),

demog as (
  select 
    sum(dd.num_students) as member_population,
    sum(am_students)/sum(d.num_students)*sum(dd.num_students) as am_population,
    sum(as_students)/sum(d.num_students)*sum(dd.num_students) as as_population,
    sum(hi_students)/sum(d.num_students)*sum(dd.num_students) as hi_population,
    sum(bl_students)/sum(d.num_students)*sum(dd.num_students) as bl_population,
    sum(wh_students)/sum(d.num_students)*sum(dd.num_students) as wh_population,
    sum(hp_students)/sum(d.num_students)*sum(dd.num_students) as hp_population,
    sum(tr_students)/sum(d.num_students)*sum(dd.num_students) as tr_population,
    sum(case
          when d.exclude_from_ia_analysis= false 
            then d.num_students
          else 0
        end) as member_sample,
    sum(case
          when d.exclude_from_ia_analysis= false 
            then am_students
          else 0
        end) as am_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then as_students
          else 0
        end) as as_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then hi_students
          else 0
        end) as hi_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then bl_students
          else 0
        end) as bl_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then wh_students
          else 0
        end) as wh_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then hp_students
          else 0
        end) as hp_sample, 
    sum(case
          when d.exclude_from_ia_analysis= false 
            then tr_students
          else 0
        end) as tr_sample       
  from fy2017_districts_deluxe_matr dd
  left join districts d 
  on dd.esh_id = d.esh_id 
  where dd.include_in_universe_of_districts
  and dd.district_type = 'Traditional'
)


select
  'overall' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then num_students::numeric
        else 0
      end)/member_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then num_students::numeric
        else 0
      end)/member_sample*member_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by member_sample, member_population

UNION

select
  'white' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then wh_students
        else 0
      end)/wh_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then wh_students 
        else 0
      end)/wh_sample*wh_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by wh_sample, wh_population

UNION

select
  'native american' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then am_students 
        else 0
      end)/am_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then am_students 
        else 0
      end)/am_sample*am_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by am_sample, am_population

UNION

select
  'asian' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then as_students
        else 0
      end)/as_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then as_students 
        else 0
      end)/as_sample*as_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by as_sample, as_population

UNION

select
  'hispanic' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then hi_students 
        else 0
      end)/hi_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then hi_students 
        else 0
      end)/hi_sample*hi_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by hi_sample, hi_population

UNION

select
  'black' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then bl_students
        else 0
      end)/bl_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then bl_students 
        else 0
      end)/bl_sample*bl_population/1000000 as extrap_students_not_meeting_goals_mil
  from districts
join demog
on true
where exclude_from_ia_analysis = false
group by bl_sample, bl_population

UNION

select
  'pacific islander' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then hp_students
        else 0
      end)/hp_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then hp_students 
        else 0
      end)/hp_sample*hp_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by hp_sample, hp_population

UNION

select
  'two or more races' as student_demographic, 
  sum(case
        when meeting_2014_goal_no_oversub = false
          then tr_students
        else 0
      end)/tr_sample as pct_students_not_meeting_goals,
  sum(case
        when meeting_2014_goal_no_oversub = false
          then tr_students 
        else 0
      end)/tr_sample*tr_population/1000000 as extrap_students_not_meeting_goals_mil
from districts
join demog
on true
where exclude_from_ia_analysis = false
group by tr_sample, tr_population

order by 2