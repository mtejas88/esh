with dist_2016 as (
	select *,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
		taggable_id is not null as manually_tagged_target 
	from fy2016_districts_deluxe_matr dd
	left join (
		select distinct taggable_id
		from fy2016.tags
		where label = 'fiber_target'
		and deleted_at is null
	) fiber_target
	on dd.esh_id = fiber_target.taggable_id::varchar
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

dist_2017 as (
	select dd.*,
		current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses
	from fy2017_districts_deluxe_matr dd
	where include_in_universe_of_districts
	and district_type = 'Traditional'
),

comparison as (
	select
		dist_2017.esh_id,
		case
			when dist_2017.num_campuses is null 
				then dist_2016.num_campuses
			when dist_2016.num_campuses - dist_2017.num_campuses < 0 
				then 0
			else dist_2016.num_campuses - dist_2017.num_campuses
		end as lost_campuses,	
		dist_2016.unscalable_campuses as lost_unscalable_campuses

	from dist_2016
	full outer join dist_2017
	on dist_2016.esh_id = dist_2017.esh_id
	where (dist_2017.fiber_target_status = 'Not Target' or dist_2017.fiber_target_status is null)
	and dist_2016.fiber_target_status = 'Target'
	and dist_2016.unscalable_campuses > 0
)

select 
	sum(lost_unscalable_campuses) as lost_unscalable_campuses,
	sum(case
			when lost_campuses > lost_unscalable_campuses
				then lost_unscalable_campuses
			else lost_campuses
		end) as lost_unscalable_campuses_due_to_lost_campuses
from comparison
