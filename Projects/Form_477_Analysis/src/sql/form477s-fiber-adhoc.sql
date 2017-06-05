with all_avg as (
select avg(f."MaxCIRDown"::float) as avgd, avg(f."MaxCIRUp"::float) as avgup
from public.form477s f
--some of these are strings equal to the field itself
where f."MaxCIRDown" != 'MaxCIRDown'
and f."MaxCIRUp" != 'MaxCIRUp'),

fiber_avg as (
select avg(f."MaxCIRDown"::float) as avgd, avg(f."MaxCIRUp"::float) as avgup
from public.form477s f
where f."TechCode"='50'
--some of these are strings equal to the field itself
and f."MaxCIRDown" != 'MaxCIRDown'
and f."MaxCIRUp" != 'MaxCIRUp')

select a.*, 'all' as c from all_avg a
union
select b.*, 'fiber' as c from fiber_avg b

/*
avgd	            avgup	            c
42.22789681945961	36.766259380184756	all
347.62447828214886	325.88906809271504	fiber
*/