--ONYX
with service_indicator as (
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

select li.frn_complete,
id as production_id, 
case 
  when not(     li.broadband=true
            and li.erate=true
            and li.consortium_shared=false
            and not('video_conferencing'=any(li.open_flags))
            and not('exclude'=any(li.open_flags))
            and not('charter_service'=any(li.open_flags))) 
    then 'excluded - do not review' 
  else 
    'included - review' 
end as review_status,
li.number_of_dirty_line_item_flags,
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
end as internet_indicator,
case
  when category is null
    then 'Other'
  else category
end as category,
array_to_string(li.open_flags,';') as open_flags,
internet_conditions_met,
wan_conditions_met,
isp_conditions_met,
upstream_conditions_met,
case when li.connect_category='Other / Uncategorized'
and li.connect_type not in ('Standalone Internet Access', 'Ethernet', 'Switched Multimegabit Data Service')
then 'Rare Connection'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Ethernet' 
then 'Low-bandwidth Ethernet'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Standalone Internet Access' 
then 'ISP Only'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Switched Multimegabit Data Service' 
then 'Switched Multimegabit' 
when li.connect_category='Cable / DSL'
and li.connect_type='Cable Modem'
then 'Cable'
when li.connect_category='Cable / DSL'
and li.connect_type='Digital Subscriber Line (DSL)'
then 'DSL'
when li.connect_category='Copper'
and (li.connect_type='DS-1 (T-1)'
    OR 
    li.bandwidth_in_mbps::numeric in (1.5, 3, 4.5, 6, 7.5, 9))
then 'T-1'
when li.connect_category='Copper'
and li.connect_type='DS-3 (T-3)'
then 'T-3'
else li.connect_category
end as "connect_category_adjusted"


from public.line_items li

left join (
      select distinct name, reporting_name, category
      from public.service_provider_categories
) spc
on li.service_provider_name = spc.name

left join lateral (
  select  line_item_id,
          array_agg(DISTINCT district_esh_id) as "recipient_districts",
          array_agg(DISTINCT postal_cd) as "recipient_postal_cd",
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
  left join public.districts
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
and connect_type != 'Data Plan/Air Card Service'