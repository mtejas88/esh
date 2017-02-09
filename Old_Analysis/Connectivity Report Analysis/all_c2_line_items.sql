/*
Author: Sneha Narayanan
Created On Date: 1/21/2016
Last Modified Date: 2/8/2016
Name of QAing Analyst(s): Greg Kurzhals/Justine Schott
Purpose: To pull all C2 line items for a specific state
*/

select *

from line_items 

where service_category in ('INTERNAL CONNECTIONS',
'INTERNAL CONNECTIONS MIBS', 'INTERNAL CONNECTIONS MNT')
and postal_cd = '{{two_letter_state}}' or 'All' = '{{two_letter_state}}'

{% form %}

two_letter_state:
  type: text
  default: 'IL'
  
{% endform %}
