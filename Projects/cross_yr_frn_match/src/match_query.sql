with ben_match as 
/* identifies applicant_bens that only filed for 1 broadband line item in both years*/
	(select 
    oli.applicant_ben as ben

    from fy2016.line_items oli
    inner join public.fy2017_esh_line_items_v nli
    on oli.applicant_ben = nli.applicant_ben

    where oli.broadband = true
    and oli.erate = true
    and nli.broadband = true
    and nli.erate = true
    
    group by oli.applicant_ben

    having count(distinct oli.id) = 1 
    and count(distinct nli.id) = 1
),

frn_match as 
	(select oli.frn as old_frn
    from fy2017.frns nf
    inner join fy2016.line_items oli
    on oli.frn = nf.frn_number_from_the_previous_year
    inner join public.fy2017_esh_line_items_v nli
    on nf.frn = nli.frn
    where oli.broadband = true 
    and oli.erate = true
    and nli.broadband = true
    and nli.erate = true
    group by oli.frn
    having count(nli.id) = 1
    and count(oli.id) = 1
    and count(oli.frn) = 1--JH - if i take this out, the number of oli.frn's doesn't change, but doesn't hurt
    and count(nli.frn) = 1),--JH - if i take this out, the number of oli.frn's doesn't change, but doesn't hurt

union_match as 
/* identifies single line item FRNs that match across years
and unions this with results from previous ben matching*/
	(select 'frn' as match_type,
	frn_match.old_frn,
    nf.frn as new_frn
    from frn_match
    inner join fy2017.frns nf
    on nf.frn_number_from_the_previous_year = frn_match.old_frn
    inner join fy2016.line_items oli
    on oli.frn = frn_match.old_frn
    inner join public.fy2017_esh_line_items_v nli
    on nf.frn = nli.frn
    where oli.broadband = true 
    and oli.erate = true
    and nli.broadband = true
    and nli.erate = true
    group by frn_match.old_frn,
    nf.frn
   

    union 

    select 'applicant' as match_type,
    oli.frn as old_frn,
    nli.frn as new_frn

    from ben_match

    inner join fy2016.line_items oli 
    on oli.applicant_ben = ben_match.ben

    inner join public.fy2017_esh_line_items_v nli
    on nli.applicant_ben = ben_match.ben

    where oli.broadband = true
    and oli.erate = true
    and nli.broadband = true 
    and nli.erate = true
),

distinct_match as 
/* removes duplicate instances where applicant ben only filed for one line item across both years 
and also used frn_number_from_the_previous_year field */
	(select
	array_agg(match_type) as match_type,
	old_frn,
    new_frn

    from union_match

    group by old_frn,
    new_frn
),


a as (select 
	match_type,
	/*OLD*/
	distinct_match.old_frn,
	eli.id as old_id,
	sr.inclusion_status as old_inclusion_status,
	oli.applicant_name as old_applicant,
	oli.applicant_postal_cd as old_postal_cd,
	case
		when sr.reporting_name is null
		then oli.service_provider_name
		else sr.reporting_name
	end as old_service_provider,
	oli.connect_type as old_connect_type,
	oli.function as old_function,
	oli.connect_category as old_connect_category, --JH - do you care about connect_type, or is connect_category good enough? maybe just weight connect_category more?
	sr.purpose as old_purpose,
	oli.consortium_shared as old_consortium_shared,
	oli.bandwidth_in_mbps as old_bandwidth,
	oli.num_lines::numeric as old_num_lines, /*convert to numeric to get rid of .0 characters, will later convert back to char to match new num lines*/
	case
		when oli.rec_elig_cost = 0
		then null
		else round(oli.rec_elig_cost)
	end as old_rec_elig_cost,
	case
		when oli.total_cost = 0
		then null
		else round(oli.total_cost)
	end as old_total_cost,
	oli.num_recipients as old_recipients,
	oli.num_open_flags as old_num_flags,
	case
		when array_length(oli.open_flag_labels,1) is null
		then '{NONE}'
		else oli.open_flag_labels 
	end as old_flags,
	case
		when array_length(oli.open_tag_labels,1) is null
		then '{NONE}'
		else oli.open_tag_labels
	end as old_tags,
	of.funding_request_nickname as old_frn_nickname,
	of.narrative as old_serv_descrip,
	/*NEW*/
	distinct_match.new_frn,
	nli.id as new_id,
	nli.applicant_name as new_applicant,
	nli.applicant_postal_cd as new_postal_cd,
	case
		when nli.reporting_name is null
		then nli.service_provider_name
		else nli.reporting_name
	end as new_service_provider, --JH - do you want to use reporting name?
	nli.connect_type as new_connect_type, --JH - do you care about connect_type, or is connect_category good enough? maybe just weight connect_category more?
	nli.function as new_function,
	nli.connect_category as new_connect_category,
	case
		when nli.purpose = 'Data connection(s) for an applicant’s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately'
		then 'Upstream'
		when nli.purpose = 'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)'
		then 'ISP'
		when nli.purpose = 'Data Connection between two or more sites entirely within the applicant’s network'
		then 'WAN'
		when nli.purpose = 'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider'
		then 'Internet'
		when nli.purpose = 'Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities'
		then 'Backbone'
		else nli.purpose
	end as new_purpose,
	nli.consortium_shared as new_consortium_shared,
	nli.bandwidth_in_mbps as new_bandwidth,
	nli.num_lines as new_num_lines,
	case
		when nli.rec_elig_cost = 0
		then null 
		else round(nli.rec_elig_cost)
	end as new_rec_elig_cost,
	case 
		when nli.total_cost = 0
		then null
		else round(nli.total_cost)
	end as new_total_cost,
	nli.num_recipients as new_recipients,
	nli.num_open_flags as new_num_flags,
	case 
		when array_length(nli.open_flag_labels,1) is null 
		then '{NONE}'
		else nli.open_flag_labels
	end as new_flags,
	case
		when array_length(nli.open_tag_labels,1) is null
		then '{NONE}'
		else nli.open_tag_labels
	end as new_tags,
	nf.funding_request_nickname as new_frn_nickname,
	nf.narrative as new_serv_descrip

	from distinct_match 

	inner join fy2016.line_items oli
	on oli.frn = distinct_match.old_frn

	inner join public.esh_line_items eli 
	on oli.id = eli.base_line_item_id

	inner join public.fy2016_services_received_matr sr
	on oli.id = sr.line_item_id

	inner join fy2016.frns of
	on of.frn = oli.frn

	inner join public.fy2017_esh_line_items_v nli
	on nli.frn = distinct_match.new_frn

	inner join fy2017.frns nf
	on nf.frn = nli.frn

	where sr.recipient_include_in_universe_of_districts = true
	and nli.broadband = true
	and eli.funding_year = 2016)

