-- temp tables to enable finding comparisons for each district:
-- limit to the locale and district_size options: plus or minus 1 locale and district size
with lookup as (
select locale,
district_size,
postal_cd,
case
 when locale = 'Rural' then 0
 when locale = 'Town' then 1
 when locale = 'Suburban' then 2
 when locale = 'Urban' then 3
end as locale_score,
case
 when district_size = 'Tiny' then 0
 when district_size = 'Small' then 1
 when district_size = 'Medium' then 2
 when district_size = 'Large' then 3
 when district_size = 'Mega' then 4
end as district_size_score,
array_agg(esh_id) as districts
from endpoint.fy2017_districts_deluxe dd
where include_in_universe_of_districts = true
group by 1,2,3,4,5),

-- aggregate the locale, district_size options
agg_lookup as (select l2.district_size as l2district,
l2.locale as l2locale,
l.postal_cd,
l.locale,
l.district_size,
l2.districts
from lookup l
join lookup l2
on (l.locale_score = l2.locale_score - 1
or l.locale_score = l2.locale_score + 1
or l.locale_score = l2.locale_score)
and
(l.district_size_score = l2.district_size_score - 1
or l.district_size_score = l2.district_size_score + 1
or l.district_size_score = l2.district_size_score)
and (l.postal_cd = l2.postal_cd)
order by 3,4,5),

-- unwrap locale, district_size options to allow to reaggregate
unagg_lookup as (select postal_cd,
locale,
district_size,
unnest(districts) as districts
from agg_lookup),

-- reaggregate
all_comps as (select postal_cd,
locale,
district_size,
array_agg(districts) as comparable_districts
from unagg_lookup
group by postal_cd, locale, district_size),

-- merge all districts by postal_cd, locale, district_size
all_comps_merged as (select dd.esh_id,
ac.comparable_districts
from endpoint.fy2017_districts_deluxe as dd
left join all_comps as ac
on ac.postal_cd = dd.postal_cd
and ac.locale = dd.locale
and ac.district_size = dd.district_size
where dd.include_in_universe_of_districts = true),

-- unaggregate so can merge in district details for district pairs
all_comps_unagg as (select esh_id,
unnest(comparable_districts) as comparable_districts
from all_comps_merged)

select * from all_comps_unagg

