select 	ci.postal_cd,
		ci.parent_entity_name,
		ci.parent_entity_number as parent_entity_id
		/*case
				when t.label = 'sufficient_wifi'
				  then 0
				when t.label = 'insufficient_wifi'
				  then 1
				when ci.child_wifi ilike ('%Sometimes%','%Never%')
					then 1
				else 0
			end as count_wifi_needed*/

from fy2017.connectivity_informations ci

left join public.tags t
on ci.parent_entity_number::varchar = t.taggable_id::varchar
and t.label in ('sufficient_wifi', 'insufficient_wifi')
and t.deleted_at is null
and funding_year = 2017

/*left join salesforce.account eb_parent
on ci.parent_entity_number = eb_parent.ben__c*/
left join public.fy2017_districts_demog_matr dd
on ci.id::varchar = dd.esh_id::varchar

/*left join public.tags t
on dd.esh_id::varchar = t.taggable_id::varchar
and t.label in ('sufficient_wifi', 'insufficient_wifi')
and t.deleted_at is null
and funding_year = 2017*/

left join public.fy2017_schools_demog_matr sd
on ci.child_entity_number = sd.school_esh_id


/*left join salesforce.account eb_child
on ci.child_entity_number = eb_child.ben__c
left join public.fy2017_schools_demog_matr sd
on eb_child.entity_id__c = sd.school_esh_id::text::int*/

where dd.esh_id is not null
and sd.school_esh_id is not null

group by 	ci.postal_cd,
			ci.parent_entity_name,
			ci.parent_entity_number
