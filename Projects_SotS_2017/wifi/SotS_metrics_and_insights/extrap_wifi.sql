with wifi_status as (
	--suffiency as of 7/24
	--copy of wifi connectivity informations except only using tags pre-7/24

	select 	ci.postal_cd,
			ci.parent_entity_name,

	(select distinct (eb_parent.entity_id) as parent_entity_id),
			--eb_parent.entity_id as parent_entity_id, using distinct entity id above and commenting non unique column
			sum(case
					when t.label = 'sufficient_wifi'
					  then 0
					when t.label = 'insufficient_wifi'
					  then 1
					when child_wifi in ('Sometimes','Never')
						then 1
					else 0
				end) as count_wifi_needed

	from fy2017.connectivity_informations ci


	left join public.entity_bens eb_parent

	on ci.parent_entity_number = eb_parent.ben

	left join public.fy2017_districts_demog_matr dd

	on eb_parent.entity_id = dd.esh_id::text::int

	left join public.tags t
	on dd.esh_id::text::int = t.taggable_id
	and t.label in ('sufficient_wifi', 'insufficient_wifi')
	and t.deleted_at is null
	and t.funding_year = 2017
	and t.created_at::date <= '2017-07-24'::date

	left join public.entity_bens eb_child   /*no funding year column in this*/
	on ci.child_entity_number = eb_child.ben

	left join public.fy2017_schools_demog_matr sd
	on eb_child.entity_id = sd.school_esh_id::text::int

	where dd.esh_id is not null
	and sd.school_esh_id is not null

	group by 	ci.postal_cd,
				ci.parent_entity_name,
				eb_parent.entity_id

),

temp as (

	select 
		d17.esh_id,
		d17.postal_cd,
		d17.num_students,
		d17.num_schools,
		d16.needs_wifi as needs_wifi_16,
		d17.needs_wifi as needs_wifi_17,
		CASE 	WHEN w.count_wifi_needed > 0 THEN true
	   			WHEN w.count_wifi_needed = 0 THEN false
	        	ELSE null
			   	END as needs_wifi_updated_17


	from public.fy2017_districts_deluxe_matr d17

	join public.fy2016_districts_deluxe_matr d16
	on d17.esh_id = d16.esh_id

	left join wifi_status w
	on d17.esh_id = w.parent_entity_id::varchar

	where d17.include_in_universe_of_districts
	and d17.district_type = 'Traditional'

),

temp_2 as (

select
	esh_id,
	postal_cd,
	num_students,
	num_schools,
	case 
	    when needs_wifi_16 = false
	      then 'Sufficient'
	    when needs_wifi_16 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_16,
  	case 
	    when needs_wifi_updated_17 = false
	      then 'Sufficient'
	    when needs_wifi_updated_17 = true
	      then 'Insufficient'
	    else 'No response'
	  end as dd_response_17

from temp


),

suff as (

	select *,
		case
			when dd_response_17 = 'Sufficient' 
			 and dd_response_16 = 'Sufficient'
			 	then 0.944
			when dd_response_17 = 'Insufficient' 
			 and dd_response_16 = 'Insufficient'
			 	then .756
			when dd_response_17 = 'No response'
				then 	case
							when dd_response_16 = 'Sufficient'
								then 1
							else 0
						end
			when dd_response_16 = 'No response'
				then 	case
							when dd_response_17 = 'Sufficient'
								then 1
							else 0
						end
			when dd_response_17 = 'Sufficient'
				then 1
			else 0
		end as sufficient_district


	from temp_2

	where not(dd_response_16 = 'No response' and dd_response_17 = 'No response')

),

total_classrooms as (
	select d.esh_id,
	--assume 25 students per classroom
	--source: http://www.nea.org/home/rankings-and-estimates-2013-2014.html
	d.num_students,
	d.num_schools,
	sum(case
	  when s.num_students <= 25
	    then 1
	  else ceil((s.num_students / 25))
	end) as num_classrooms

	from public.fy2017_schools_demog_matr s
	join public.fy2017_districts_deluxe_matr d
	on s.district_esh_id = d.esh_id

	where d.include_in_universe_of_districts = true
	and d.district_type = 'Traditional'

	group by 1, 2, 3

),

insuff_classrooms_16 as (
	select 
		sum(case
	        when d.needs_wifi = true
	         then case 
	                when s.num_students <= 25
	            	    then 1
	            	       else ceil((s.num_students / 25))
	            	end
	      end)::numeric / sum(case 
	                when s.num_students <= 25
	            	    then 1
	            	       else ceil((s.num_students / 25))
	            	end)::numeric as perc_classrooms_insuff_16
      

	from public.fy2016_schools_demog_matr s
	join public.fy2016_districts_deluxe_matr d
	on s.district_esh_id = d.esh_id

	where d.include_in_universe_of_districts = true
	and d.district_type = 'Traditional'
	and d.needs_wifi is not null

),

suff_and_classrooms as (

	select 
		sum(suff.sufficient_district * total_classrooms.num_schools) as suff_schools_sample,
		sum(total_classrooms.num_schools) as num_schools_sample,
		sum(suff.sufficient_district * total_classrooms.num_schools)::numeric / sum(total_classrooms.num_schools)::numeric as perc_suff_schools,
		sum(suff.sufficient_district)::numeric as sufficient_districts_sample,
		count(suff.esh_id) as num_districts_sample,
		sum(suff.sufficient_district)::numeric / count(suff.esh_id) as perc_suff_districts,
		sum(suff.sufficient_district * total_classrooms.num_classrooms) as suff_classrooms_sample,
		sum(total_classrooms.num_classrooms) as num_classrooms_sample,
		sum(suff.sufficient_district * total_classrooms.num_classrooms)::numeric / sum(total_classrooms.num_classrooms)::numeric as perc_suff_classrooms,
		sum(suff.num_students * suff.sufficient_district) as suff_students_sample,
		sum(suff.num_students) as num_students_sample,
		sum(suff.num_students * suff.sufficient_district) / sum(suff.num_students) as perc_suff_students

	from suff

	join total_classrooms
	on suff.esh_id = total_classrooms.esh_id

),

pop as (

select
	count(esh_id) as num_districts,
	sum(num_students) as num_students,
	sum(num_classrooms) as num_classrooms,
	sum(num_schools) as num_schools
from total_classrooms

)

select 
  perc_suff_students,
  perc_suff_districts,
  perc_suff_classrooms,
  perc_suff_schools,
  round(perc_suff_districts * num_districts::numeric,0) as extrap_districts_suff,
  round(perc_suff_students * num_students::numeric,0) as extrap_students_suff,
  round(perc_suff_classrooms * num_classrooms::numeric,0) as extrap_classrooms_suff,
  round(perc_suff_schools * num_schools::numeric,0) as extrap_schools_suff,
  num_districts - round(perc_suff_districts * num_districts::numeric,0) as extrap_districts_insuff,
  num_classrooms - round(perc_suff_classrooms * num_classrooms::numeric,0) as extrap_classrooms_insuff,
  num_schools - round(perc_suff_schools * num_schools::numeric,0) as extrap_schools_insuff,
  round(perc_classrooms_insuff_16 * num_classrooms::numeric, 0) as extrap_classrooms_insuff_16,
  num_classrooms - round(perc_classrooms_insuff_16 * num_classrooms::numeric, 0) as extrap_classrooms_suff_16
from suff_and_classrooms
left join pop
on true
left join insuff_classrooms_16
on true