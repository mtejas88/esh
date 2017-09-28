select
  spin,
  sp_name_before,
  sp_name_after,
  dba_before,
  dba_after
from
  (select
      spin,
      sp_name as "sp_name_before",
      sp_name as "sp_name_after",
      dba as "dba_before",
      right(dba, strpos(lower(dba), 'dba')-4) as "dba_after"
    from
      districts.sps_spin 
    where
      lower(dba) like 'dba%' AND 
      lower(dba) not like 'dba as %' AND
      lower(dba) not like 'dba,%' AND
      lower(dba) not like 'dba -%' AND
      lower(dba) not like 'dba-%' AND
      lower(dba) not like 'dba:%' AND
      lower(dba) not like 'dbas:%' AND
      lower(dba) not like 'dba/%' AND
      lower(dba) not like '% dba%') noDBA
UNION   
select
  spin,
  sp_name_before,
  sp_name_after,
  dba_before,
  dba_after
from
  (select
      spin,
      sp_name as "sp_name_before",
      substring (sp_name, 1, strpos(sp_name, 'dba')-1) as "sp_name_after",
      dba as "dba_before",
      substring (dba, strpos (dba, 'dba')+3, length(dba)) as "dba_after"
    from
      districts.sps_spin 
    where
    (sp_name like '% dba %' AND dba like '% dba %')
    AND sp_name not like '% broadband %'
    AND dba not like '% broadband %') noDBA
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
      substring (sp_name, 1, strpos(sp_name, 'dba')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      districts.sps_spin 
    where
    sp_name like '% dba %'
    AND sp_name not like '% broadband %'
    AND dba not like '% broadband %'
    AND dba not like '% dba %') noDBA
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
      substring (dba, strpos (lower(dba), 'dba')+3, length(dba)) as "dba_after"
    from
      districts.sps_spin 
    where
    lower(dba) like '% dba%'
    AND lower(sp_name) not like '% broadband %'
    AND lower(dba) not like '% broadband %'
    AND lower(sp_name) not like '% dba %'
    AND lower(dba) not like 'dba%'
    AND lower(sp_name) not like 'dba%') noDBA
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
      substring (sp_name, 1, strpos(lower(sp_name), 'dba')-1) as "sp_name_after",
      dba as "dba_before",
      dba as "dba_after"
    from
      districts.sps_spin 
    where
    lower(sp_name) like '% dba%'
    AND lower(sp_name) not like '% broadband %'
    AND lower(dba) not like '% broadband %'
    AND lower(dba) not like '% dba %'
    AND lower(dba) not like 'dba%'
    AND lower(sp_name) not like 'dba%') noDBA
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
      substring (dba, 1, strpos(lower(dba), '(dba)')-1) as "dba_after"
    from
      districts.sps_spin 
    where lower(dba) like '%(dba)%' AND lower(dba) not like '(dba)%' AND lower(sp_name) not like '%dba%'
    AND lower(dba) not like '%broadband%' AND lower(sp_name) not like '%broadband%') noDBA
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
      substring (dba, strpos(lower(dba), '(dba)')+6, length(dba)) as "dba_after"
    from
      districts.sps_spin 
    where
    lower(dba) like '(dba)%' AND lower(sp_name) not like '%dba%'
    AND lower(dba) not like '%broadband%' AND lower(sp_name) not like '%broadband%') noDBA
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
      substring (dba, strpos(lower(dba), 'dba')+4, length(dba)) as "dba_after"
    from
      districts.sps_spin 
    where
    lower(dba) like 'dba%' AND lower(sp_name) not like '%dba%'
    AND lower(dba) not like '%broadband%' AND lower(sp_name) not like '%broadband%') noDBA
    
    
select *
from districts.sps_spin 
where sp_name like '%dba%' or dba like '%dba%'
AND lower(sp_name) not like '% broadband %'
AND lower(dba) not like '% broadband %'