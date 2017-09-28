SELECT
  count(distinct esh.id) as number_sps,
  count(distinct case 
                  when esh.spin is null 
                    then esh.id else null end) as count_not_matching_spins,
  count(distinct case 
                  when esh.spin is not null 
                    then esh.id else null end) as count_matching_spins,
  count(distinct case 
                  when esh.spin is not null
                  AND (esh.name = usac.sp_name 
                  AND esh.reporting_name = usac.dba)
                    then esh.id else null end) as matching_spin_matching_name_reportingname,
  count(distinct case
                  when esh.spin is not null
                  AND esh.name = usac.sp_name
                  AND esh.reporting_name != usac.dba
                    then esh.id else null end) as matching_spin_matching_name,
  count(case
                  when esh.spin is not null
                  AND esh.reporting_name = usac.dba
                  AND esh.name != usac.sp_name
                    then esh.id else null end) as matching_spin_matching_reportingname,
  count(distinct case
                  when esh.spin is not null
                  AND (esh.name != usac.sp_name
                  AND esh.reporting_name != usac.dba)
                    then esh.id else null end) as matching_spin_nonamematch
  FROM public.esh_service_providers esh
  LEFT JOIN public.usac_sp_spin_v1 usac
    ON esh.spin = usac.spin