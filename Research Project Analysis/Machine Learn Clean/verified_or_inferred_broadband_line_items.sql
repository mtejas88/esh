/* ONYX DB */
with version_order as (
                select fy2015_item21_services_and_cost_id,
                      case 
                        when contacted is null or contacted = false 
                          then 
                            case
                              when user_id is not null
                                then true
                              else 
                                false
                            end
                        when contacted = true 
                          then true
                      end as contacted_or_inferred,
                      version_id,
                      row_number() over (
                                        partition by fy2015_item21_services_and_cost_id 
                                        order by version_id desc
                                        ) as row_num
                
                from line_item_notes
                where note not like '%little magician%'
),
service_indicator as (
select district_esh_id,
        count(distinct case
                when (isp_conditions_met = true)
                  or (internet_conditions_met = true and li.consortium_shared=true)
                  then line_item_id
              end) as isp_indicator,
        count(distinct case
                when (upstream_conditions_met = true and li.consortium_shared=false)
                  then line_item_id
              end) as upstream_indicator,
        count(distinct case
                when (wan_conditions_met = true and li.consortium_shared=false)
                  then line_item_id
              end) as wan_indicator,
        count(distinct case
                when (internet_conditions_met = true and li.consortium_shared=false)
                  then line_item_id
              end) as internet_indicator

from line_item_district_association_2015 lida
left join public.line_items li
on lida.line_item_id = li.id

where li.broadband=true
and li.erate=true
and not('video_conferencing'=any(li.open_flags))
and not('exclude'=any(li.open_flags))
and not('charter_service'=any(li.open_flags))
and not('committed_information_rate'=any(li.open_flags))

group by district_esh_id
),
agg_service_indicator as (
  select line_item_id,
          sum(isp_indicator) as isp_indicator,
          sum(upstream_indicator) as upstream_indicator,
          sum(wan_indicator) as wan_indicator,
          sum(internet_indicator) as internet_indicator

  from line_item_district_association_2015 lida
  join service_indicator si
  on lida.district_esh_id = si.district_esh_id

  group by line_item_id
)

select  li.id as line_item_id,
        applicant_id,
        applicant_type,
        applicant_ben,
        applicant_name,
        applicant_postal_cd,
        application_number,
        frn,
        frn_line_item_no,
        purpose,
        wan,
        bandwidth_in_mbps,
        connect_type,
        connect_category,
        num_lines,
        one_time_eligible_cost,
        rec_elig_cost,
        total_cost,
        service_provider_name,
        exclude,
        version_order.contacted_or_inferred,
        internet_conditions_met,
        isp_conditions_met,
        upstream_conditions_met,
        wan_conditions_met,
        contract_end_date,
        reporting_name,
        category,
        recipient_districts,
        count_recipient_districts,
        recipient_schools,
        case
          when isp_indicator is null
            then 'unknown'
          when isp_conditions_met = true
            then 
              case
                when isp_indicator>count_recipient_districts
                  then 'yes'
                else
                  'no'
              end 
          when isp_conditions_met = false
            then 
              case
                when isp_indicator>0
                  then 'yes'
                else
                  'no'
              end 
        end as isp_indicator,        
        case
          when upstream_indicator is null
            then 'unknown'
          when upstream_conditions_met = true
            then 
              case
                when upstream_indicator>count_recipient_districts
                  then 'yes'
                else
                  'no'
              end 
          when upstream_conditions_met = false
            then 
              case
                when upstream_indicator>0
                  then 'yes'
                else
                  'no'
              end 
        end as upstream_indicator,
        case
          when wan_indicator is null
            then 'unknown'
          when wan_conditions_met = true
            then 
              case
                when wan_indicator>count_recipient_districts
                  then 'yes'
                else
                  'no'
              end 
          when wan_conditions_met = false
            then 
              case
                when wan_indicator>0
                  then 'yes'
                else
                  'no'
              end 
        end as wan_indicator,
        case
          when internet_indicator is null
            then 'unknown'
          when internet_conditions_met = true
            then 
              case
                when wan_indicator>count_recipient_districts
                  then 'yes'
                else
                  'no'
              end 
          when internet_conditions_met = false
            then 
              case
                when internet_indicator>0
                  then 'yes'
                else
                  'no'
              end 
        end as internet_indicator
      
from line_items li
join version_order
on li.id = version_order.fy2015_item21_services_and_cost_id
left join (
      select distinct name, reporting_name, category
      from service_provider_categories
) spc
on li.service_provider_name = spc.name
left join lateral (
  select  line_item_id,
          array_agg(DISTINCT district_esh_id) as "recipient_districts",
          array_agg(DISTINCT postal_cd) as "recipient_postal_cd",
          array_agg(DISTINCT exclude_from_analysis) as "recipient_district_cleanliness",
          sum(DISTINCT case
                when num_schools = 'No data'
                  then 0
                else
                  num_schools::numeric
              end) as "recipient_schools",
          count(DISTINCT case
                when num_schools != 'No data'
                  then district_esh_id
              end) as "count_recipient_districts"          
  from lines_to_district_by_line_item_2015 ldli
  left join districts
  on ldli.district_esh_id = districts.esh_id
  GROUP BY line_item_id) x
on li.id=x.line_item_id
left join agg_service_indicator
on li.id = agg_service_indicator.line_item_id

where li.broadband=true
and li.erate=true
and li.consortium_shared=false
and not('video_conferencing'=any(li.open_flags))
and not('exclude'=any(li.open_flags))
and not('charter_service'=any(li.open_flags))
and not('committed_information_rate'=any(li.open_flags))
and not('ethernet_copper'=any(li.open_flags))
and app_type != 'LIBRARY'
and row_num = 1
and contacted_or_inferred = true
and exclude = false
and frn_line_item_no is not null
and frn is not null