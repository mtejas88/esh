select 
ea.id,
ea.line_item_id,
ea.base_allocation_id,
	
	eli.application_number,
	eli.frn_complete,
	eli.broadband,
	eli.applicant_ben,
	ab.entity_id as applicant_id, 
	ab.entity_type as applicant_type,

ea.recipient_ben,

	rb.entity_id as recipient_id,
	rb.entity_type as recipient_type,
	e.name as recipient_name,
	e.postal_cd as recipient_postal_cd,

ea.cat_2_cost,
ea.num_lines_to_allocate,
ea.original_num_lines_to_allocate,
ea.created_at,
ea.updated_at

from public.esh_allocations ea

left join public.esh_line_items eli 
on eli.id = ea.line_item_id

left join public.entity_bens ab
on ab.ben = eli.applicant_ben

left join public.entity_bens rb 
on rb.ben = ea.recipient_ben

left join public.entities e 
on e.entity_id = rb.entity_id

where ea.funding_year = 2017
and eli.funding_year = 2017