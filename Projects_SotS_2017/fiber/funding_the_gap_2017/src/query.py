from pandas import DataFrame

def getUnscalableBreakdown( conn ) :
    cur = conn.cursor()
    cur.execute( """\
select
  case
    when postal_cd in ( 'AZ', 'CA', 'CO', 'FL', 'ID', 'MA', 'MD', 'ME', 'MO', 'MT', 'NC', 'NH', 'NM', 'NV', 'NY', 'OK', 'TX', 'VA')
    and discount_rate_c1_matrix >= .8
      then 'Upgrade at no cost' 
    when discount_rate_c1_matrix >= .8
      then 'Upgrade at no cost with match fund'
    else 'Upgrade at minimal cost'
  end as diagnosis,
  sum(current_assumed_unscalable_campuses+current_known_unscalable_campuses)::numeric
from public.fy2017_districts_deluxe_matr 
where include_in_universe_of_districts
and district_type = 'Traditional'
group by 1;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)