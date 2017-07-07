select f."BlockCode" as blockcode, 
count(distinct f."HoldingCompanyName") as nproviders,
array_agg(distinct f."HoldingCompanyName") as providerlist
from public.form477s f
where f."TechCode"='50'
group by 1