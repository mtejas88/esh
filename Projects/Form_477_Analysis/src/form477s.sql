select f."BlockCode" as blockcode, 
count(distinct f."HoldingCompanyName") as nproviders,
array_agg(distinct f."HoldingCompanyName") as providerlist
from public.form477s f
group by 1