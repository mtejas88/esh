/* charter population we care about */
with cs as (select d.esh_id::numeric as district_esh_id,
d.name as district_name,
f.esh_id__c::numeric as charter_esh_id,
f.name as charter_name

from salesforce.facilities__c f

inner join salesforce.account a
on a.sfid = f.account__c

inner join public.fy2017_districts_deluxe_matr d
on d.esh_id = a.esh_id__c

where f.charter__c = true
and f.recordtypename__c = 'School'
and f.out_of_business__c = false

and d.district_type = 'Traditional'
and d.include_in_universe_of_districts = true
),

/* faculity level info from salesforce to better classify other locations */
fac as (select d.esh_id::numeric as district_esh_id,
d.name as district_name,
f.esh_id__c::numeric as fac_esh_id,
f.name as fac_name,
case
	when f.recordtypename__c = 'School' and f.charter__c = true and d.district_type = 'Traditional' and d.include_in_universe_of_districts = true
	then 'Charter School'
	else f.recordtypename__c
end as fac_type,
d.district_type,
d.include_in_universe_of_districts

from salesforce.facilities__c f

left join salesforce.account a
on a.sfid = f.account__c

left join public.fy2017_districts_deluxe_matr d
on d.esh_id = a.esh_id__c

where f.esh_id__c is not null),

/* recipients of service relationships: intentionally using the least conservative way to define a recipient of service. 
e.g. not limiting to broadband or using allocations, 
adding current 2017, not removing anything excluded or denied */
rs as (select rs.applicant_ben,
rs.billed_entity_name as applicant_name,
eb_a.entity_type as applicant_esh_entity_type,
eb_a.entity_id as applicant_entity_id,
dd.include_in_universe_of_districts as applicant_district_universe,
dd.district_type as applicant_district_type,
rs.ben as recipient_ben,
rs.name as recipient_name,
eb_s.entity_type as recipient_esh_entity_type,
eb_s.entity_id as recipient_entity_id

from fy2017.recipients_of_services rs

left join public.entity_bens eb_a
on rs.applicant_ben = eb_a.ben

left join public.fy2017_districts_deluxe_matr dd
on dd.esh_id::numeric = eb_a.entity_id

left join public.entity_bens eb_s
on rs.ben = eb_s.ben

union 

select rs.applicant_ben,
rs.billed_entity_name as applicant_name,
eb_a.entity_type as applicant_esh_entity_type,
eb_a.entity_id as applicant_entity_id,
dd.include_in_universe_of_districts as applicant_district_universe,
dd.district_type as applicant_district_type,
rs.ben as recipient_ben,
rs.name as recipient_name,
eb_s.entity_type as recipient_esh_entity_type,
eb_s.entity_id as recipient_entity_id

from fy2017.current_recipients_of_services rs

left join public.entity_bens eb_a
on rs.applicant_ben = eb_a.ben

left join public.fy2017_districts_deluxe_matr dd
on dd.esh_id::numeric = eb_a.entity_id

left join public.entity_bens eb_s
on rs.ben = eb_s.ben),

/*pre table */
pre_1 as (select distinct 
cs.district_esh_id,
cs.district_name,
cs.charter_esh_id,
cs.charter_name,
rs.applicant_name,
rs.applicant_esh_entity_type,
rs.applicant_entity_id,
rs.applicant_district_universe,
rs.applicant_district_type,
--rs.recipient_name,
--rs.recipient_esh_entity_type,

-- info about applicant for charter school when they are recipients of service
case 
	when cs.charter_esh_id = rs.applicant_entity_id
	then rs.applicant_entity_id
	else null
end as self_applicant,
case 
	when rs.applicant_entity_id = cs.district_esh_id
	then rs.applicant_entity_id
	else null
end as own_district_applicant,
case 
	when rs.applicant_entity_id != cs.district_esh_id and applicant_district_universe = true and applicant_district_type = 'Traditional'
	then rs.applicant_entity_id
	else null
end as other_reg_district_applicant,
case 
	when (applicant_district_universe = false or applicant_district_type = 'Charter' or applicant_district_type = 'BIE')
	then rs.applicant_entity_id
	else null
end as other_chrtrbie_district_applicant,
case
	when rs.applicant_esh_entity_type = 'Consortium'
	then rs.applicant_entity_id
	else null
end as consortium_applicant,
-- note to self: if these are common, come back and dimension into regular school, charter in reg dist, charter etc. 
case 
	when rs.applicant_esh_entity_type = 'School' and cs.charter_esh_id != rs.applicant_entity_id
	then rs.applicant_entity_id
	else null
end as school_applicant,

-- note to self: if these are common, come back and dimension into NIF, District Office
case
	when rs.applicant_esh_entity_type = 'OtherLocation'
	then rs.applicant_entity_id
	else null
end as other_location_applicant

from cs 

-- information about charter schools when they are recipients of services
inner join rs 
on rs.recipient_entity_id = cs.charter_esh_id::numeric),
 
pre_2 as (

select district_esh_id,
district_name,
charter_esh_id,
charter_name,
count(distinct self_applicant) as self_applicant,
count(distinct own_district_applicant) as own_district_applicant,
count(distinct other_reg_district_applicant) as other_reg_district_applicant,
/*commenting out because there isn't currently any instance of this in the data */
--count(distinct other_chrtrbie_district_applicant) as other_chrtrbie_district_applicant,
count(distinct consortium_applicant) as consortium_applicant,
count(distinct school_applicant) as school_applicant,
count(distinct other_location_applicant) as other_location_applicant

from pre_1

group by district_esh_id,
district_name,
charter_esh_id,
charter_name)

select count(charter_esh_id) as charter,
count(distinct district_esh_id) as district

from pre_2

where own_district_applicant > 0