
/*removing dependency on any endpoint view and utilizng crusher views instead*/

with r_sr as (
        select 
        case
          when sr.purpose = 'ISP' and consortium_shared = true
          then 'Shared ISP'
          when sr.purpose = 'ISP' and 'committed_information_rate' = any(sr.open_tags) 
          then 'CIR'
          when sr.purpose = 'ISP' and consortium_shared = false
          then 'Dedicated ISP'
          else sr.purpose
          end as "refined_purpose",
        (sr.bandwidth_in_mbps * sr.quantity_of_line_items_received_by_district) as district_line_item_total_bandwidth_in_mbps,
        (sr.bandwidth_in_mbps * sr.line_item_total_num_lines::numeric) as line_item_total_bandwidth_in_mbps,
        case
          when sr.months_of_service = 0 
          then sr.line_item_district_monthly_cost_total*12
          else sr.line_item_district_monthly_cost_total * sr.months_of_service 
        end as line_item_district_total_cost,
        case
          when sr.months_of_service = 0 
          then (sr.line_item_district_monthly_cost_total-sr.line_item_district_monthly_cost_recurring)*12 
          else (sr.line_item_district_monthly_cost_total-sr.line_item_district_monthly_cost_recurring)*sr.months_of_service
        end as line_item_district_one_time_cost,
        case
          when line_item_district_monthly_cost_recurring = 0 
          then line_item_district_monthly_cost_total /*will either be zero for free services of NRC/12 */
          else line_item_district_monthly_cost_recurring
        end as line_item_district_mrc_unless_null,
        sr.*

        from public.fy2016_services_received_matr sr
        join public.fy2016_districts_deluxe_matr d
        on d.esh_id = sr.recipient_id
        where sr.broadband = true
        and (sr.inclusion_status = 'clean_with_cost' or sr.inclusion_status = 'clean_no_cost') /* not sure if i should also include dirty line items? */
        and sr.purpose != 'WAN'
        and sr.recipient_include_in_universe_of_districts = true
        and d.district_type = 'Traditional' 
        and (
                sr.applicant_id = 893740 /*Hawaii*/
                or sr.applicant_id in (select taggable_id as applicant_id
                                  from fy2016.tags 
                                  where fy2016.tags.label = 'state')
                or sr.line_item_id in (309770,
                                        310688,
                                        309839,
                                        309184,
                                        309618,
                                        309840,
                                        309826,
                                        309851,
                                        310686,
                                        310688,
                                        309154,
                                        310689,
                                        310690,
                                        310691,
                                        310692,
                                        310693,
                                        309704,
                                        309705,
                                        310051,
                                        309670) /* non e-rate line items mistakenly added to districts and not state network entities */
                )
              and sr.recipient_postal_cd in ('AL',
                                        'AR',
                                        'DE',
                                        'GA',
                                        'KY',
                                        'MO',
                                        'MS',
                                        'NC',
                                        'SC',
                                        'SD',
                                        'WA',
                                        'WY',
                                        'HI',
                                        'ME',
                                        'ND',
                                        'UT',
                                        'FL',
                                        'MS')
        ),
