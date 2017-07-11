with lca as (
	select
		fr.application_number,
	    sum(original_requested_amount::numeric) as lowcost_c1_funding_requested,
	    sum(case
	    		when frn_status = 'Denied'
	    			then 1
	    		else 0
	    	end) as frns_denied
	from funding_requests_2016_and_later fr
	join fy2016.basic_informations bi
	on fr.application_number = bi.application_number
	where category_of_service::numeric = 1
	and fr.funding_year != ''
	and fr.funding_year::numeric = 2016
	and fr.original_requested_amount != ''
	and window_status = 'In Window'
	and bi.total_funding_year_commitment_amount_request::numeric < 25000
	group by 1
)

select
	frns_denied > 0 as application_denied,
	count(*) as apps,
	sum(lowcost_c1_funding_requested) as requested
from lca
group by 1