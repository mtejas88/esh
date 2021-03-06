/*
Author: Greg Kurzhals
Created On Date: 11/02/2015
Last Modified Date: 01/05/2016
Name of QAing Analyst(s): Justine Schott
Purpose: A version of the "Services Received" query that returns a list of services where the applicant and recipient appear to be located 
in different states - designed to identify potential misallocations and incorrect BEN-NCES mappings
Methodology: Applies allocation logic and formatting of "Services Received" query, and filters for rows where the postal_cd of the recipient 
is different from either the line_items or districts table postal_cd field.
Dependencies:"Services Received by Each District" - https://modeanalytics.com/educationsuperhighway/reports/7fe09fee682e
*/

--Returns esh_id, district_esh_id, and postal_cd for any potential recipient in our population (schools and districts, other locations excluded)
with district_lookup as (
  select esh_id, district_esh_id, postal_cd
  from schools
  union
  select esh_id, esh_id as district_esh_id, postal_cd
  from districts
),

--Returns allocations table, with district_esh_id of the recipient entity included in each row
ad as (
  select district_esh_id, a.*
  from allocations a
  join district_lookup dl
  on dl.esh_id = a.recipient_id
)

select y.id as "line_item_id",
ad.district_esh_id as "recipient_district_id",
x.name as "recipient_district",
x.postal_cd as "district_postal_cd",
ad.recipient_name,
ad.recipient_id,
ad.recipient_postal_cd,
y.applicant_name,
y.applicant_ben,
y.applicant_postal_cd

    from ad

    left join districts x
    on ad.district_esh_id=x.esh_id

    left join line_items y
    on ad.line_item_id=y.id
    
    /*Isolating all broadband line items where the recipient's postal_cd differs from either of the two postal_cd fields corresponding 
    to the applicant*/
    where y.broadband=true and x.include_in_universe_of_districts=true
    and (ad.recipient_postal_cd!=y.applicant_postal_cd OR x.postal_cd!=y.applicant_postal_cd)