/*district aggregate services received by purpose, fiber vs. non fiber for upstream and bundled IA*/
t_sr as (
        select r_sr.recipient_postal_cd,
        r_sr.recipient_id,
        r_sr.recipient_name,
        r_sr.recipient_exclude_from_ia_cost_analysis,
    /* Internet */
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_internet_bw,
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end)
        as total_district_internet_circuits,
        sum(case
          when r_sr.refined_purpose = 'Internet' and (r_sr.connect_category = 'Lit Fiber' or r_sr.connect_category = 'Dark Fiber')
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_internet_circuits_fiber,
        sum(case
          when r_sr.refined_purpose = 'Internet' and r_sr.connect_category != 'Lit Fiber' and r_sr.connect_category != 'Dark Fiber'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_internet_circuits_not_fiber,
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then 1
          else 0
          end) 
        as total_district_internet_line_items,
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then r_sr.line_item_district_monthly_cost_recurring 
          else 0
          end) 
        as total_district_internet_line_item_mrc,
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end) 
        as total_district_internet_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'Internet'
          then r_sr.line_item_district_total_cost
          else 0
          end) 
        as total_district_internet_line_item_monthly_total,
    /* CIR */
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_CIR_bw,
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_CIR_circuits,
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then 1
          else 0
          end) 
        as total_district_CIR_line_items,
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then r_sr.line_item_district_monthly_cost_recurring
          else 0
          end) 
        as total_district_CIR_line_item_mrc,
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end) 
        as total_district_CIR_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'CIR'
          then r_sr.line_item_district_total_cost
          else 0
          end) 
        as total_district_CIR_line_item_monthly_total,
    /*Dedicated ISP*/
        sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_dedicated_isp_bw,
        sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_dedicated_isp_circuits,
        sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then 1
          else 0
          end) 
        as total_district_dedicated_isp_line_items,
        sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then r_sr.line_item_district_monthly_cost_recurring 
          else 0
          end) 
        as total_district_dedicated_isp_line_item_mrc,
         sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end)
        as total_district_dedicated_isp_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'Dedicated ISP'
          then r_sr.line_item_district_total_cost 
          else 0
          end) 
        as total_district_dedicated_isp_line_item_monthly_total,
    /*Upstream*/
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_upstream_bw,
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_upstream_circuits,
        sum(case
          when r_sr.refined_purpose = 'Upstream' and (r_sr.connect_category = 'Lit Fiber' or r_sr.connect_category = 'Dark Fiber')
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_upstream_circuits_fiber,
        sum(case
          when r_sr.refined_purpose = 'Upstream' and r_sr.connect_category != 'Lit Fiber' and r_sr.connect_category != 'Dark Fiber'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_upstream_circuits_not_fiber,
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then 1
          else 0
          end) 
        as total_district_upstream_line_items,
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then r_sr.line_item_district_monthly_cost_recurring
          else 0
          end) 
        as total_district_upstream_line_item_mrc,
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end) 
        as total_district_upstream_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'Upstream'
          then r_sr.line_item_district_total_cost
          else 0
          end) 
        as total_district_upstream_line_item_monthly_total,
    /*Shared ISP*/
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_shared_isp_bw,
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_shared_isp_circuits,
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then 1
          else 0
          end) 
        as total_district_shared_isp_line_items,
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then r_sr.line_item_district_monthly_cost_recurring
          else 0
          end) 
        as total_district_shared_isp_line_item_mrc,
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end) 
        as total_district_shared_isp_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'Shared ISP'
          then r_sr.line_item_district_total_cost
          else 0
          end) 
        as total_district_shared_isp_line_item_monthly_total,
    /*Backbone*/
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then r_sr.district_line_item_total_bandwidth_in_mbps
          else 0
          end) 
        as total_district_backbone_bw,
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then r_sr.quantity_of_line_items_received_by_district
          else 0
          end) 
        as total_district_backbone_circuits,
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then 1
          else 0
          end) 
        as total_district_backbone_line_items,
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then r_sr.line_item_district_monthly_cost_recurring
          else 0
          end) 
        as total_district_backbone_line_item_mrc,
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then r_sr.line_item_district_mrc_unless_null
          else 0
          end) 
        as total_district_backbone_line_item_mrc_unless_null,
        sum(case
          when r_sr.refined_purpose = 'Backbone'
          then r_sr.line_item_district_total_cost
          else 0
          end) 
        as total_district_backbone_line_item_monthly_total

        from r_sr

        left join public.fy2016_districts_deluxe_matr  dd
        on r_sr.recipient_id = dd.esh_id
 
        where r_sr.recipient_exclude_from_ia_analysis = false /* not sure if should include any dirty districts? */
            
        group by r_sr.recipient_postal_cd,
        r_sr.recipient_id,
        r_sr.recipient_name,
        r_sr.recipient_exclude_from_ia_cost_analysis),
