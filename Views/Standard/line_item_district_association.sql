select dl.district_esh_id,
	   a.line_item_id
from allocations a
join district_lookup_nifs dl
on a.recipient_id = dl.esh_id

/*
Author:                       Justine Schott
Created On Date:              03/03/2016
Last Modified Date: 
Name of QAing Analyst(s):  
Purpose:                      To determine all possible line items received by a district for the purpose of aiding data cleaning
*/