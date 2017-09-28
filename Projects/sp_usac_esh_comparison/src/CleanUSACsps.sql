--inc
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      substring(sp_name, 1, strpos(lower(sp_name), 'inc')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '%inc%'
      AND lower(sp_name) not like '%inci%'
      AND lower(sp_name) not like '%inco%'
      AND lower(sp_name) not like '%ince%'
      AND lower(sp_name) not like '%incu%'
      AND lower(sp_name) not like '%inca%'
      ) noInc
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'inc')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '%inc%'
      AND lower(dba) not like '%inci%'
      AND lower(dba) not like '%inco%'
      AND lower(dba) not like '%ince%'
      AND lower(dba) not like '%incu%'
      AND lower(dba) not like '%inca%'
      ) noInc
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      substring(sp_name, 1, strpos(lower(sp_name), 'inc')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% inc%'
      ) noInc
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'inc')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% inc%'
      ) noInc
--llc
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(name), 'llc'),
      substring(sp_name, 1, strpos(lower(sp_name), 'llc')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '%llc%' 
      AND lower(sp_name) not like '%allc%' 
      AND lower(sp_name) not like '%ellc%'
      AND lower(sp_name) not like '%ullc%'
      AND lower(sp_name) not like '%illc%'
      AND lower(sp_name) not like '%ollc%') noLLC
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'llc')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '%llc%' 
      AND lower(dba) not like '%allc%' 
      AND lower(dba) not like '%ellc%'
      AND lower(dba) not like '%ullc%'
      AND lower(dba) not like '%illc%'
      AND lower(dba) not like '%ollc%') noLLC
--
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'l.l.c.'),
      substring(sp_name, 1, strpos(lower(sp_name), 'l.l.c.')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '%l.l.c.%' 
      AND lower(sp_name) not like '%allc%' 
      AND lower(sp_name) not like '%ell%'
      AND lower(sp_name) not like '%ull%'
      AND lower(sp_name) not like '%ill%'
      AND lower(sp_name) not like '%oll%') noLLC
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'l.l.c.'),
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'l.l.c.')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '%l.l.c.%' 
      AND lower(dba) not like '%allc%' 
      AND lower(dba) not like '%ell%'
      AND lower(dba) not like '%ull%'
      AND lower(dba) not like '%ill%'
      AND lower(dba) not like '%oll%') noLLC

--llp
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(name), 'llp'),
      substring(sp_name, 1, strpos(lower(sp_name), 'llp')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '%llp%' 
      AND lower(sp_name) not like '%allp%' 
      AND lower(sp_name) not like '%ellp%'
      AND lower(sp_name) not like '%ullp%'
      AND lower(sp_name) not like '%illp%'
      AND lower(sp_name) not like '%ollp%') noLLP
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'llp')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '%llp%' 
      AND lower(dba) not like '%allp%' 
      AND lower(dba) not like '%ellp%'
      AND lower(dba) not like '%ullp%'
      AND lower(dba) not like '%illp%'
      AND lower(dba) not like '%ollp%') noLLP
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'l.l.p.'),
      substring(sp_name, 1, strpos(lower(sp_name), 'l.l.p.')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '%l.l.p.%' 
      AND lower(sp_name) not like '%allp%' 
      AND lower(sp_name) not like '%ellp%'
      AND lower(sp_name) not like '%ullp%'
      AND lower(sp_name) not like '%illp%'
      AND lower(sp_name) not like '%ollp%') noLLP
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'l.l.p.'),
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'l.l.p.')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '%l.l.p.%' 
      AND lower(dba) not like '%allp%' 
      AND lower(dba) not like '%ellp%'
      AND lower(dba) not like '%ullp%'
      AND lower(dba) not like '%illp%'
      AND lower(dba) not like '%ollp%') noLLP
--LP
UNION
  select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      left(sp_name, strpos(lower(sp_name), 'lp')-1) as "sp_name_after",
      dba as "dba_before",
      left(dba, strpos(lower(dba), 'lp')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      (lower(sp_name) like '% lp%' OR lower(dba) like '% lp%')) noLP
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      left(sp_name, strpos(lower(sp_name), 'l.p.')-1) as "sp_name_after",
      dba as "dba_before",
      left(dba, strpos(lower(dba), 'l.p.')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      (lower(sp_name) like '% l.p%' OR lower(dba) like '% l.p%')) noLP
--Corp
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'corp') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'corp')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% corp%' 
      AND lower(dba) not like '% corp%'
      AND lower(sp_name) not like 'corp%' 
      AND lower(dba) not like 'corp%') noCORP
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'corp')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% corp%' 
      AND lower(sp_name) not like '% corp%'
      AND lower(sp_name) not like 'corp%' 
      AND lower(dba) not like 'corp%') noCORP
--Company
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'comp') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'comp')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% comp%' 
      AND lower(dba) not like '% comp%'
      AND lower(sp_name) not like 'comp%' 
      AND lower(dba) not like 'comp%'
      AND lower(sp_name) not like '%compu%'
      AND lower(dba) not like '%compu%') noCOMP
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'comp')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% comp%' 
      AND lower(sp_name) not like '% comp%'
      AND lower(sp_name) not like 'comp%' 
      AND lower(dba) not like 'comp%'
      AND lower(sp_name) not like '%compu%'
      AND lower(dba) not like '%compu%') noCOMP