/*district level first round of calculating metrics*/
m_sr as (select t_sr.*,
        case 
          when t_sr.total_district_cir_bw != 0
          then t_sr.total_district_cir_bw + t_sr.total_district_internet_bw
          when t_sr.total_district_dedicated_isp_bw !=0 and t_sr.total_district_upstream_bw !=0 and t_sr.total_district_dedicated_isp_bw < t_sr.total_district_upstream_bw
          then t_sr.total_district_dedicated_isp_bw + t_sr.total_district_internet_bw 
          when t_sr.total_district_dedicated_isp_bw !=0 and t_sr.total_district_upstream_bw !=0 and t_sr.total_district_dedicated_isp_bw > t_sr.total_district_upstream_bw
          then t_sr.total_district_dedicated_isp_bw + t_sr.total_district_upstream_bw
          when t_sr.total_district_upstream_bw !=0 and t_sr.total_district_dedicated_isp_bw =0 
          /* intentionally used circuits for shared ISP because Networkmaine still has zero bw on their consortium_placeholder line item*/
          then t_sr.total_district_upstream_bw + t_sr.total_district_internet_bw
          when t_sr.total_district_upstream_bw = 0 and t_sr.total_district_dedicated_isp_bw = 0
          then t_sr.total_district_internet_bw
          else 0
        end as sn_ia_bw_mbps_total,
          (t_sr.total_district_upstream_circuits + t_sr.total_district_internet_circuits) as sn_total_district_dedicated_circuits,
          (t_sr.total_district_upstream_circuits_fiber + t_sr.total_district_internet_circuits_fiber) as sn_total_district_dedicated_circuits_fiber,
          (t_sr.total_district_upstream_circuits_not_fiber + t_sr.total_district_internet_circuits_not_fiber) as sn_total_district_dedicated_circuits_not_fiber,
          (t_sr.total_district_internet_line_item_mrc + t_sr.total_district_cir_line_item_mrc + t_sr.total_district_dedicated_isp_line_item_mrc + t_sr.total_district_upstream_line_item_mrc + t_sr.total_district_shared_isp_line_item_mrc) 
            as sn_total_district_internet_mrc_no_backbone,
          (t_sr.total_district_internet_line_item_mrc + t_sr.total_district_cir_line_item_mrc + t_sr.total_district_dedicated_isp_line_item_mrc + t_sr.total_district_upstream_line_item_mrc + t_sr.total_district_shared_isp_line_item_mrc + t_sr.total_district_backbone_line_item_mrc) 
            as sn_total_district_internet_mrc_with_backbone,
          (t_sr.total_district_internet_line_item_mrc_unless_null + t_sr.total_district_CIR_line_item_mrc_unless_null + t_sr.total_district_dedicated_isp_line_item_mrc_unless_null + t_sr.total_district_upstream_line_item_mrc_unless_null + t_sr.total_district_shared_isp_line_item_mrc_unless_null) 
            as sn_total_district_internet_mrc_unless_null_no_backbone,
          (t_sr.total_district_internet_line_item_mrc_unless_null + t_sr.total_district_CIR_line_item_mrc_unless_null + t_sr.total_district_dedicated_isp_line_item_mrc_unless_null + t_sr.total_district_upstream_line_item_mrc_unless_null + t_sr.total_district_shared_isp_line_item_mrc_unless_null + t_sr.total_district_backbone_line_item_mrc_unless_null) 
            as sn_total_district_internet_mrc_unless_null_with_backbone,
          (t_sr.total_district_internet_line_item_monthly_total + t_sr.total_district_cir_line_item_monthly_total + t_sr.total_district_dedicated_isp_line_item_monthly_total + t_sr.total_district_upstream_line_item_monthly_total + t_sr.total_district_shared_isp_line_item_monthly_total) 
            as sn_total_district_internet_monthly_total_no_backbone,
          (t_sr.total_district_internet_line_item_monthly_total + t_sr.total_district_cir_line_item_monthly_total + t_sr.total_district_dedicated_isp_line_item_monthly_total + t_sr.total_district_upstream_line_item_monthly_total + t_sr.total_district_shared_isp_line_item_monthly_total + t_sr.total_district_backbone_line_item_monthly_total) 
            as sn_total_district_internet_monthly_total_with_backbone
        from t_sr),
