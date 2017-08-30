with wifi_status as (
	--suffiency as of 7/24
	--copy of wifi connectivity informations except only using tags pre-7/24

	select 	ci.postal_cd,
			ci.parent_entity_name,

	(select distinct (eb_parent.entity_id) as parent_entity_id),
			--eb_parent.entity_id as parent_entity_id, using distinct entity id above and commenting non unique column
			sum(case
					when t.label = 'sufficient_wifi'
					  then 0
					when t.label = 'insufficient_wifi'
					  then 1
					when child_wifi in ('Sometimes','Never')
						then 1
					else 0
				end) as count_wifi_needed

	from fy2017.connectivity_informations ci


	left join public.entity_bens eb_parent

	on ci.parent_entity_number = eb_parent.ben

	left join public.fy2017_districts_demog_matr dd

	on eb_parent.entity_id = dd.esh_id::text::int

	left join public.tags t
	on dd.esh_id::text::int = t.taggable_id
	and t.label in ('sufficient_wifi', 'insufficient_wifi')
	and t.deleted_at is null
	and t.funding_year = 2017
	and t.created_at::date <= '2017-07-24'::date

	left join public.entity_bens eb_child   /*no funding year column in this*/
	on ci.child_entity_number = eb_child.ben

	left join public.fy2017_schools_demog_matr sd
	on eb_child.entity_id = sd.school_esh_id::text::int

	where dd.esh_id is not null
	and sd.school_esh_id is not null

	group by 	ci.postal_cd,
				ci.parent_entity_name,
				eb_parent.entity_id

),

temp as (

	select 
		d17.esh_id,
		d16.needs_wifi as needs_wifi_16,
		d17.needs_wifi as needs_wifi_17,
		CASE 	WHEN w.count_wifi_needed > 0 THEN true
	   			WHEN w.count_wifi_needed = 0 THEN false
	        	ELSE null
			   	END as needs_wifi_updated_17


	from public.fy2017_districts_deluxe_matr d17

	join public.fy2016_districts_deluxe_matr d16
	on d17.esh_id = d16.esh_id

	left join wifi_status w
	on d17.esh_id = w.parent_entity_id::varchar

	where d17.include_in_universe_of_districts
	and d17.district_type = 'Traditional'

)

select 
	case 
	    when needs_wifi_16 = false
	      then 'Sufficient'
	    when needs_wifi_16 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_16,
  	case 
	    when needs_wifi_updated_17 = false
	      then 'Sufficient'
	    when needs_wifi_updated_17 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_17,
	case 
	    when sr.q7_wi_fi_sufficiency__c in ('Completely', 'Mostly')
	      then 'Sufficient'
	    when sr.q7_wi_fi_sufficiency__c in ('Never', 'Sometimes')
	      then 'Insufficient'
	    else 'No response'
  	end as summary_response,
  	count(distinct esh_id) as num_districts

from salesforce.survey_response__c sr

join salesforce.account a
on sr.account__c = a.sfid

join temp
on a.esh_id__c = temp.esh_id

group by 1, 2, 3
order by 1, 2, 3
