select  eb.entity_id,
        sum(case
              when (child_biggest_barriers != 'No barriers' and child_biggest_barriers is not null)
              or (parent_biggest_barriers != 'No barriers' and parent_biggest_barriers is not null)
                then 1
              else 0
            end) as barriers
from fy2016.connectivity_informations ci
left join entity_bens eb
on ci.parent_entity_number = eb.ben
group by 1