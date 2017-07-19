with sub as(
  select  dm.esh_id, 
          fiber_target_status, 
          current_assumed_unscalable_campuses+current_known_unscalable_campuses as unscalable_campuses
  from fy2016_districts_metrics_matr dm
  left join public.fy2016_fiber_bw_target_status_matr tgt
  on dm.esh_id= tgt.esh_id
  where dm.include_in_universe_of_districts
  and dm.district_type = 'Traditional'
  and tgt.exclude_from_ia_analysis = false
)

select  fiber_target_status, 
        sum(case
              when unscalable_campuses = 0
                then 1
              else 0
            end) as districts_need_adjustment,
        sum(case
              when unscalable_campuses = 0
                then 1
              else 0
            end) / sum(1)::numeric as pct_need_adjustment
from sub
where fiber_target_status = 'Target'
group by 1

UNION

select  fiber_target_status,
        sum(case
              when unscalable_campuses > 0
                then 1
              else 0
            end) as districts_need_adjustment,
        sum(case
              when unscalable_campuses > 0
                then 1
              else 0
            end) / sum(1)::numeric as pct_need_adjustment
from sub
where fiber_target_status = 'Not Target'
group by 1


