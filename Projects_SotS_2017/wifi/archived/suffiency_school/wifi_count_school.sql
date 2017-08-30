with all_responses as (

	--parent responses
	select 
	  distinct dd.esh_id as district_esh_id,
	  dd.name as district_name,
	  dd.esh_id as responding_esh_id,
	  dd.name as responding_name,
	  ci.parent_wifi as wifi_response,
	  t.label as open_wifi_tags,
	  case
	  	when t.label = 'sufficient_wifi'
	  		then 0
	  	when t.label = 'insufficient_wifi'
	  		then 1
	  	when ci.parent_wifi in ('Sometimes', 'Never')
	  		then 1
	  	else 0
	  end as needs_wifi

	from fy2017.connectivity_informations ci
	      
	left join public.entity_bens eb_parent
	on ci.parent_entity_number = eb_parent.ben
	      
	join public.fy2017_districts_demog_matr dd
	on eb_parent.entity_id::varchar = dd.esh_id

	left join public.tags t
	on dd.esh_id = t.taggable_id::varchar
	and t.label in ('sufficient_wifi', 'insufficient_wifi')
	and t.deleted_at is null
	and funding_year = 2017
	      
	where dd.include_in_universe_of_districts = true
	and ci.parent_wifi is not null
	and ci.parent_wifi != 'Not Applicable'

	UNION 

	--child responses. note, some child responses could have multiple responses
	select 
	  distinct dd.esh_id as district_esh_id,
	  dd.name as district_name,
	  sd.school_esh_id as responding_esh_id,
	  sd.name as responding_name,
	  ci.child_wifi as wifi_response,
	  t.label as open_wifi_tags,
	  case
	  	when t.label = 'sufficient_wifi'
	  		then 0
	  	when t.label = 'insufficient_wifi'
	  		then 1
	  	when ci.child_wifi in ('Sometimes', 'Never')
	  		then 1
	  	else 0
	  end as needs_wifi

	from fy2017.connectivity_informations ci
	      
	left join public.entity_bens eb_parent
	on ci.parent_entity_number = eb_parent.ben
	      
	join public.fy2017_districts_demog_matr dd
	on eb_parent.entity_id::varchar = dd.esh_id

	left join public.entity_bens eb_child
	on ci.child_entity_number = eb_child.ben

	join public.fy2017_schools_demog_matr sd
	on eb_child.entity_id::varchar = sd.school_esh_id

	left join public.tags t
	on dd.esh_id = t.taggable_id::varchar
	and t.label in ('sufficient_wifi', 'insufficient_wifi')
	and t.deleted_at is null
	and funding_year = 2017
	      
	where dd.include_in_universe_of_districts = true
	and ci.child_wifi is not null
	and ci.child_wifi != 'Not Applicable'

),

responses_extrap as (

	select 
		dd.postal_cd,
		dd.name as parent_entity_name,
		dd.esh_id as parent_entity_id,
		sum(a.needs_wifi)::numeric / count(a.responding_esh_id)::numeric * dd.num_schools as count_wifi_needed

	from public.fy2017_districts_demog_matr dd

	left join all_responses a
	on dd.esh_id = a.district_esh_id

	where dd.include_in_universe_of_districts = true

	group by
	  dd.postal_cd,
	  dd.name,
	  dd.esh_id,
	  dd.num_schools

),

cross_year_responses as (
	select 
	  d17.esh_id,
	  d17.num_schools,
	  case 
	    when d16.needs_wifi = false
	      then 'Sufficient'
	    when d16.needs_wifi = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_16,
	  case 
	    when d17.needs_wifi = false
	      then 'Sufficient'
	    when d17.needs_wifi = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_17
	  
	from public.fy2017_districts_deluxe_matr d17

	left join public.fy2016_districts_deluxe_matr d16
	on d17.esh_id = d16.esh_id

	where d17.include_in_universe_of_districts = true
	and d17.district_type = 'Traditional'

),

responses_to_cross_yr as (

select 
  cr.esh_id,
  cr.dd_response_16,
  cr.dd_response_17,
  cr.num_schools,
  r.count_wifi_needed,
  case
    when cr.dd_response_16 = 'Sufficient' 
     and cr.dd_response_17 = 'Sufficient'
      then cr.num_schools * .013
    when cr.dd_response_16 = 'Sufficient' 
     and cr.dd_response_17 = 'No response'
      then cr.num_schools * .074
    when cr.dd_response_16 = 'Insufficient' 
     and cr.dd_response_17 = 'Insufficient'
      then cr.num_schools * .822
    when cr.dd_response_16 = 'Insufficient' 
     and cr.dd_response_17 = 'No response'
      then cr.num_schools * .58
    when cr.dd_response_16 = 'No response' 
     and cr.dd_response_17 = 'No response'
      then cr.num_schools * .202
    else r.count_wifi_needed
  end as extrap_schools_wifi_needed

from cross_year_responses cr

left join responses_extrap r
on cr.esh_id = r.parent_entity_id

)

/*
select 
round(sum(num_schools),0) as num_schools,
round(sum(extrap_schools_wifi_needed),0) as extrap_schools_need_wifi,
round(round(sum(extrap_schools_wifi_needed),0) / round(sum(num_schools),0),2) as extrap_schools_need_wifi_perc,
count(esh_id) as num_districts
*/
select *
from responses_to_cross_yr
