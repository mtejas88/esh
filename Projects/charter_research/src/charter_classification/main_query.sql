
with entity_demog_big as (
-- classifies all entities using hybrid of entity table, dd, and SFDC 
-- note this will create duplicate records for entities that have more than one ben mapped to them
	select e.entity_id as entity_esh_id,
	eb.ben as entity_ben,
	e.postal_cd as entity_postal_cd,
	case
		-- districts
		when dd.district_type = 'Traditional' and dd.include_in_universe_of_districts = true
		then 'Traditional District'
		when dd.district_type = 'Charter' and dd.include_in_universe_of_districts_all_charters = true
		then 'Charter District'
		when dd.district_type = 'BIE' 
		then 'BIE District'
		when (dd.district_type = 'Charter' or dd.district_type = 'Traditional') 
			and dd.include_in_universe_of_districts_all_charters = false
		then 'Out District'
		-- consortia
		when e.entity_type = 'Consortium'
		then 'Consortium'
		-- schools
		when f.recordtypename__c = 'School' 
			and f.out_of_business__c = false
			and f.charter__c = true
		then 'Charter School'
		when f.recordtypename__c = 'School' 
			and f.out_of_business__c = false
			and f.charter__c = false
		then 'School'
		-- district office, most are actually just district esh_ids but for the few that aren't 
		when f.recordtypename__c = 'District Office'
			and f.out_of_business__c = false
			and dd.esh_id is null
		then 'District Office'
		-- currently keeping non instructional facility and non traditional together, might want to split later
		when (f.recordtypename__c = 'Non-Traditional Education Facility' or f.recordtypename__c = 'Non-Instructional Facility')
			and f.out_of_business__c = false
		then 'Other Location'
		when f.out_of_business__c = true
		then 'Out Facility'
		else 'Other'
	end as entity_class,
	case 
		when f.out_of_business__c = false and f.recordtypename__c = 'School'
		then f.campus__c
	end as entity_campus_id,
	-- parent district info for schools and other locations, duplicating for districts themselves to make things easier
	case 
		when dd.esh_id is not null
		then dd.esh_id::numeric
		else p_dd.esh_id::numeric
	end as parent_district_esh_id,
	case
		-- duplicated district info
		when dd.district_type = 'Traditional' and dd.include_in_universe_of_districts = true
		then 'Traditional District'
		when dd.district_type = 'Charter' and dd.include_in_universe_of_districts_all_charters = true
		then 'Charter District'
		when dd.district_type = 'BIE' 
		then 'BIE District'
		when (dd.district_type = 'Charter' or dd.district_type = 'Traditional') 
			and dd.include_in_universe_of_districts_all_charters = false
		then 'Out District'
		-- district info for schools and other locations 
		when p_dd.district_type = 'Traditional' and p_dd.include_in_universe_of_districts = true
		then 'Traditional District'
		when p_dd.district_type = 'Charter' and p_dd.include_in_universe_of_districts_all_charters = true
		then 'Charter District'
		when p_dd.district_type = 'BIE' 
		then 'BIE District'
		when (p_dd.district_type = 'Charter' or p_dd.district_type = 'Traditional') 
			and p_dd.include_in_universe_of_districts_all_charters = false
		then 'Out District'
	end as parent_district_class

	from public.entities e 

	left join public.entity_bens eb
	on eb.entity_id = e.entity_id

	left join public.fy2017_districts_deluxe_matr dd
	on dd.esh_id::numeric = e.entity_id

	left join salesforce.facilities__c f
	on f.esh_id__c::numeric = e.entity_id

	left join salesforce.account a
	on a.sfid = f.account__c

	left join public.fy2017_districts_deluxe_matr p_dd
	on p_dd.esh_id = a.esh_id__c
),

entity_demog as (select entity_esh_id,
	entity_ben,
	entity_class,
	entity_postal_cd,
	entity_campus_id,
	parent_district_esh_id,
	parent_district_class

	from entity_demog_big

	group by 
	entity_esh_id,
	entity_ben,
	entity_class,
	entity_postal_cd,
	entity_campus_id,
	parent_district_esh_id,
	parent_district_class
),


-- limit to campuses in regular districts that contain regular school
rs_campus as (select entity_campus_id,
	parent_district_esh_id

	from entity_demog 
	where entity_class = 'School'
	and parent_district_class = 'Traditional District'
),

