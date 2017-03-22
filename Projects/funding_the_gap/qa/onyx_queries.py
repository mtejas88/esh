from pandas import DataFrame

#to-do: query returns traditional, BIE, and charter in AZ. do we want to include more?

def getCampuses( conn ) :
    cur = conn.cursor()
    cur.execute( "SELECT * FROM public.fy2016_campuses_for_ftg_matr order by esh_id;" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)

def getDistricts( conn ) :
    cur = conn.cursor()
    cur.execute("""\
    	SELECT 	distinct
    				esh_id, district_nces_cd, district_name, district_postal_cd, district_latitude, district_longitude,
    				district_locale, district_num_campuses, district_num_schools, district_num_students, c1_discount_rate_or_state_avg,
    				denomination, district_exclude_from_ia_analysis, district_fiber_target_status, district_num_campuses_unscalable,
                    district_hierarchy_ia_connect_category
    	FROM public.fy2016_campuses_for_ftg_matr ftg
    	ORDER BY esh_id;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)