/* district level metrics final round */
a as    (select m_sr.*,
        (m_sr.sn_total_district_internet_mrc_no_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_mrc_no_backbone,
        (m_sr.sn_total_district_internet_mrc_with_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_mrc_with_backbone,
        (m_sr.sn_total_district_internet_mrc_unless_null_no_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_mrc_unless_null_no_backbone,
        (m_sr.sn_total_district_internet_mrc_unless_null_with_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_mrc_unless_null_with_backbone,
        (m_sr.sn_total_district_internet_monthly_total_no_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_monthly_total_no_backbone,
        (m_sr.sn_total_district_internet_monthly_total_with_backbone/m_sr.sn_ia_bw_mbps_total) as sn_cost_per_mbps_monthly_total_with_backbone,
        (sn_ia_bw_mbps_total*1000)/d.num_students as sn_ia_bandwidth_per_student_kbps,
        case
          when ((sn_ia_bw_mbps_total*1000)/d.num_students) >= 100
          then TRUE
          else FALSE
          end as sn_meeting_2014_bw_goals,
        d.ia_monthly_cost_total as all_total_district_ia_mrc_unless_null_with_backbone,
        d.ia_monthly_cost_no_backbone as all_total_district_ia_mrc_unless_null_no_backbone,
        d.ia_monthly_cost_per_mbps as all_cost_per_mbps_mrc_unless_null_with_backbone,
        /*(d.ia_monthly_cost_total/d.ia_bw_mbps_total) as all_cost_per_mbps_mrc_unless_null_with_backbone_calc_test,
        (d.ia_monthly_cost_no_backbone/d.ia_bw_mbps_total) as all_cost_per_mbps_mrc_unless_null_no_backbone_calc_test,*/
        d.ia_bandwidth_per_student_kbps as all_ia_bandwidth_per_student_kbps,
        d.meeting_2014_goal_no_oversub as all_meeting_2014_bw_goals,
        d.ia_bw_mbps_total as all_ia_bw_mbps_total,
        d.ia_procurement_type


        from m_sr
        left join public.fy2016_districts_deluxe_matr  d
        on d.esh_id = m_sr.recipient_id

        where m_sr.sn_ia_bw_mbps_total != 0),
/*state network services received first round line items */
sn_sr as    (select r_sr.recipient_postal_cd,
            r_sr.refined_purpose,
            r_sr.connect_category,
            r_sr.line_item_id,
            r_sr.line_item_total_bandwidth_in_mbps,
            r_sr.bandwidth_in_mbps,
            r_sr.line_item_total_num_lines::numeric,
            r_sr.line_item_recurring_elig_cost,
            r_sr.line_item_one_time_cost,
            r_sr.line_item_total_cost,
            r_sr.line_item_total_monthly_cost,
            case
              when r_sr.line_item_recurring_elig_cost = 0 
              then r_sr.line_item_total_monthly_cost
              else r_sr.line_item_recurring_elig_cost
            end as line_item_mrc_unless_null 

            from r_sr
          
            group by r_sr.recipient_postal_cd,
            r_sr.refined_purpose,
            r_sr.connect_category,
            r_sr.line_item_id,
            r_sr.line_item_total_bandwidth_in_mbps,
            r_sr.bandwidth_in_mbps,
            r_sr.line_item_total_num_lines::numeric,
            r_sr.line_item_recurring_elig_cost,
            r_sr.line_item_one_time_cost,
            r_sr.line_item_total_cost,
            r_sr.line_item_total_monthly_cost),
/*total state network services received final round, will be limited to clean line items but not clean districts*/
tsn_sr as (select sn_sr.recipient_postal_cd,
           /*Internet*/
           sum (case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_dedicated_internet_bw,
          sum(case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_dedicated_internet_circuits,
          sum(case
            when sn_sr.refined_purpose = 'Internet' and (sn_sr.connect_category = 'Lit Fiber' or sn_sr.connect_category = 'Dark Fiber')
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_dedicated_internet_circuits_fiber,
          sum(case
            when sn_sr.refined_purpose = 'Internet' and sn_sr.connect_category != 'Lit Fiber' and sn_sr.connect_category != 'Dark Fiber'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_dedicated_internet_circuits_not_fiber,
          sum(case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end) 
          as sn_app_dedicated_internet_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_dedicated_internet_one_item,
          sum(case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_dedicated_internet_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_dedicated_internet_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'Internet'
            then sn_sr.line_item_mrc_unless_null
            else 0
            end)
          as sn_app_dedicated_internet_total_mrc_unless_null,
          /*Upstream*/
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_upstream_bw,
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_upstream_circuits,
          sum(case
            when sn_sr.refined_purpose = 'Upstream' and (sn_sr.connect_category = 'Lit Fiber' or sn_sr.connect_category = 'Dark Fiber')
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_upstream_circuits_fiber,
          sum(case
            when sn_sr.refined_purpose = 'Upstream' and sn_sr.connect_category != 'Lit Fiber' and sn_sr.connect_category != 'Dark Fiber'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_upstream_circuits_not_fiber,
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end)
          as sn_app_upstream_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_upstream_one_item,
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_upstream_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_upstream_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'Upstream'
            then sn_sr.line_item_mrc_unless_null
            else 0
            end)
          as sn_app_upstream_total_mrc_unless_null,
          /*CIR'*/
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_cir_bw,
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_cir_circuits,
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end)
          as sn_app_cir_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_cir_one_item,
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_cir_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_cir_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'CIR'
            then sn_sr.line_item_mrc_unless_null
            else 0
            end)
          as sn_app_cir_total_mrc_unless_null,
          /*Dedicated ISP*/
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_dedicated_isp_bw,
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_dedicated_isp_circuits,
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end)
          as sn_app_dedicated_isp_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_dedicated_isp_one_item,
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_dedicated_isp_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_dedicated_isp_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'Dedicated ISP'
            then sn_sr.line_item_mrc_unless_null
            end)
          as sn_app_dedicated_isp_total_mrc_unless_null,
          /*Shared ISP*/
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_shared_isp_bw,
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_shared_isp_circuits,
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end)
          as sn_app_shared_isp_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_shared_isp_one_item,
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_shared_isp_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_shared_isp_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'Shared ISP'
            then sn_sr.line_item_mrc_unless_null
            else 0
            end)
          as sn_app_shared_isp_total_mrc_unless_null,
          /*Backbone*/
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_total_bandwidth_in_mbps
            else 0
            end)
          as sn_app_backbone_bw,
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_total_num_lines
            else 0 
            end)
          as sn_app_backbone_circuits,
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_recurring_elig_cost
            else 0
            end)
          as sn_app_backbone_mrc,
          sum(case 
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_one_time_cost
            else 0
            end)
          as sn_app_backbone_one_item,
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_total_cost
            else 0
            end)
          as sn_app_backbone_total_cost,
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_total_monthly_cost
            else 0
            end)
          as sn_app_backbone_total_monthly_cost,
          sum(case
            when sn_sr.refined_purpose = 'Backbone'
            then sn_sr.line_item_mrc_unless_null 
            else 0
            end)
          as sn_app_backbone_total_mrc_unless_null
          from sn_sr
          group by sn_sr.recipient_postal_cd),
