select substring(f."BlockCode" from 1 for 12) as blockgroup,
count(distinct f."HoldingCompanyName") as nproviders
from public.form477s f
where f."TechCode"='50'
group by 1