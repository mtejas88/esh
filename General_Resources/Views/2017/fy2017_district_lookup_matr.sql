select esh_id, esh_id as district_esh_id

from fy2017_districts_demog_matr

  union

select school_esh_id, district_esh_id

from fy2017_schools_demog_matr




/*

Author:                       Justine Schott

Created On Date:              06/16/2016

Last Modified Date: 		  09/23/2016

Name of QAing Analyst(s):

Purpose:                      To append a list of all instructonal facilities and their associated district_esh_id

                              in order to aggregate services received by all these to the appropriate district (2016)

Modified Date: 4/27/2017
Name of Modifier: Saaim Aslam
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise

*/
