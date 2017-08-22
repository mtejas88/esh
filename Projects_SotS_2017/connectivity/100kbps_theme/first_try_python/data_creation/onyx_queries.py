from pandas import DataFrame

def getDistricts_notmeeting( conn ) :
    cur = conn.cursor()
    cur.execute("""\
    	SELECT*
    	FROM public.fy2017_districts_deluxe_matr 
        where exclude_from_ia_analysis=false
        and include_in_universe_of_districts
        and district_type = 'Traditional'
        and meeting_2014_goal_no_oversub=false
    	ORDER BY esh_id;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)

def getDistricts_meeting( conn ) :
    cur = conn.cursor()
    cur.execute("""\
        SELECT*
        FROM public.fy2017_districts_deluxe_matr 
        where exclude_from_ia_analysis=false
        and include_in_universe_of_districts
        and district_type = 'Traditional'
        and meeting_2014_goal_no_oversub=true
        ORDER BY esh_id;""" )
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)
