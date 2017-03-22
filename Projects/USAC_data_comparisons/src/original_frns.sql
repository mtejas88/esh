select application_number,
line_item,
type_of_product,
function,
purpose,
download_speed,
download_speed_units,
monthly_quantity,
total_monthly_eligible_recurring_costs
from fy2016.frn_line_items 
where function != 'Voice'