select 
  d.esh_id,
  d.name,
  d.city,
  d.postal_cd,
  d.district_size,
  d.locale,
  d.num_students,
  d.discount_rate_c2,
  d.c2_prediscount_budget_15,
  d.c2_prediscount_remaining_17,
  d.c2_postdiscount_remaining_17,
  a.outreach_status__c

from public.fy2017_districts_deluxe_matr d

left join salesforce.account a
on d.esh_id = a.esh_id__c

where d.include_in_universe_of_districts = true
and d.district_type = 'Traditional'