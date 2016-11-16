select dl.district_esh_id,
	   a.line_item_id
from public.allocations a
join district_lookup_nifs_2015_m dl
on a.recipient_id = dl.esh_id

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date: 		  06/02/2016
Name of QAing Analyst(s):
Purpose:                      To determine all possible line items received by a district for the purpose of aiding data cleaning
*/