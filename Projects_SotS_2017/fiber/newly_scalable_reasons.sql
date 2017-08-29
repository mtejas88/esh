with frns_17 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.frns frn
  
  left join fy2017.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2017.current_frns
  )
  and frn_status not in ('Cancelled', 'Denied')
  and line_item != '1799060913.001'
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2017.current_frns frn
  
  left join fy2017.current_frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn_status not in ('Cancelled', 'Denied')
  and line_item != '1799060913.001'

),

frns_16 as (

  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2016.frns frn
  
  left join fy2016.frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn not in (
    select frn
    from fy2016.current_frns
  )
  and frn_status not in ('Cancelled', 'Denied')
  and line_item not in (
    '1699138492.001',
    '1699138389.001',
    '1699138534.001',
    '1699139419.001',
    '1699137400.001',
    '1699139453.001',
    '1699138480.001',
    '1699138580.001',
    '1699139324.001',
    '1699139322.001',
    '1699138486.001'
  )
  
  union
  
  select frn.application_number,
  frn.frn,
  frn.frn_status,
  frn.fiber_sub_type,
  fli.line_item
  
  from fy2016.current_frns frn
  
  left join fy2016.current_frn_line_items fli
  on frn.frn = fli.frn
  
  where frn.frn_status not in ('Cancelled', 'Denied')
  and line_item not in (
    '1699138492.001',
    '1699138389.001',
    '1699138534.001',
    '1699139419.001',
    '1699137400.001',
    '1699139453.001',
    '1699138480.001',
    '1699138580.001',
    '1699139324.001',
    '1699139322.001',
    '1699138486.001'
  )

),

providers_2017 as (
  select 
    recipient_id, 
    array_agg(distinct case
                        when fiber_sub_type = 'Special Construction'
                        or 'special_construction' = any(open_flags) 
                        OR 'special_construction_tag' = any(open_tags)
                          then reporting_name
                        end) as spec_k_provider_2017, 
    array_agg(distinct case
                        when inclusion_status != 'dqs_excluded'
                          then reporting_name
                        end) as provider_2017
  from (
    select sr.*, frns.fiber_sub_type
    from frns_17 frns
    full outer join (
      select *
      from public.fy2017_esh_line_items_v 
    ) li 
    on frns.frn = li.frn
    full outer join public.fy2017_services_received_matr sr
    on li.id = sr.line_item_id
    order by sr.reporting_name
  ) ordering
  group by 1
),

providers_2016 as (
  select 
    recipient_id, 
    array_agg(distinct case
                        when fiber_sub_type = 'Special Construction'
                        or 'special_construction' = any(open_flags) 
                        OR 'special_construction_tag' = any(open_tags)
                          then reporting_name
                        end) as spec_k_provider_2016, 
    array_agg(distinct case
                        when inclusion_status != 'dqs_excluded'
                          then reporting_name
                        end) as provider_2016
  from (
    select sr.*, frns.fiber_sub_type
    from frns_16 frns
    full outer join (
      select *
      from fy2016.line_items 
    ) li 
    on frns.frn = li.frn
    full outer join public.fy2016_services_received_matr sr
    on li.id = sr.line_item_id
    order by sr.reporting_name
  ) ordering
  group by 1
),

dist_2016 as (
  select dd.*,
    current_assumed_unscalable_campuses + current_known_unscalable_campuses as unscalable_campuses,
    array_to_string(providers_2016.spec_k_provider_2016,';') != '' 
    and providers_2016.spec_k_provider_2016 is not null as spec_k_2016,
    providers_2016.spec_k_provider_2016,
    providers_2016.provider_2016
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
    case
      when dist_2016.spec_k_2016 is null
        then false
      else dist_2016.spec_k_2016
    end as spec_k_2016,
    spec_k_provider_2017,
    spec_k_provider_2016,
    provider_2016,
    provider_2017,
	outreach_status__c = 'Fiber Project' as esh_engaged_fiber_project,
    dist_2016.fiber_target_status as fiber_target_status_2016,
    dist_2017.fiber_target_status as fiber_target_status_2017,
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
  left join salesforce.account a
  on dist_2017.esh_id = a.esh_id__c
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


select
	'overall' as locale,
	'mechanism' as category,
	sum(case
			when spec_k_2017 or spec_k_2016 or esh_engaged_fiber_project
				then unscalable_campuses_moved_to_fiber
			else 0
		end)/sum(unscalable_campuses_moved_to_fiber) as pct_unscalable_campuses_moved_to_fiber
from districts_categorized
group by 1, 2

UNION

select
	case
		when locale in ('Rural', 'Town')
			then 'Rural'
		else 'Urban'
	end as locale,
	'special construction' as category,
	sum(case
			when spec_k_2017 or spec_k_2016
				then unscalable_campuses_moved_to_fiber
			else 0
		end)/sum(unscalable_campuses_moved_to_fiber) as pct_unscalable_campuses_moved_to_fiber
from districts_categorized
group by 1, 2

UNION

select
	'Urban' as locale,
	'switch provider' as category,
	sum(case
			when overall_switcher
				then unscalable_campuses_moved_to_fiber
			else 0
		end)/sum(unscalable_campuses_moved_to_fiber) as pct_unscalable_campuses_moved_to_fiber
from districts_categorized
where locale not in ('Rural', 'Town')
group by 1, 2



