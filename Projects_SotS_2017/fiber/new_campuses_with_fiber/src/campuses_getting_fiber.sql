with providers_2017 as (
  select 
    sr.recipient_id, 
    array_agg(distinct case
                        when fiber_sub_type = 'Special Construction'
                          then sr.reporting_name
                        end) as spec_k_provider_2017, 
    array_agg(distinct case
                        when inclusion_status != 'dqs_excluded'
                          then sr.reporting_name
                        end) as provider_2017
  from fy2017.frns
  full outer join (
    select *
    from public.fy2017_esh_line_items_v 
  ) li 
  on frns.frn = li.frn
  full outer join public.fy2017_services_received_matr sr
  on li.id = sr.line_item_id
  group by 1
),

providers_2016 as (
  select 
    sr.recipient_id, 
    array_agg(distinct sr.reporting_name) as provider_2016
  from public.fy2016_services_received_matr sr
  where inclusion_status != 'dqs_excluded'
  group by 1
),

dist_2016 as (
  select dd.*,
    current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
    provider_2016
  from fy2016_districts_deluxe_matr dd
  left join providers_2016
  on dd.esh_id = providers_2016.recipient_id
  where include_in_universe_of_districts
  and district_type = 'Traditional'
),

dist_2017 as (
  select dd.*,
    current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
    array_to_string(providers_2017.spec_k_provider_2017,';') != '' 
    and providers_2017.spec_k_provider_2017 is not null as spec_k_2017,
    providers_2017.spec_k_provider_2017,
    providers_2017.provider_2017
  from fy2017_districts_deluxe_matr dd
  left join providers_2017
  on dd.esh_id = providers_2017.recipient_id
  where include_in_universe_of_districts
  and district_type = 'Traditional'
),

comparison as (
  select
    dist_2017.esh_id,
    dist_2017.locale,
    dist_2017.exclude_from_ia_analysis as exclude_from_ia_analysis_2017,
    dist_2016.exclude_from_ia_analysis as exclude_from_ia_analysis_2016,
    dist_2016.service_provider_assignment as service_provider_assignment_2016,
    case
      when dist_2017.spec_k_2017 is null
        then false
      else dist_2017.spec_k_2017
    end as spec_k_2017,
    spec_k_provider_2017,
    provider_2016,
    provider_2017,
    dist_2016.fiber_target_status as fiber_target_status_2016,
    dist_2017.fiber_target_status as fiber_target_status_2017,
    dist_2016.meeting_2014_goal_no_oversub as meeting_2014_goal_no_oversub_2016,
    case
      when dist_2017.meeting_2014_goal_no_oversub is null
        then false
      else dist_2017.meeting_2014_goal_no_oversub 
    end as meeting_2014_goal_no_oversub_2017, 
    dist_2017.ia_monthly_cost_total + dist_2017.wan_monthly_cost_total as monthly_cost_total_2017,
    dist_2016.ia_monthly_cost_total + dist_2016.wan_monthly_cost_total as monthly_cost_total_2016,
    dist_2017.unscalable_campuses,
    case
      when dist_2017.unscalable_campuses is null 
        then dist_2016.unscalable_campuses
      when dist_2016.unscalable_campuses is null 
        then -dist_2017.unscalable_campuses
      else dist_2016.unscalable_campuses - dist_2017.unscalable_campuses
    end as lost_unscalable_campuses,  
    case
      when dist_2017.num_campuses is null 
        then dist_2016.num_campuses
      when dist_2016.num_campuses is null or dist_2016.num_campuses - dist_2017.num_campuses < 0 
        then 0
      else dist_2016.num_campuses - dist_2017.num_campuses
    end as lost_campuses
  from dist_2016
  full outer join dist_2017
  on dist_2016.esh_id = dist_2017.esh_id
),

extrapolated_unscalable_campuses as (
	select sum(	case
      					when exclude_from_ia_analysis_2017= false 
                and exclude_from_ia_analysis_2016= false 
                and fiber_target_status_2016 = 'Target'
                and fiber_target_status_2017 = 'Not Target'
      						then  case
                          when lost_unscalable_campuses < 0
                            then lost_unscalable_campuses
                          when lost_campuses > lost_unscalable_campuses
                            then 0
                          else lost_unscalable_campuses - lost_campuses
                        end
      					else 0
      				end)/sum(lost_unscalable_campuses)::numeric as extrapolate_pct
	from comparison
),

districts_categorized as (
  select *,
  case
    when lost_unscalable_campuses < 0
      then lost_unscalable_campuses
    when lost_campuses > lost_unscalable_campuses
      then 0
    else lost_unscalable_campuses - lost_campuses
  end unscalable_campuses_moved_to_fiber,
  case
    when spec_k_2017
      then not(spec_k_provider_2017 && provider_2016)
    else not(provider_2017 = provider_2016)
  end overall_switcher
  from comparison
  where exclude_from_ia_analysis_2017= false 
  and exclude_from_ia_analysis_2016= false 
  and fiber_target_status_2016 = 'Target'
  and fiber_target_status_2017 = 'Not Target'
)


--select
--  spec_k_2017,
--  sum(case
--        when overall_switcher
--          then unscalable_campuses_moved_to_fiber
--        else 0
--      end) as new_fiber_campuses_switched_sp_sample,
--  sum(case
--        when overall_switcher = false
--          then unscalable_campuses_moved_to_fiber
--        else 0
--      end) as new_fiber_campuses_same_sp_sample,
--  sum(case
--        when overall_switcher
--          then unscalable_campuses_moved_to_fiber
--        else 0
--      end)/extrapolate_pct as new_fiber_campuses_switched_sp_extrap,
--  sum(case
--        when overall_switcher = false
--          then unscalable_campuses_moved_to_fiber
--        else 0
--      end)/extrapolate_pct as new_fiber_campuses_same_sp_extrap
select *
from districts_categorized
--join extrapolated_unscalable_campuses 
--on true
--group by 1, extrapolate_pct
