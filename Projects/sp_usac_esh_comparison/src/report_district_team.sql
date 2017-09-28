SELECT esh.name,
       esh.reporting_name,
       usac.sp_name,
       usac.dba,
       esh.id,
       usac.spin AS "usac_spin",
       esh.spin AS "esh_spin"
FROM public.esh_service_providers esh
LEFT JOIN public.usac_sp_spin_v2 usac
  ON esh.spin = usac.spin
  WHERE esh.spin is not null
    AND esh.name != usac.sp_name
    AND esh.reporting_name = usac.dba