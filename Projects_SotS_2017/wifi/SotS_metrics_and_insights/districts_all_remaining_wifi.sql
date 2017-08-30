with receives_erate as (
select distinct recipient_id
from public.fy2017_services_received_matr
where recipient_include_in_universe_of_districts = true
and inclusion_status != 'dqs_excluded'
and erate = true
)

select 
count(	case 
			when c2_prediscount_remaining_17 = c2_prediscount_budget_15 
				then esh_id 
		end) as used_no_budget,
count(	case 
			when c2_prediscount_remaining_17 = c2_prediscount_budget_15 
				then esh_id 
		end)::numeric / count(esh_id)::numeric as perc_used_no_budget,
sum(	case 
			when c2_prediscount_remaining_17 = c2_prediscount_budget_15 
				then num_students 
		end) as students_used_no_budget,
sum(c2_postdiscount_remaining_17) as all_funds_remaining,
count(	case 
			when c2_prediscount_remaining_17 = c2_prediscount_budget_15 
			 and receives_erate.recipient_id is not null
				then esh_id 
		end) as used_no_budget_and_receives_services,
sum(	case 
			when c2_prediscount_remaining_17 = c2_prediscount_budget_15 
			 and receives_erate.recipient_id is not null
				then num_students 
		end) as students_used_no_budget_and_receives_services,
count(	case 
			when c2_prediscount_remaining_17 >= .5 * c2_prediscount_budget_15 
				then esh_id 
		end) as distrcts_with_at_least_half_funds_remaining,
count(	case 
			when c2_prediscount_remaining_17 >= .5 * c2_prediscount_budget_15 
				then esh_id 
		end)::numeric / count(esh_id) as perc_distrcts_with_at_least_half_funds_remaining

from public.fy2017_districts_deluxe_matr

left join receives_erate
on fy2017_districts_deluxe_matr.esh_id = receives_erate.recipient_id

where include_in_universe_of_districts
and district_type = 'Traditional'