-- limit to charter schools in regular districts
-- add in info about which share campus with regular school
cs_1 as (select
	ed.entity_esh_id as charter_esh_id,
	ed.parent_district_esh_id as district_esh_id,
	ed.entity_postal_cd as postal_cd,
	case 
		when rs_campus.entity_campus_id is null
		then false
		else true 
	end as shared_campus_reg

	from entity_demog ed 

	left join rs_campus 
	on rs_campus.entity_campus_id = ed.entity_campus_id
		and rs_campus.parent_district_esh_id = ed.parent_district_esh_id

	where ed.entity_class = 'Charter School'
	and ed.parent_district_class = 'Traditional District'
),

-- applicant to recipient relationship
-- note: intentionally using the least conservative method to define these relationships.
-- e.g. not limiting to broadband, not using allocations, not removing anything excluded or denied, adding current 2017
serv_big as (select u.applicant_ben,
		--applicant info
		ed_a.entity_esh_id as applicant_entity_id,
		ed_a.entity_class as applicant_entity_class,
		ed_a.parent_district_esh_id as applicant_district_entity_id,
		ed_a.parent_district_class as applicant_district_entity_class,
		-- recipient info
		u.ben as recipient_ben,
		ed_r.entity_esh_id as recipient_entity_id,
		ed_r.entity_class as recipient_entity_class,
		ed_r.parent_district_esh_id as recipient_district_entity_id,
		ed_r.parent_district_class as recipient_district_entity_class

		from fy2017.recipients_of_services u 
		
		left join entity_demog ed_a 
		on u.applicant_ben = ed_a.entity_ben 

		left join entity_demog ed_r
		on u.ben = ed_r.entity_ben
--commenting out because i think this might take too long
/*
	union 
		select u.applicant_ben,
		--applicant info
		ed_a.entity_esh_id as applicant_entity_id,
		ed_a.entity_class as applicant_entity_class,
		ed_a.parent_district_esh_id as applicant_district_entity_id,
		ed_a.parent_district_class as applicant_district_entity_class,
		-- recipient info
		u.ben as recipient_ben,
		ed_r.entity_esh_id as recipient_entity_id,
		ed_r.entity_class as recipient_entity_class,
		ed_r.parent_district_esh_id as recipient_district_entity_id,
		ed_r.parent_district_class as recipient_district_entity_class

		from fy2017.current_recipients_of_services u 
		
		left join entity_demog ed_a 
		on u.applicant_ben = ed_a.entity_ben 

		left join entity_demog ed_r
		on u.ben = ed_r.entity_ben */
),

serv as (select 
	applicant_entity_id,
	applicant_entity_class,
	applicant_district_entity_id,
	applicant_district_entity_class,
	recipient_entity_id,
	recipient_entity_class,
	recipient_district_entity_id,
	recipient_district_entity_class

	from serv_big

	group by applicant_entity_id,
	applicant_entity_class,
	applicant_district_entity_id,
	applicant_district_entity_class,
	recipient_entity_id,
	recipient_entity_class,
	recipient_district_entity_id,
	recipient_district_entity_class
),

applicant_recip_count as (select applicant_entity_id,
	count(distinct recipient_entity_id) as distinct_recipient

	from serv
	where applicant_entity_id != recipient_entity_id

	group by applicant_entity_id
),

-- limit to applicants that serve regular schools other than their districts
reg_serv as (select applicant_entity_id,
	recipient_district_entity_id

	from serv
	where recipient_entity_class = 'School'
	and recipient_district_entity_class = 'Traditional District'
	and applicant_entity_id != recipient_district_entity_id

	group by applicant_entity_id,
	recipient_district_entity_id
),


charter_recip_big as (select cs_1.charter_esh_id,
	cs_1.district_esh_id,
	cs_1.shared_campus_reg,
	cs_1.postal_cd,
	--file for themselves
	case
		when serv.applicant_entity_id = charter_esh_id
		then serv.applicant_entity_id
	end as applicant_self,
	case
		when serv.applicant_entity_id = charter_esh_id and applicant_recip_count.distinct_recipient > 0
		then serv.applicant_entity_id
	end as applicant_self_other_recips,
	--receive services from their district or reg school, district office in their district
	case
		when serv.applicant_district_entity_id = cs_1.district_esh_id
		and (serv.applicant_entity_class in ('School','District Office','Other Location','Traditional District'))
		then serv.applicant_entity_id
	end as applicant_own_district,
	--receive services from applicant that also serves regular districts
	case
		when reg_serv.applicant_entity_id = serv.applicant_entity_id
		then serv.applicant_entity_id
	end as applicant_servs_reg_schools,
	--receive services from another charter school in reg district other than self
	case 
		when serv.applicant_entity_class = 'Charter School' 
			and serv.applicant_district_entity_class = 'Traditional District'
			and serv.applicant_entity_id != charter_esh_id
		then serv.applicant_entity_id
	end as applicant_other_charter_school,
	--receive services from charter district
	case 
		when serv.applicant_district_entity_class = 'Charter District'
		then serv.applicant_entity_id
	end as applicant_charter_district,
	--receive services from consortia
	case 
		when serv.applicant_entity_class = 'Consortium'
		then serv.applicant_entity_id
	end as applicant_consortia,
	case
		when serv.applicant_entity_class = 'Consortium'
			and serv.applicant_entity_id not in (select applicant_entity_id from reg_serv)
		then serv.applicant_entity_id
	end as applicant_consoria_not_reg,
	serv.applicant_entity_id as all_applicants

	from cs_1
	left join serv 
	on serv.recipient_entity_id = cs_1.charter_esh_id

	left join reg_serv
	on reg_serv.recipient_district_entity_id = cs_1.district_esh_id

	left join applicant_recip_count
	on applicant_recip_count.applicant_entity_id = cs_1.charter_esh_id
),

