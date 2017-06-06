with dropped_apps as (
  select
    bi16.billed_entity_number, bi16.application_number
  from fy2016.basic_informations bi16
  left join fy2017.basic_informations bi17
  on bi16.billed_entity_number = bi17.billed_entity_number
  where bi17.billed_entity_number is null
 ),

dropped_types as (
	select
		da.billed_entity_number,
		da.application_number,
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
	group by 1,2
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
		application_number
	from dropped_types
),

dropped_app_categories as (
	select 	billed_entity_number,
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
)

select
	case
		when c2_app+voice_only > 0 and internet_only+internet_and_voice=0
			then 'c2 or voice only'
		when c2_app+voice_only+internet_and_voice > 0
			then 'partially c2 or voice'
		else 'internet only'
	end as category,
	count(*)
from dropped_app_categories
group by 1