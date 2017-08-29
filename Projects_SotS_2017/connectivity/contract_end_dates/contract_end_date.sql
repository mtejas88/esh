 select *,
case
  when most_recent_ia_contract_end_date <= '2018-06-30'
    then 1
  when most_recent_ia_contract_end_date <= '2019-06-30'
    then 2
  when most_recent_ia_contract_end_date <= '2020-06-30'
    then 3
  when most_recent_ia_contract_end_date <= '2021-06-30'
    then 4
  when most_recent_ia_contract_end_date <= '2022-06-30'
    then 5
  when most_recent_ia_contract_end_date <= '2023-06-30'
    then 6
  when most_recent_ia_contract_end_date <= '2024-06-30'
    then 7
end as contract_end_time  

from fy2017_districts_deluxe_matr
where include_in_universe_of_districts
and district_type = 'Traditional'
and meeting_2014_goal_no_oversub = FALSE
and exclude_from_ia_analysis = FALSE