select distinct
match_type::varchar,
old_frn,
new_frn,
old_id,
new_id,
old_inclusion_status,
case
	when new_num_flags > 0
	then 'dirty'
	else 'clean'
end as new_status,
/*if fields always match or never match - they can be removed from match score to make it more informative
intentionally not including cost for now as it is not a field we edit often */
(	
	+ (case when old_service_provider = new_service_provider then 200 else 0 end)
	+ (case when old_num_lines::char = new_num_lines then 100 else 0 end) -- we also did a partial match for this last year
	+ (case when @(old_rec_elig_cost - new_rec_elig_cost)/new_rec_elig_cost <= .05 then 50 else 0 end)
	+ (case when old_bandwidth = new_bandwidth then 10 else 0 end)
	+ (case when old_purpose = new_purpose then 5 else 0 end)
	+ (case when old_connect_category = new_connect_category then 2 else 0 end)
	--+ (case when old_recipients = new_recipients then 1 else 0 end) --JH - if you want to make it more detailed, you could check that all recips are the same
	+ (case when @(old_total_cost - new_total_cost)/new_total_cost <= .05 then 1 else 0 end)
	)
as match_score,
old_postal_cd as postal_cd,
old_applicant,
/*updated fields will only include new data if it differs from the old to not */
case
	when old_applicant != new_applicant
	then new_applicant
end as updated_applicant,
old_service_provider,
case
	when old_service_provider != new_service_provider
	then new_service_provider
end as updated_service_provider,
old_connect_type,
case
	when old_connect_type != new_connect_type
	then new_connect_type
end as updated_connect_type,
old_function,
case
	when old_function != new_function
	then new_function
end as updated_function,
old_connect_category,
case 
	when old_connect_category != new_connect_category
	then new_connect_category
end as updated_connect_category,
old_purpose,
case
	when old_purpose != new_purpose
	then new_purpose
end as updated_purpose,
old_consortium_shared,
case
	when old_consortium_shared != new_consortium_shared
	then new_consortium_shared
end as updated_consortium_shared,
old_bandwidth,
case
	when old_bandwidth != new_bandwidth
	then new_bandwidth
end as updated_bandwidth,
old_num_lines,
case
	when old_num_lines::char != new_num_lines
	then new_num_lines
end as updated_num_lines,
old_rec_elig_cost,
case
	when @(old_rec_elig_cost - new_rec_elig_cost)/new_rec_elig_cost > .05
	then new_rec_elig_cost
end as updated_rec_elig_cost,
old_total_cost,
case 
	when @(old_total_cost - new_total_cost)/new_total_cost > .05
	then new_total_cost
end as updated_total_cost,
old_recipients,
case
	when old_recipients != new_recipients
	then new_recipients
end as updated_recipients,
old_flags::varchar,
new_flags::varchar,
old_tags::varchar,
new_tags::varchar,
old_frn_nickname::varchar, 
new_frn_nickname::varchar,
old_serv_descrip::varchar,
new_serv_descrip::varchar

from a 
where old_inclusion_status like '%clean%' /*there is also some value in reviewing dirty or exclude cross year matches, maybe as separate work stream?*/

order by old_applicant asc