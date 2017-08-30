select postal_cd, sum(current_assumed_unscalable_campuses + current_known_unscalable_campuses)
as unscalable_campuses_all
from public.fy2017_districts_deluxe_matr dd
where dd.include_in_universe_of_districts
and dd.district_type = 'Traditional'
and postal_cd in

('ID','AZ','VA','NC','CA','NM','NY','OK','FL','ME','MA','MT','MO','TX','NV','MD','NH','CO','MN','KS','IL')
group by 1