/*status of districts in state on state network vs. off state network, defined as district receiving any broadband services from state network applicant*/
s_sn_status as    (with c as (select case 
                              when dd.esh_id not in (select sr.recipient_id as esh_id
                                        from public.fy2016_services_received_matr sr
                                        where (sr.applicant_id in (select taggable_id as applicant_id
                                              from fy2016.tags 
                                              where fy2016.tags.label = 'state')
                                              or sr.applicant_id = 893740 /* Hawaii */))
                               then 'FALSE'
                              else 'TRUE'
                            end as on_state_network,
                            dd.*
                            from public.fy2016_districts_deluxe_matr dd
                            where dd.include_in_universe_of_districts = true
                            and dd.district_type = 'Traditional'
                            and dd.postal_cd in         ('AL',
                                                        'AR',
                                                        'DE',
                                                        'GA',
                                                        'KY',
                                                        'MO',
                                                        'MS',
                                                        'NC',
                                                        'SC',
                                                        'SD',
                                                        'WA',
                                                        'WY',
                                                        'HI',
                                                        'ME',
                                                        'ND',
                                                        'UT',
                                                        'FL',
                                                        'MS')) 
              select c.postal_cd,
              count(c.esh_id) as total_districts,
              sum(case 
                when c.on_state_network = 'TRUE'
                then 1
                else 0
                end)
              as districts_on_state_network,
              sum(case 
                when c.on_state_network = 'TRUE'
                then c.num_students
                else 0
                end)
              as students_on_state_network,
              sum(case
                when c.on_state_network = 'FALSE'
                then 1
                else 0
                end)
              as districts_off_state_network
              from c
              group by c.postal_cd
              order by postal_cd),
/*clean districts in state meeting goals*/
s_clean as      (select 
          d.postal_cd,
          count (d.esh_id) as districts_in_state_count,
          sum (case 
              when d.meeting_2014_goal_no_oversub = true 
              then 1
              else 0
          end) as districts_in_state_meeting_2014_bw_goals_count
          from public.fy2016_districts_deluxe_matr d
          where d.include_in_universe_of_districts = true
          and d.district_type = 'Traditional'
          and d.exclude_from_ia_analysis = false 
          group by d.postal_cd),
/*dirty and clean districts in state meeting goals*/
s_dirty as      (select 
          d.postal_cd,
          count (d.esh_id) as districts_in_state_count,
          sum (d.num_students::numeric) as students_in_state_count,
          sum (case 
              when d.meeting_2014_goal_no_oversub = true 
              then 1
              else 0
          end) as districts_in_state_meeting_2014_bw_goals_count
          from public.fy2016_districts_deluxe_matr d
          where d.include_in_universe_of_districts = true
          and d.district_type = 'Traditional'
          group by d.postal_cd),

