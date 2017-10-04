with cs as (select d.esh_id as district_esh_id,
d.name as district_name,
f.esh_id__c as charter_esh_id,
f.name as charter_name,
f.campus__c as campus_id

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

rs as (select d.esh_id as district_esh_id,
f.esh_id__c as regular_school_esh_id,
f.campus__c as campus_id

from salesforce.facilities__c f

inner join salesforce.account a
on a.sfid = f.account__c

inner join public.fy2017_districts_deluxe_matr d
on d.esh_id = a.esh_id__c

where f.recordtypename__c = 'School'
and f.out_of_business__c = false
and f.charter__c = false

and d.district_type = 'Traditional'
and d.include_in_universe_of_districts = true
),
overlap as (
select distinct cs.*

from cs

inner join rs
on rs.district_esh_id = cs.district_esh_id
and rs.campus_id = cs.campus_id),
no_overlap as (
select distinct cs.*

from cs

left join rs
on rs.district_esh_id = cs.district_esh_id
and rs.campus_id = cs.campus_id

where rs.district_esh_id is null 
and rs.campus_id is null)

select 
o.*,
true as campus_reg_school

from overlap o

union 

select
n.*,
false as campus_reg_school

from no_overlap n







