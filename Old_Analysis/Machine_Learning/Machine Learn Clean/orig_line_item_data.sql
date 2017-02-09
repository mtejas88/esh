/* CRIMSON DB */
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
        'n/a' as contacted,
        internet_conditions_met,
        isp_conditions_met,
        upstream_conditions_met,
        wan_conditions_met,
        contract_end_date
from line_items li
where postal_cd not in ('AS', 'GU', 'VI', 'DC', 'PR')
and broadband=true
and erate=true
and consortium_shared=false
and connect_type != 'Data Plan/Air Card Service'