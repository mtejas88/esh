/* copied from https://modeanalytics.com/educationsuperhighway/reports/312c9556dcf5 */

select *, 
array_to_string(school_esh_ids, ', ') as school_esh_ids
from districts 
where (postal_cd= '{{state}}' OR 'All'='{{state}}')
and include_in_universe_of_districts = true
and (exclude_from_analysis::varchar='{{exclude_from_analysis}}' OR 'All'='{{exclude_from_analysis}}')

{% form %}

state:
  type: text
  default: 'All'
  
exclude_from_analysis:
  type: select
  default: 'All'
  options: [['true'],
            ['false'],
            ['All']
           ]

{% endform %}