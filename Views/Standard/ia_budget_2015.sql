select  esh_id,
        case
          when (select count(*)
                from (select  esh_id,
                              d.ia_cost_per_mbps::numeric * (d.ia_bandwidth_per_student::numeric/1000) * d.num_students::numeric as ia_annual_cost,
                              (d.ia_bandwidth_per_student::numeric/1000)*d.num_students::numeric as ia_bandwidth,
                              d.ia_cost_per_mbps
                      from public.districts d
                      where include_in_universe_of_districts = true
                        and exclude_from_analysis = false
                        and ia_cost_per_mbps != 'Insufficient data') d_all
        where d.esh_id != d_all.esh_id
        and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
        and d.ia_annual_cost > d_all.ia_annual_cost*.8
                    ) = 0 then 0
        else
                (select count(*)
                 from (select  esh_id,
                               d.ia_cost_per_mbps::numeric * (d.ia_bandwidth_per_student::numeric/1000) * d.num_students::numeric as ia_annual_cost,
                              (d.ia_bandwidth_per_student::numeric/1000)*d.num_students::numeric as ia_bandwidth,
                               d.ia_cost_per_mbps
                       from public.districts d
                       where include_in_universe_of_districts = true
                          and exclude_from_analysis = false
                          and ia_cost_per_mbps != 'Insufficient data') d_all
                  where d.esh_id != d_all.esh_id
                    and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
                    and d.ia_annual_cost> d_all.ia_annual_cost*.8
                    and d.ia_cost_per_mbps >= d_all.ia_cost_per_mbps
                    and d.ia_bandwidth < d_all.ia_bandwidth
                )/(select count(*)
                   from (select  esh_id,
                                  d.ia_cost_per_mbps::numeric * (d.ia_bandwidth_per_student::numeric/1000) * d.num_students::numeric as ia_annual_cost,
                                  (d.ia_bandwidth_per_student::numeric/1000)*d.num_students::numeric as ia_bandwidth,
                                  d.ia_cost_per_mbps
                         from public.districts d
                         where include_in_universe_of_districts = true
                          and exclude_from_analysis = false
                          and ia_cost_per_mbps != 'Insufficient data') d_all
                    where d.esh_id != d_all.esh_id
                    and d.ia_annual_cost<= d_all.ia_annual_cost*1.2
                    and d.ia_annual_cost> d_all.ia_annual_cost*.8
                )::numeric
        end as pct_dists_more_ia_bw_for_ia_budget
        
from (select  esh_id,
                  d.ia_cost_per_mbps::numeric * (d.ia_bandwidth_per_student::numeric/1000) * d.num_students::numeric as ia_annual_cost,
                  (d.ia_bandwidth_per_student::numeric/1000)*d.num_students::numeric as ia_bandwidth,
                  d.ia_cost_per_mbps
          from public.districts d
          where include_in_universe_of_districts = true
          and exclude_from_analysis = false
          and ia_cost_per_mbps != 'Insufficient data') d