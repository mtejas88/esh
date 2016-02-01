/*
Author: Justine Schott
Created On Date: 12/30/2015
Last Modified Date: 01/04/2016
Name of QAing Analyst(s): Greg Kurzhals
Purpose: To track district flags, line items, costs, and applicants as data comes in for 2016
Methodology:Using districts table, entity_flags, and line_items tables
*/

select  case when service_category IN ('INTERNAL CONNECTIONS', 'INTERNAL CONNECTIONS MNT', 'INTERNAL CONNECTIONS MIBS') 
		  then 'Category 2'
  			else service_category 
  		end as service_type,
		count(1) as line_item_count,
		sum(total_cost) as total_cost,
		count(distinct 
				CASE WHEN applicant_type = 'District' 
					then applicant_id 
				end
		) as district_applicants,
		count(distinct 
				CASE WHEN applicant_type = 'School' 
					then applicant_id
				end
		) as school_applicants,
		count(distinct 
				CASE WHEN applicant_type = 'Consortium' 
					then applicant_id 
				end
		) as consortia_applicants,
		count(distinct applicant_id) as total_applicants

from line_items

group by case when service_category IN ('INTERNAL CONNECTIONS', 'INTERNAL CONNECTIONS MNT', 'INTERNAL CONNECTIONS MIBS') 
		  then 'Category 2'
  			else service_category 
  		end 