final as (select a.recipient_postal_cd,
          count(a.recipient_id) as sn_clean_districts,
          s_sn_status.districts_on_state_network as sn_districts,
          s_sn_status.students_on_state_network as sn_students,
          s_clean.districts_in_state_count as all_clean_districts,
          s_dirty.districts_in_state_count as all_districts,
          s_dirty.students_in_state_count as all_students,
          sum (case
            when a.sn_meeting_2014_bw_goals = 'TRUE'
            then 1
            else 0
          end) as sn_districts_2014_bw_goals,
          sum (case
            when a.all_meeting_2014_bw_goals = TRUE
            then 1
            else 0
          end) as sn_districts_all_services_2014_bw_goals,
          s_clean.districts_in_state_meeting_2014_bw_goals_count as all_districts_2014_bw_goals,
          /* BW and circuits */
          sum(a.sn_ia_bw_mbps_total) as sn_sum_direct_bw,
          sum(a.all_ia_bw_mbps_total) as all_sum_direct_bw,
          sum(a.sn_total_district_dedicated_circuits) as sn_sum_direct_circuits,
          sum(a.sn_total_district_dedicated_circuits_fiber) as sn_sum_direct_circuits_fiber,
          sum(a.sn_total_district_dedicated_circuits_not_fiber) as sn_sum_direct_circuits_not_fiber,
          /*cost metrics */
          sum(a.sn_total_district_internet_mrc_no_backbone) as sn_sum_district_internet_mrc_no_backbone,
          sum(a.sn_total_district_internet_mrc_with_backbone) as sn_sum_district_internet_mrc_with_backbone,
          sum(a.sn_total_district_internet_monthly_total_no_backbone) as sn_sum_district_internet_monthly_total_no_backbone,
          sum(a.sn_total_district_internet_monthly_total_with_backbone) as sn_sum_district_internet_monthly_total_with_backbone,
          sum(a.all_total_district_ia_mrc_unless_null_no_backbone) as all_services_sum_district_internet_mrc_unless_null_no_backbone,
          sum(a.all_total_district_ia_mrc_unless_null_with_backbone) as all_services_sum_district_internet_mrc_unless_null_with_backbone,
          /*cost per mbps */
          median(a.sn_cost_per_mbps_mrc_with_backbone) as sn_median_cost_per_mbps_mrc_with_backbone,
          median(a.sn_cost_per_mbps_mrc_no_backbone) as sn_median_cost_per_mbps_mrc_no_backbone,
          median(a.sn_cost_per_mbps_mrc_unless_null_with_backbone) as sn_median_cost_per_mbps_mrc_unless_null_with_backbone,
          median(a.sn_cost_per_mbps_mrc_unless_null_no_backbone) as sn_median_cost_per_mbps_mrc_unless_null_no_backbone,
          median(a.all_cost_per_mbps_mrc_unless_null_with_backbone) as all_services_median_cost_per_mbps_mrc_unless_null_with_backbone,
          sum(a.sn_total_district_internet_mrc_with_backbone)/sum(a.sn_ia_bw_mbps_total) as sn_wavg_cost_per_mbps_mrc_with_backbone,
          sum(a.sn_total_district_internet_mrc_no_backbone)/sum(a.sn_ia_bw_mbps_total) as sn_wavg_cost_per_mbps_mrc_no_backbone,
          sum(a.sn_total_district_internet_mrc_unless_null_with_backbone)/sum(a.sn_ia_bw_mbps_total) as sn_wavg_cost_per_mbps_mrc_unless_null_with_backbone,
          sum(a.sn_total_district_internet_mrc_unless_null_no_backbone)/sum(a.sn_ia_bw_mbps_total) as sn_wavg_cost_per_mbps_mrc_unless_null_no_backbone,
          sum(a.all_total_district_ia_mrc_unless_null_with_backbone)/sum(a.all_ia_bw_mbps_total) as all_services_wavg_cost_per_mbps_mrc_unless_null_with_backbone,
          sum(a.all_total_district_ia_mrc_unless_null_no_backbone)/sum(a.all_ia_bw_mbps_total) as all_services_wavg_cost_per_mbps_mrc_unless_null_no_backbone,
          /*total state app metrics*/
          tsn_sr.sn_app_dedicated_internet_bw,
          tsn_sr.sn_app_dedicated_internet_circuits,
          tsn_sr.sn_app_dedicated_internet_circuits_fiber,
          tsn_sr.sn_app_dedicated_internet_circuits_not_fiber,
          tsn_sr.sn_app_dedicated_internet_total_cost,
          tsn_sr.sn_app_dedicated_internet_total_mrc_unless_null,
          case
            when tsn_sr.sn_app_dedicated_internet_bw = 0
            then 0
            else (tsn_sr.sn_app_dedicated_internet_total_mrc_unless_null/tsn_sr.sn_app_dedicated_internet_bw) 
          end as sn_app_dedicated_internet_cost_per_mbps_mrc_unless_null,
          tsn_sr.sn_app_upstream_bw,
          tsn_sr.sn_app_upstream_circuits,
          tsn_sr.sn_app_upstream_circuits_fiber,
          tsn_sr.sn_app_upstream_circuits_not_fiber,
          tsn_sr.sn_app_upstream_total_cost,
          tsn_sr.sn_app_upstream_total_mrc_unless_null,
          case
            when tsn_sr.sn_app_upstream_bw = 0
            then 0
            else (tsn_sr.sn_app_upstream_total_mrc_unless_null/tsn_sr.sn_app_upstream_bw) 
          end as sn_app_upstream_cost_per_mbps_mrc_unless_null,
          tsn_sr.sn_app_cir_bw,
          tsn_sr.sn_app_cir_circuits,
          tsn_sr.sn_app_cir_total_cost,
          tsn_sr.sn_app_cir_total_mrc_unless_null,
          case
            when tsn_sr.sn_app_cir_bw = 0
            then 0 
            else (tsn_sr.sn_app_cir_total_mrc_unless_null/tsn_sr.sn_app_cir_bw) 
          end as sn_app_cir_cost_per_mbps_mrc_unless_null,
          tsn_sr.sn_app_dedicated_isp_bw,
          tsn_sr.sn_app_dedicated_isp_circuits,
          tsn_sr.sn_app_dedicated_isp_total_cost,
          tsn_sr.sn_app_dedicated_isp_total_mrc_unless_null,
          case
            when tsn_sr.sn_app_dedicated_isp_bw = 0
            then 0
            else (tsn_sr.sn_app_dedicated_isp_total_mrc_unless_null/tsn_sr.sn_app_dedicated_isp_bw) 
          end as sn_app_dedicated_isp_cost_per_mbps_mrc_unless_null,
          tsn_sr.sn_app_shared_isp_bw,
          tsn_sr.sn_app_shared_isp_circuits,
          tsn_sr.sn_app_shared_isp_total_cost,
          tsn_sr.sn_app_shared_isp_total_mrc_unless_null,
          case
            when tsn_sr.sn_app_shared_isp_bw = 0
            then 0
            else (tsn_sr.sn_app_shared_isp_total_mrc_unless_null/tsn_sr.sn_app_shared_isp_bw) 
          end as sn_app_shared_isp_cost_per_mbps_mrc_unless_null,
          tsn_sr.sn_app_backbone_bw,
          tsn_sr.sn_app_backbone_circuits,
          tsn_sr.sn_app_backbone_total_cost,
          tsn_sr.sn_app_backbone_total_mrc_unless_null,
          case
          when tsn_sr.sn_app_backbone_bw = 0
          then 0
          else (tsn_sr.sn_app_backbone_total_mrc_unless_null/tsn_sr.sn_app_backbone_bw) 
          end as sn_app_backbone_cost_per_mbps_mrc_unless_null

          from a 
          left join tsn_sr
          on tsn_sr.recipient_postal_cd = a.recipient_postal_cd
          left join s_sn_status
          on s_sn_status.postal_cd = a.recipient_postal_cd
          left join s_clean
          on s_clean.postal_cd = a.recipient_postal_cd
          left join s_dirty
          on s_dirty.postal_cd = a.recipient_postal_cd
          group by a.recipient_postal_cd,
          s_sn_status.districts_on_state_network,
          s_sn_status.students_on_state_network,
          s_clean.districts_in_state_count,
          s_dirty.districts_in_state_count,
          s_dirty.students_in_state_count,
          s_clean.districts_in_state_meeting_2014_bw_goals_count,
          tsn_sr.sn_app_dedicated_internet_bw,
          tsn_sr.sn_app_dedicated_internet_circuits,
          tsn_sr.sn_app_dedicated_internet_circuits_fiber,
          tsn_sr.sn_app_dedicated_internet_circuits_not_fiber,
          tsn_sr.sn_app_dedicated_internet_total_cost,
          tsn_sr.sn_app_dedicated_internet_total_mrc_unless_null,
          tsn_sr.sn_app_upstream_bw,
          tsn_sr.sn_app_upstream_circuits,
          tsn_sr.sn_app_upstream_circuits_fiber,
          tsn_sr.sn_app_upstream_circuits_not_fiber,
          tsn_sr.sn_app_upstream_total_cost,
          tsn_sr.sn_app_upstream_total_mrc_unless_null,
          tsn_sr.sn_app_cir_bw,
          tsn_sr.sn_app_cir_circuits,
          tsn_sr.sn_app_cir_total_cost,
          tsn_sr.sn_app_cir_total_mrc_unless_null,
          tsn_sr.sn_app_dedicated_isp_bw,
          tsn_sr.sn_app_dedicated_isp_circuits,
          tsn_sr.sn_app_dedicated_isp_total_cost,
          tsn_sr.sn_app_dedicated_isp_total_mrc_unless_null,
          tsn_sr.sn_app_shared_isp_bw,
          tsn_sr.sn_app_shared_isp_circuits,
          tsn_sr.sn_app_shared_isp_total_cost,
          tsn_sr.sn_app_shared_isp_total_mrc_unless_null,
          tsn_sr.sn_app_backbone_bw,
          tsn_sr.sn_app_backbone_circuits,
          tsn_sr.sn_app_backbone_total_cost,
          tsn_sr.sn_app_backbone_total_mrc_unless_null)
