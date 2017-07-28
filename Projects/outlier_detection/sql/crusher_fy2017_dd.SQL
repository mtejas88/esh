with nobcost_2017 as (
select	dd.esh_id,

				case

				  when (case

			          	when	com_info_bandwidth_cost	>	0

			          	then	com_info_bandwidth_cost

			          	when	upstream_bandwidth_cost	=	0

			          	then	isp_bandwidth_cost

			          	when	isp_bandwidth_cost	=	0

			          	then	upstream_bandwidth_cost

			          	when	upstream_bandwidth_cost	>	isp_bandwidth_cost

			          	then	isp_bandwidth_cost

			          	else	upstream_bandwidth_cost

			          end	+	internet_bandwidth_cost) > 0

				    then  (ia_monthly_cost_direct_to_district	+

				    			((ia_monthly_cost_per_student_shared_ia_pieces)*num_students))/

				    				(case

                    	when	com_info_bandwidth_cost	>	0

                    	then	com_info_bandwidth_cost

                    	when	upstream_bandwidth_cost	=	0

                    	then	isp_bandwidth_cost

                    	when	isp_bandwidth_cost	=	0

                    	then	upstream_bandwidth_cost

                    	when	upstream_bandwidth_cost	>	isp_bandwidth_cost

                    	then	isp_bandwidth_cost

                    	else	upstream_bandwidth_cost

                    end	+	internet_bandwidth_cost)

			  end as	ia_monthly_cost_per_mbps

from	fy2017_districts_demog_matr dd

left	join	fy2017_districts_aggregation_matr	da

on	dd.esh_id	=	da.district_esh_id
),

nobcost_2016 as (
select	dd.esh_id,

				case

				  when (case

			          	when	com_info_bandwidth_cost	>	0

			          	then	com_info_bandwidth_cost

			          	when	upstream_bandwidth_cost	=	0

			          	then	isp_bandwidth_cost

			          	when	isp_bandwidth_cost	=	0

			          	then	upstream_bandwidth_cost

			          	when	upstream_bandwidth_cost	>	isp_bandwidth_cost

			          	then	isp_bandwidth_cost

			          	else	upstream_bandwidth_cost

			          end	+	internet_bandwidth_cost) > 0

				    then  (ia_monthly_cost_direct_to_district	+

				    			((ia_monthly_cost_per_student_shared_ia_pieces)*num_students))/

				    				(case

                    	when	com_info_bandwidth_cost	>	0

                    	then	com_info_bandwidth_cost

                    	when	upstream_bandwidth_cost	=	0

                    	then	isp_bandwidth_cost

                    	when	isp_bandwidth_cost	=	0

                    	then	upstream_bandwidth_cost

                    	when	upstream_bandwidth_cost	>	isp_bandwidth_cost

                    	then	isp_bandwidth_cost

                    	else	upstream_bandwidth_cost

                    end	+	internet_bandwidth_cost)

			  end as	ia_monthly_cost_per_mbps

from	fy2016_districts_demog_matr dd

left	join	fy2016_districts_aggregation_matr	da

on	dd.esh_id	=	da.district_esh_id
),

dd_2017 as 
(select *
from public.fy2017_districts_deluxe_matr),
dd_2016 as (select*from public.fy2016_districts_deluxe_matr)

select dd_2017.*,
case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
then (dd_2017.ia_bw_mbps_total - dd_2016.ia_bw_mbps_total) end as change_in_bw_tot,

case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and (dd_2016.ia_bw_mbps_total=0) and (dd_2017.ia_bw_mbps_total > 0) then 1
when dd_2016.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_analysis = false 
and (dd_2016.ia_bw_mbps_total=0) and (dd_2017.ia_bw_mbps_total = 0) then 0
when dd_2016.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_analysis = false 
then (dd_2017.ia_bw_mbps_total - dd_2016.ia_bw_mbps_total)/dd_2016.ia_bw_mbps_total end as change_in_bw_pct,

case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and (dd_2016.ia_monthly_cost_per_mbps is not null) then
(dd_2017.ia_monthly_cost_per_mbps - dd_2016.ia_monthly_cost_per_mbps) end as change_in_cost_tot,

case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and (nb16.ia_monthly_cost_per_mbps is not null) then
(nb17.ia_monthly_cost_per_mbps - nb16.ia_monthly_cost_per_mbps) end as change_in_cost_tot_nb,

case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and (dd_2016.ia_monthly_cost_per_mbps=0) and (dd_2017.ia_monthly_cost_per_mbps > 0) then 1
when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and(dd_2016.ia_monthly_cost_per_mbps=0) and (dd_2017.ia_monthly_cost_per_mbps = 0) then 0
when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and(dd_2016.ia_monthly_cost_per_mbps is not null) then
(dd_2017.ia_monthly_cost_per_mbps - dd_2016.ia_monthly_cost_per_mbps)/dd_2016.ia_monthly_cost_per_mbps
end as change_in_cost_pct,

case when dd_2016.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_analysis = false 
and (dd_2016.meeting_2014_goal_no_oversub=true) and (dd_2017.meeting_2014_goal_no_oversub=false) then true
else false
end as meeting_to_not_meeting_connectivity,

case when dd_2016.exclude_from_ia_analysis = false and dd_2016.exclude_from_ia_cost_analysis = false and 
dd_2017.exclude_from_ia_analysis = false and dd_2017.exclude_from_ia_cost_analysis = false 
and (dd_2016.meeting_knapsack_affordability_target=true) and (dd_2017.meeting_knapsack_affordability_target=false) then true
else false
end as meeting_to_not_meeting_affordability

from dd_2017 left join dd_2016 on dd_2017.esh_id::integer=dd_2016.esh_id::integer
left join nobcost_2017 nb17 on dd_2017.esh_id::integer=nb17.esh_id::integer
left join nobcost_2016 nb16 on dd_2017.esh_id::integer=nb16.esh_id::integer