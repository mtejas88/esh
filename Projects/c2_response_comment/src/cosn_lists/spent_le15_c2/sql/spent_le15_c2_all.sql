with t as (select esh_id,
name,
postal_cd,
c2_prediscount_budget_15,
c2_prediscount_remaining_17,
c2_postdiscount_remaining_17,
needs_wifi

from public.fy2017_districts_deluxe_matr
)

select*from t
where round(c2_prediscount_remaining_17,0)>=.85*round(c2_prediscount_budget_15,0)