select final.recipient_postal_cd as postal_cd,
final.sn_clean_districts,
final.sn_districts,
final.sn_students,
final.all_clean_districts,
final.all_districts,
final.all_students,
final.sn_districts_2014_bw_goals,
final.sn_districts_all_services_2014_bw_goals,
final.all_districts_2014_bw_goals,
final.sn_median_cost_per_mbps_mrc_with_backbone,
final.sn_median_cost_per_mbps_mrc_no_backbone,
final.sn_median_cost_per_mbps_mrc_unless_null_with_backbone,
final.sn_median_cost_per_mbps_mrc_unless_null_no_backbone,
final.all_services_median_cost_per_mbps_mrc_unless_null_with_backbone,
final.sn_wavg_cost_per_mbps_mrc_with_backbone,
final.sn_wavg_cost_per_mbps_mrc_no_backbone,
final.sn_wavg_cost_per_mbps_mrc_unless_null_with_backbone,
final.sn_wavg_cost_per_mbps_mrc_unless_null_no_backbone,
final.all_services_wavg_cost_per_mbps_mrc_unless_null_with_backbone,
final.all_services_wavg_cost_per_mbps_mrc_unless_null_no_backbone,
final.sn_app_dedicated_internet_bw,
final.sn_app_dedicated_internet_circuits,
final.sn_app_dedicated_internet_circuits_fiber,
final.sn_app_dedicated_internet_circuits_not_fiber,
final.sn_app_dedicated_internet_total_cost,
final.sn_app_dedicated_internet_total_mrc_unless_null,
final.sn_app_dedicated_internet_cost_per_mbps_mrc_unless_null,
final.sn_app_upstream_bw,
final.sn_app_upstream_circuits,
final.sn_app_upstream_circuits_fiber,
final.sn_app_upstream_circuits_not_fiber,
final.sn_app_upstream_total_cost,
final.sn_app_upstream_total_mrc_unless_null,
final.sn_app_upstream_cost_per_mbps_mrc_unless_null,
final.sn_app_cir_bw,
final.sn_app_cir_circuits,
final.sn_app_cir_total_cost,
final.sn_app_cir_total_mrc_unless_null,
final.sn_app_cir_cost_per_mbps_mrc_unless_null,
final.sn_app_dedicated_isp_bw,
final.sn_app_dedicated_isp_circuits,
final.sn_app_dedicated_isp_total_cost,
final.sn_app_dedicated_isp_total_mrc_unless_null,
final.sn_app_dedicated_isp_cost_per_mbps_mrc_unless_null,
final.sn_app_shared_isp_bw,
final.sn_app_shared_isp_circuits,
final.sn_app_shared_isp_total_cost,
final.sn_app_shared_isp_total_mrc_unless_null,
final.sn_app_shared_isp_cost_per_mbps_mrc_unless_null,
final.sn_app_backbone_bw,
final.sn_app_backbone_circuits,
final.sn_app_backbone_total_cost,
final.sn_app_backbone_total_mrc_unless_null,
final.sn_app_backbone_cost_per_mbps_mrc_unless_null
from final
order by final.recipient_postal_cd


/*
Author: Jamie Barnes
Created On Date: 12/2/2016
Last Modified Date: 3/1/2017
Name of QAing Analyst(s): Justine Schott
Purpose: State network metrics like aggregate district statistics and application metrics for states identified as comprehensive state networks for National Analysis one-pager
*/