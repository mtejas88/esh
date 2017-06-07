select substring(f."BlockCode" from 1 for 11) as censustract,
count(distinct f."HoldingCompanyName") as nproviders
from public.form477s f
where f."TechCode"='50'
group by 1