select dd.*

  , fbts.fiber_target_status
  , fbts.bw_target_status


from endpoint.fy2016_districts_deluxe dd

left join endpoint.fy2016_fiber_bw_target_status fbts
on dd.esh_id = fbts.esh_id

where dd.include_in_universe_of_districts = true



/* Crusher Materialized: https://github.com/educationsuperhighway/ficher/blob/master/Views/Materialized/2016%20Material%20Girl%20Equivalents/fy2016_districts_deluxe_m.sql
Crusher Standard: https://github.com/educationsuperhighway/ficher/blob/master/Views/Standard/2016%20Material%20Girl%20Equivalents/fy2016_districts_deluxe.sql
Material Girl Endpoint: https://github.com/educationsuperhighway/ecto/blob/master/db_ecto/material_girl/endpoint/fy2016_districts_deluxe.sql
*/