with dropped_apps as (
  select
    bi16.billed_entity_number, bi16.application_number,
    bi16.applicant_type, bi16.category_one_discount_rate, bi16.urban_rural_status
  from fy2016.basic_informations bi16
  left join fy2017.basic_informations bi17
  on bi16.billed_entity_number = bi17.billed_entity_number
  where bi17.billed_entity_number is null
 ),

dropped_types as (
	select
		da.billed_entity_number,
		da.application_number,
		da.applicant_type,
		da.category_one_discount_rate,
		da.urban_rural_status,
		sum(case
				when frns.service_type ilike '%internal%'
					then 1
				else 0
			end) as c2_app,
		sum(case
				when frns.service_type ilike '%internet%'
					then 1
				else 0
			end) as internet_frns,
		sum(case
				when frns.service_type ilike '%voice%'
					then 1
				else 0
			end) as voice_frns
	from dropped_apps da
	left join fy2016.frns
	on da.application_number = frns.application_number
	group by 1,2,3,4,5
),

dropped_categories as (
	select
		case
			when c2_app > 0
				then 'c2 app'
			when internet_frns > 0 and voice_frns = 0
				then 'internet only'
			when internet_frns = 0 and voice_frns > 0
				then 'voice only'
			else 'internet and voice'
		end as category,
		billed_entity_number,
		application_number,
		applicant_type,
		category_one_discount_rate,
		urban_rural_status
	from dropped_types
),

dropped_app_categories as (
	select 	billed_entity_number,
			array_to_string(array_agg(distinct applicant_type),';') as applicant_type,
			avg(category_one_discount_rate::numeric) as category_one_discount_rate,
			array_to_string(array_agg(distinct urban_rural_status),';') as urban_rural_status,
			sum(case
					when category = 'c2 app'
						then 1
					else 0
				end) as c2_app,
			sum(case
					when category = 'internet only'
						then 1
					else 0
				end) as internet_only,
			sum(case
					when category = 'voice only'
						then 1
					else 0
				end) as voice_only,
			sum(case
					when category = 'internet and voice'
						then 1
					else 0
				end) as internet_and_voice

	from dropped_categories
	group by 1
),

dropped_app_recipients as (
	select distinct
		case
			when c2_app+voice_only > 0 and internet_only+internet_and_voice=0
				then 'c2 or voice only'
			when c2_app+voice_only+internet_and_voice > 0
				then 'partially c2 or voice'
			else 'internet only'
		end as category,
		dac.*,
		ros.ben as recipient_ben
	from dropped_app_categories dac
	left join fy2016.recipients_of_services ros
	on dac.billed_entity_number = ros.applicant_ben
)

select
	category,
	count(distinct billed_entity_number) as num_applicants,
	count(distinct 	case
						when applicant_type ilike '%library%'
							then billed_entity_number
					end) as num_library_applicants,
	count(distinct 	case
						when applicant_type ilike '%school%'
							then billed_entity_number
					end) as num_instructional_applicants,
	count(distinct 	case
						when applicant_type = 'Consortium'
							then billed_entity_number
					end) as num_consortium_applicants,
	count(distinct 	case
						when  category_one_discount_rate <= 50
							then billed_entity_number
					end) as dr_50_or_less_applicants,
	count(distinct 	case
						when  category_one_discount_rate > 50 and category_one_discount_rate <= 70
							then billed_entity_number
					end) as dr_50_to_70_applicants,
	count(distinct 	case
						when  category_one_discount_rate > 70
							then billed_entity_number
					end) as dr_gt_70_applicants,
	count(distinct 	case
						when  urban_rural_status = 'Urban'
							then billed_entity_number
					end) as urban_applicants,
	count(distinct 	case
						when  urban_rural_status = 'Rural'
							then billed_entity_number
					end) as rural_applicants,
	count(*) as num_recipients,
	sum(case
			when ros.recipient_ben is null
				then 1
			else 0
		end) as num_recipients_dropped

from dropped_app_recipients dar
left join (
	select distinct ben as recipient_ben
	from fy2017.recipients_of_services
) ros
on dar.recipient_ben = ros.recipient_ben
group by 1
order by 1