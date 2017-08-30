with app_recip_lookup as (
	select distinct
		eb_applicant.ben::varchar as applicant_ben,
		dd.esh_id as recipient_esh_id
	from public.fy2017_services_received_matr sr
	join public.entity_bens eb_applicant
	on sr.applicant_id = eb_applicant.entity_id
	join public.entity_bens eb_recipient
	on sr.recipient_id = eb_recipient.entity_id::varchar
	join public.fy2017_districts_deluxe_matr dd
	on sr.recipient_id = dd.esh_id
	
	where sr.inclusion_status != 'dqs_excluded'
	and sr.erate = true
	and dd.include_in_universe_of_districts = true
	and dd.district_type = 'Traditional'

	UNION

	select distinct
		eb_applicant.ben::varchar as applicant_ben,
		dd.esh_id as recipient_esh_id
	from public.fy2017_district_lookup_matr dl
	join public.entity_bens eb_applicant
	on dl.esh_id = eb_applicant.entity_id::varchar
	join public.entity_bens eb_recipient
	on dl.district_esh_id = eb_recipient.entity_id::varchar
	join public.fy2017_districts_deluxe_matr dd
	on dl.district_esh_id = dd.esh_id

	where dd.include_in_universe_of_districts = true
	and dd.district_type = 'Traditional'
),

wifi_recipients as (
	select distinct
		funding_year::numeric,
		count(distinct app_recip_lookup.recipient_esh_id) as num_recip_districts

	from public.funding_requests

	join app_recip_lookup
	on funding_requests.ben = app_recip_lookup.applicant_ben

	where cmtd_category_of_service not in ('VOICE SERVICES','INTERNET ACCESS', 'TELCOMM SERVICES')
	and cmtd_category_of_service is not null
	and commitment_status != 'NOT FUNDED'
	and application_type not in ('LIBRARY')
	and funding_year::numeric <= 2014

	group by funding_year::numeric

)

select 
funding_requests.funding_year::numeric,
sum(cmtd_total_cost::numeric) as total_cost,
count(distinct funding_requests.ben) as num_applicants,
wifi_recipients.num_recip_districts,
wifi_recipients.num_recip_districts / (
	select count(esh_id)::numeric
	from public.fy2017_districts_deluxe_matr
	where include_in_universe_of_districts = true
	and district_type = 'Traditional'
	) as perc_recipients

from public.funding_requests

left join wifi_recipients
on funding_requests.funding_year::numeric = wifi_recipients.funding_year::numeric

where cmtd_category_of_service not in ('VOICE SERVICES','INTERNET ACCESS', 'TELCOMM SERVICES')
and cmtd_category_of_service is not null
and commitment_status != 'NOT FUNDED'
and application_type not in ('LIBRARY')
and funding_requests.funding_year::numeric <= 2014

group by
	funding_requests.funding_year::numeric,
	wifi_recipients.num_recip_districts
