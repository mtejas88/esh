with a as (select d.esh_id as district_esh_id,
count(f.esh_id__c) as charter_schools

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

group by d.esh_id)

select
count(district_esh_id) as districts,
sum(charter_schools) as charter_schools

from a