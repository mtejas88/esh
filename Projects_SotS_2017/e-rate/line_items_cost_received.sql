select 
	'bb, not erate received' as category,
	count(distinct line_item_id) as line_items,
	round(sum(line_item_district_mrc_unless_null*sr.months_of_service)/1000000,0) as cost,
	round(sum(line_item_district_mrc_unless_null*discount_rate::numeric/100*sr.months_of_service)/1000000,0) as funding
from fy2017_services_received_matr sr
join fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
join fy2017_esh_line_items_v li
on sr.line_item_id = li.id
left join fy2017.frns
on li.frn = frns.frn
where sr.broadband
and sr.recipient_include_in_universe_of_districts
and district_type = 'Traditional'
and sr.inclusion_status != 'dqs_excluded'
and sr.erate = false
group by 1

UNION

select 
	'bb, special construction received' as category,
	count(distinct line_item_id) as line_items,
	round(sum(line_item_district_mrc_unless_null*sr.months_of_service)/1000000,0) as cost,
	round(sum(line_item_district_mrc_unless_null*discount_rate::numeric/100*sr.months_of_service)/1000000,0) as funding
from fy2017_services_received_matr sr
join fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
join fy2017_esh_line_items_v li
on sr.line_item_id = li.id
left join fy2017.frns
on li.frn = frns.frn
where sr.broadband
and sr.recipient_include_in_universe_of_districts
and district_type = 'Traditional'
and sr.inclusion_status != 'dqs_excluded'
and case
	    when frns.fiber_sub_type = 'Special Construction'
	    or 'special_construction' = any(sr.open_flags)
	    OR 'special_construction_tag' = any(sr.open_tags)
			then true
		else false
	end
group by 1

UNION

select 
	'bb, clean received' as category,
	count(distinct line_item_id) as line_items,
	round(sum(line_item_district_mrc_unless_null*sr.months_of_service)/1000000,0) as cost,
	round(sum(line_item_district_mrc_unless_null*discount_rate::numeric/100*sr.months_of_service)/1000000,0) as funding
from fy2017_services_received_matr sr
join fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
join fy2017_esh_line_items_v li
on sr.line_item_id = li.id
left join fy2017.frns
on li.frn = frns.frn
where sr.broadband
and sr.recipient_include_in_universe_of_districts
and district_type = 'Traditional'
and sr.inclusion_status ilike '%clean%'
group by 1

UNION

select 
	'bb, received' as category,
	count(distinct line_item_id) as line_items,
	round(sum(line_item_district_mrc_unless_null*sr.months_of_service)/1000000,0) as cost,
	round(sum(line_item_district_mrc_unless_null*discount_rate::numeric/100*sr.months_of_service)/1000000,0) as funding
from fy2017_services_received_matr sr
join fy2017_districts_deluxe_matr dd
on sr.recipient_id = dd.esh_id
join fy2017_esh_line_items_v li
on sr.line_item_id = li.id
left join fy2017.frns
on li.frn = frns.frn
where sr.broadband
and sr.recipient_include_in_universe_of_districts
and district_type = 'Traditional'
and sr.inclusion_status != 'dqs_excluded'
group by 1

UNION

select 
	'c2, received' as category,
	NULL as line_items,
	round((sum(c2_prediscount_remaining_16) - sum(c2_prediscount_remaining_17))/1000000,0) as cost,
	round((sum(c2_postdiscount_remaining_16) - sum(c2_postdiscount_remaining_17))/1000000,0) as funding
from public.fy2017_districts_deluxe_matr
where include_in_universe_of_districts = true
and district_type = 'Traditional'
