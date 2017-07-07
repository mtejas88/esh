with dropped_apps as (
  select
    bi15."BEN" as billed_entity_number,
    bi15."Application Number" as application_number,
    bi15."App Type" as applicant_type,
    case
      when dc.category_one_discount_rate is null
        then frki.category_one_discount_rate
      else dc.category_one_discount_rate
    end as category_one_discount_rate,
    case
      when dc.urban_rural_status = 'Y'
        then 'Urban'
      when dc.urban_rural_status = 'N' or dc.urban_rural_status is null
        then 'Rural'
      else 'Urban;Rural'
    end as urban_rural_status
  from public.fy2015_basic_information_and_certifications bi15
  left join (
  	select "Application Number",
  			avg(case
	  				when "FRN Service Type" ilike '%voice%'
	  					then "Discount"::numeric + 20
	  				when "FRN Service Type" ilike '%internal%' and "Discount"::numeric = 85
	  					then 90
	  				else "Discount"::numeric
	  			end) as category_one_discount_rate
  	from public.fy2015_funding_request_key_informations
  	group by 1
  ) frki
  on bi15."Application Number" = frki."Application Number"
  left join (
  	select "BEN",
  			array_to_string(array_agg(distinct "Urban or Rural Mod"),';') as urban_rural_status,
  			avg("Cat 1 Disc Rate"::numeric) as category_one_discount_rate
  	from public.fy2015_discount_calculations
  	group by 1
  ) dc
  on bi15."BEN" = dc."BEN"
  left join fy2016.basic_informations bi16
  on bi15."BEN" = bi16.billed_entity_number
  where bi16.billed_entity_number is null and bi15."BEN" is not null
 ),

dropped_types as (
	select
		da.billed_entity_number,
		da.application_number,
		da.applicant_type,
		da.category_one_discount_rate,
		da.urban_rural_status,
		sum(case
				when frki."FRN Service Type" ilike '%internal%'
					then 1
				else 0
			end) as c2_app,
		sum(case
				when frki."FRN Service Type" ilike '%internet%'
					then 1
				else 0
			end) as internet_frns,
		sum(case
				when frki."FRN Service Type" ilike '%voice%'
					then 1
				else 0
			end) as voice_frns
	from dropped_apps da
	left join public.fy2015_funding_request_key_informations frki
	on da.application_number = frki."Application Number"
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

added_1617 as (
	select
	  case
	    when applications_2017 = 0
	      then 'dropped off'
	    when applications_2016 = 0
	      then 'new'
	    when applications_2016 > applications_2017
	      then 'less apps'
	    when applications_2016 < applications_2017
	      then 'more apps'
	    else 'same both years'
	  end as category,
	  applicants.*
	from(
	  select
	    case
	      when bi16.billed_entity_number is null
	        then bi17.billed_entity_number
	      else bi16.billed_entity_number
	    end as billed_entity_number,
	    count(distinct  bi16.application_number) as applications_2016,
	    count(distinct  bi17.application_number) as applications_2017
	  from fy2016.basic_informations bi16
	  full outer join fy2017.basic_informations bi17
	  on bi16.billed_entity_number = bi17.billed_entity_number
	  group by 1
	) applicants
	where applications_2016 = 0
)

select
	a.billed_entity_number is not null as dropped_2016_added_2017,
	count(*)
from dropped_app_categories dac
left join added_1617 a
on dac.billed_entity_number = a.billed_entity_number
group by 1