/* ONYX DB */
with version_order as (
                select fy2015_item21_services_and_cost_id,
                      case when contacted is null or contacted = false then false
                        when contacted = true then true
                      end as contacted,
                      version_id,
                      row_number() over (
                                        partition by fy2015_item21_services_and_cost_id
                                        order by version_id desc
                                        ) as row_num

                from line_item_notes
                where note not like '%little magician%'
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
        num_lines,
        one_time_eligible_cost,
        rec_elig_cost,
        total_cost,
        service_provider_name,
        exclude,
        version_order.contacted,
        internet_conditions_met,
        isp_conditions_met,
        upstream_conditions_met,
        wan_conditions_met,
        contract_end_date

from line_items li
join version_order
on li.id = version_order.fy2015_item21_services_and_cost_id

where broadband = true
and erate = true
and app_type != 'LIBRARY'
and row_num = 1
and contacted = true
