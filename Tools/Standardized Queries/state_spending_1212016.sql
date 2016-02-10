/*
Author: Sneha Narayanan
Created On Date: 1/21/2016
Last Modified Date: 1/21/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: To calculate total cost, total C1 cost, total C2 cost; total e-rate funding for the same categories;
average C2 cost per student, and % of entities meeting C2 budget by STATE. These are summary stats and will be 
most helpful for connectivity reports and other state engagements.
*/
with distinct_application_entities as (
	select distinct
	  "Application Number",
	  "Full/Part Count",
	  "Cat 1 Disc Rate",
	  "Cat 2 Disc Rate"

	from public.fy2015_discount_calculations dc

	where "Stud NSLP Perc" != '0'
),
application_discount_rate as (
	select
		"Application Number",
		round(sum( "Full/Part Count"::numeric * "Cat 1 Disc Rate"::numeric)/sum("Full/Part Count"::numeric),0) as agg_c1_discount_rate,
		round(sum( "Full/Part Count"::numeric * "Cat 2 Disc Rate"::numeric)/sum("Full/Part Count"::numeric),0) as agg_c2_discount_rate,
		sum("Full/Part Count"::numeric) as num_students_usac

	from distinct_application_entities

	group by "Application Number"
	having sum("Full/Part Count"::numeric) > 0
),
application_costs_by_category as (
  select 
    postal_cd,
    ben,
    --case when num_students = 'No data' then null else num_students::numeric end as 
    num_students,
    application_number,
    sum (case when service_category not in ('INTERNAL CONNECTIONS', 'INTERNAL CONNECTIONS MIBS', 'INTERNAL CONNECTIONS MNT') then total_cost end) as category_1_cost,
    sum (case when service_category in ('INTERNAL CONNECTIONS', 'INTERNAL CONNECTIONS MIBS', 'INTERNAL CONNECTIONS MNT') then total_cost end) as category_2_cost

  from public.line_items
  
  where report_app_type = true
  and report_private = true

  group by
    postal_cd,
    ben,
    num_students,
    application_number
),
application_funding_by_category as (
	select 
		application_discount_rate.*,
		application_costs_by_category.*,
		application_discount_rate.agg_c1_discount_rate / 100 * application_costs_by_category.category_1_cost as category_1_funding,
		application_discount_rate.agg_c2_discount_rate / 100 * application_costs_by_category.category_2_cost as category_2_funding

	from application_discount_rate
	left join application_costs_by_category
	on application_discount_rate."Application Number" = application_costs_by_category.application_number
	
	where postal_cd = 'IL' or 'All' = 'IL'
),
ben_funding_by_category as (
	select 
		postal_cd,
		ben,
		num_students,
		sum(category_1_cost) as ben_category_1_cost,
		sum(category_2_cost) as ben_category_2_cost,
		sum(category_1_funding) as ben_category_1_funding,
		sum(category_2_funding) as ben_category_2_funding,
		case when num_students > 0 then
		  sum(category_2_cost) / num_students 
		else NULL
		end as ben_category_2_cost_per_student,
		sum(agg_c1_discount_rate*num_students_usac)/sum(num_students_usac) as agg_c1_discount_rate,
		sum(agg_c2_discount_rate*num_students_usac)/sum(num_students_usac) as agg_c2_discount_rate,
		sum(num_students_usac) as num_students_usac


	from application_funding_by_category

	group by
		postal_cd,
		ben,
		num_students
),
all_students_in_state as (
	select 
		"LSTATE",
		sum(case when "MEMBER" > 0 then "MEMBER" end) as total_num_students

	from ag121a
	where "TYPE" in (1,2,7)

	group by
		"LSTATE"
)

select
	postal_cd,
	(sum(ben_category_1_cost) + sum(ben_category_2_cost))/1000000 as "Total E-Rate Cost ($M)",
	sum (ben_category_1_cost)/1000000 as "Total C1 E-Rate Cost ($M)",
	sum(ben_category_2_cost)/1000000 as "Total C2 E-Rate Cost ($M)",
	all_students_in_state.total_num_students*150/1000000::decimal as "Total C2 State Budget based on NCES ($M)",
	(sum(ben_category_1_funding) + sum(ben_category_2_funding))/1000000 as "Total E-Rate Funding ($M)",
	sum (ben_category_1_funding)/1000000 as "Total C1 E-rate Funding ($M)",
	sum(ben_category_2_funding)/1000000 as "Total C2 E-Rate Funding ($M)",
	sum(case when num_students is not null then ben_category_2_cost end) / sum (num_students) as "Average C2 Cost per Student",
	count(case when ben_category_2_cost_per_student >= 150 then ben end)/count(case when num_students is not null then ben end)::numeric 
		as "Pct of Entities Meeting C2 Budget",
	sum(agg_c1_discount_rate*num_students_usac)/sum(num_students_usac) as agg_c1_discount_rate,
	sum(agg_c2_discount_rate*num_students_usac)/sum(num_students_usac) as agg_c2_discount_rate

from ben_funding_by_category
left join all_students_in_state
on ben_funding_by_category.postal_cd = all_students_in_state."LSTATE"

group by postal_cd, all_students_in_state.total_num_students
order by postal_cd