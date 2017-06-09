with new_apps as (
  select
    bi17.billed_entity_number,
    bi17.application_number
  from fy2017.basic_informations bi17
  left join fy2016.basic_informations bi16
  on bi17.billed_entity_number = bi16.billed_entity_number
  where bi17.billed_entity_number is not null and bi16.billed_entity_number is null
 ),

new_types as (
	select
		da.billed_entity_number,
		da.application_number,
		sum(case
				when frki.service_type ilike '%internal%'
					then 1
				else 0
			end) as c2_app,
		sum(case
				when frki.service_type ilike '%internet%'
					then 1
				else 0
			end) as internet_frns,
		sum(case
				when frki.service_type ilike '%voice%'
					then 1
				else 0
			end) as voice_frns
	from new_apps da
	left join fy2017.frns frki
	on da.application_number = frki.application_number
	group by 1,2
),

new_categories as (
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
	from new_types
),

new_app_categories as (
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

	from new_categories
	group by 1
),

new_app_recipients as (
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
	from new_app_categories dac
	left join fy2017.recipients_of_services ros
	on dac.billed_entity_number = ros.applicant_ben
),

dropped_1516 as (
	select *
	from(
	  select
	    case
	      when bi16.billed_entity_number is null
	        then bi15."BEN"
	      else bi16.billed_entity_number
	    end as billed_entity_number,
	    count(distinct  bi16.application_number) as applications_2016,
	    count(distinct  bi15."Application Number") as applications_2015
	  from fy2016.basic_informations bi16
	  full outer join public.fy2015_basic_information_and_certifications bi15
	  on bi16.billed_entity_number = bi15."BEN"
	  group by 1
	) applicants
	where applications_2016 = 0
)

select
	dar.category,
	count(distinct dar.billed_entity_number) as num_applicants,
	count(*) as num_recipients

from new_app_recipients dar
left join (
	select distinct ben as recipient_ben
	from fy2017.recipients_of_services
) ros
on dar.recipient_ben = ros.recipient_ben
left join dropped_1516
on dar.billed_entity_number = dropped_1516.billed_entity_number
where dropped_1516.billed_entity_number is null
group by 1
order by 1