charter_recip as (select charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants

	from charter_recip_big

	group by charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants
),

charter_line_item_big  as (select cr.*,
	a.line_item_id,
	case
	  when a.line_item_id in (select taggable_id
	                        from public.tags t
	                        where t.funding_year = 2017
	                        and t.deleted_at is null
	                        and t.taggable_type = 'LineItem'
	                        and t.label = 'charter_service')
	  then 1
	  else 0
	end as charter_service_tag

	from charter_recip cr

	left join fy2017.esh_allocations_v a
	on a.recipient_id = cr.charter_esh_id 
	  and cr.all_applicants = a.applicant_id
	  and a.broadband = true),

charter_line_item as (select charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	case 
		when charter_service_tag > 0
		then applicant_own_district
		else null 
	end as applicant_own_district_charter_tag,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants,
	line_item_id,
	charter_service_tag

	from charter_line_item_big

	group by charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants,
	line_item_id,
	charter_service_tag
),

charter_line_item_agg as (select charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	applicant_own_district_charter_tag,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants,
	count(line_item_id) as line_items,
	sum(charter_service_tag) as charter_service_line_items

	from charter_line_item

	group by charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	applicant_self,
	applicant_self_other_recips,
	applicant_own_district,
	applicant_own_district_charter_tag,
	applicant_servs_reg_schools,
	applicant_other_charter_school,
	applicant_charter_district,
	applicant_consortia,
	applicant_consoria_not_reg,
	all_applicants
),

charter_final_agg as (select charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd,
	count(distinct applicant_self) as applicant_self,
	count(distinct applicant_self_other_recips) as applicant_self_other_recips,
	count(distinct applicant_own_district) as applicant_own_district,
	count(distinct applicant_own_district_charter_tag) as applicant_own_district_charter_tag,
	count(distinct applicant_servs_reg_schools) as applicant_servs_reg_schools,
	count(distinct applicant_other_charter_school) as applicant_other_charter_school,
	count(distinct applicant_charter_district) as applicant_charter_district,
	count(distinct applicant_consortia) as applicant_consortia,
	count(distinct applicant_consoria_not_reg) as applicant_consoria_not_reg,
	count(distinct all_applicants) as all_applicants

	from charter_line_item_agg


	group by charter_esh_id,
	district_esh_id,
	shared_campus_reg,
	postal_cd
)


select *,
case
	when shared_campus_reg = true 
		and applicant_self = 0
		and applicant_charter_district = 0
		and applicant_consoria_not_reg =0
	then true
end as group_remain_1,
case
	when applicant_own_district > 0
	and applicant_own_district_charter_tag = 0
		and applicant_self = 0
		and applicant_charter_district = 0
		and applicant_consoria_not_reg =0
	then true
end as group_remain_2,
case
	when applicant_own_district_charter_tag > 0
		and applicant_self = 0
		and applicant_charter_district = 0
		and applicant_consoria_not_reg = 0
	then true
end as group_remain_3,
case
	when applicant_servs_reg_schools > 0
		and applicant_self = 0
		and applicant_charter_district = 0
		and applicant_consoria_not_reg = 0
	then true
end as group_remain_4,
case
	when applicant_self > 0
		and applicant_self_other_recips = 0
	then true
end as group_remove_5,
case 
	when applicant_consoria_not_reg > 0
	then true
end as group_remove_6,
case
	when shared_campus_reg = false
	and all_applicants = 0
	then true
end as group_remove_7,
case
	when applicant_self_other_recips > 0
	then true
end as group_together_8

from charter_final_agg