--Enterprise
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'enterprise') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'enterprise')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% enterprise%' 
      AND lower(dba) not like '% enterprise%'
      ) noENTERPRISE
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'enterprise')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% enterprise%' 
      AND lower(sp_name) not like '% enterprise%'
      ) noENTERPRISE
--Limited and Ltd
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'limited') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'limited')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% limited%' 
      AND lower(dba) not like '% limited%'
      ) noLIMITED
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'limited')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% limited%' 
      AND lower(sp_name) not like '% limited%'
      ) noLIMITED
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'ltd') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'ltd')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% ltd%' 
      AND lower(dba) not like '% ltd%'
      ) noLTD
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'ltd')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% ltd%' 
      AND lower(sp_name) not like '% ltd%'
      ) noLTD
-- Of, THe, The
UNION
select
  spin,
  sp_name as "sp_name_before",
  replace(sp_name,'Of','of') as "sp_name_after",
  dba as "dba_before",
  replace(dba,'Of','of') as "dba_after"
from
  public.usac_sp_spin_v2
where
  dba like '% Of %' 
  OR sp_name like '% Of %'
UNION
select
  spin,
  sp_name as "sp_name_before",
  replace(sp_name,'The','the') as "sp_name_after",
  dba as "dba_before",
  replace(dba,'The','the') as "dba_after"
from
  public.usac_sp_spin_v2
where
  (dba like '% The %' 
  OR sp_name like '% The %')
  AND dba not like 'The %'
  AND sp_name not like 'The %'
UNION
select
  spin,
  sp_name as "sp_name_before",
  replace(sp_name,'THe','the') as "sp_name_after",
  dba as "dba_before",
  replace(dba,'THe','the') as "dba_after"
from
  public.usac_sp_spin_v2
where
  dba like '%THe %' 
  OR sp_name like '%THe %'
--Tele -> Telephone
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'tele', 'telephone') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% telephone %' 
      AND lower(dba) like '% tele %'
      ) noTELEPHONE
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'tele', 'telephone') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% telephone %' 
      AND lower(sp_name) like '% tele %'
      ) noTELEPHONE
--Tele -> Telephone
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'tele', 'telecommunication') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% telecommunication %' 
      AND lower(dba) like '% tele %'
      ) noTELECOMM
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'tele', 'telecommunication') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% telecommunication %' 
      AND lower(sp_name) like '% tele %'
      ) noTELECOMM
--Comm
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'comm', 'communications') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% communication%'
      AND lower(dba) like '% comm %'
      ) noCOMM
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'comm', 'communication') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% communication%' 
      AND lower(sp_name) like '% comm %'
      ) noCOMM
--Muni
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'muni', 'municipal') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% municipal%'
      AND lower(dba) like '% muni %'
      ) noMUNI
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'muni', 'municipal') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% municipal%' 
      AND lower(sp_name) like '% muni %'
      ) noMUNI
--COOP
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'coop', 'cooperative') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% cooperative%'
      AND lower(dba) like '% coop%'
      AND lower(dba) not like '% cooperative%'
      ) noCOOP
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'coop', 'cooperative') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% cooperative%' 
      AND lower(sp_name) like '% coop%'
      AND lower(sp_name) not like '% cooperative%'
      ) noCOOP
-- Tech -> Technology
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      replace(lower(dba), 'tech', 'technology') as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% technolog%'
      AND lower(dba) like '% tech%'
      AND lower(dba) not like '% technolog%'
      ) noTECH
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      replace(lower(sp_name), 'tech', 'technology') as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% technolog%' 
      AND lower(sp_name) like '% tech%'
      AND lower(sp_name) not like '% technolog%'
      ) noTECH
-- Commission
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'commission') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'commission')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% commission%' 
      AND lower(dba) not like '% commission%'
      ) noCOMMISSION
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'commission')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% commission%' 
      AND lower(sp_name) not like '% commission%'
      ) noCOMMISSION
-- Cooperative
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'cooperative') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'coop')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% coop%' 
      AND lower(dba) not like '% coop%'
      ) noCOOPERATIVE
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'coop')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% coop%' 
      AND lower(sp_name) not like '% coop%'
      ) noCOOPERATIVE

-- Association

UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      --strpos(lower(sp_name), 'telecom') as "sp_name_after",
      substring(sp_name, 1, strpos(lower(sp_name), 'association')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(sp_name) like '% association%' 
      AND lower(dba) not like '% association%'
      ) noASSOCIATION
UNION
select
  spin,
  sp_name_before,
  replace(sp_name_after,',',' ') as "sp_name_after",
  dba_before,
  replace(dba_after,',',' ') as "dba_after"
  from
    (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      substring(dba, 1, strpos(lower(dba), 'association')-1) as "dba_after"
    from
      public.usac_sp_spin_v2
    where
      lower(dba) like '% association%' 
      AND lower(sp_name) not like '% association%'
      ) noASSOCIATION
