select esh_id,
nces_cd,
name,
district_type,
postal_cd
from public.fy2017_districts_deluxe_matr 
where postal_cd = 'CA'
and district_type = 'Traditional'
and include_in_universe_of_districts = true