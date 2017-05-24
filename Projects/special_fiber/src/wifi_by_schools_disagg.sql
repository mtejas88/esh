--MATCHING STATE OF THE STATES

with wifi_lookup as (

SELECT
    COUNT("ID"),
    esh_id,
    parent_wifi
FROM
(SELECT
    DISTINCT dd.esh_id,
    ci.parent_entity_number AS "ID",
    ci.postal_cd,
    ci.parent_entity_name,
    ci.parent_wifi
FROM 
    fy2016.connectivity_informations ci,
    public.entity_bens eb_parent,
    public.fy2016_districts_demog_matr ddm,
    endpoint.fy2016_districts_deluxe dd
WHERE
    ci.parent_entity_number = eb_parent.ben AND
    eb_parent.entity_id = ddm.esh_id::text::INT AND
    dd.esh_id = ddm.esh_id AND
    ci.parent_wifi IS NOT NULL  AND
    dd.include_in_universe_of_districts = TRUE
    
    
GROUP BY
    dd.esh_id,
    ci.parent_entity_number,
    ci.postal_cd,
    ci.parent_entity_name,
    ci.parent_wifi,
    ci.child_entity_name,
    ci.child_wifi
UNION
SELECT
    DISTINCT dd.esh_id,
    ci.child_entity_number AS "ID",
    ci.postal_cd,
    ci.child_entity_name,
    ci.child_wifi
FROM 
    fy2016.connectivity_informations ci,
    public.entity_bens eb_parent,
    public.fy2016_districts_demog_matr ddm,
    endpoint.fy2016_districts_deluxe dd
WHERE
    ci.parent_entity_number = eb_parent.ben AND
    eb_parent.entity_id = ddm.esh_id::text::INT AND
    dd.esh_id = ddm.esh_id AND
    ci.parent_wifi IS NULL AND
    dd.include_in_universe_of_districts = TRUE
    
GROUP BY
    dd.esh_id,
    ci.child_entity_number,    
    ci.postal_cd,
    ci.parent_entity_name,
    ci.parent_wifi,
    ci.child_entity_name,
    ci.child_wifi) answers
GROUP BY
parent_wifi,
esh_id

order by 2,3

)

select esh_id,
sum(case when parent_wifi in ('Sometimes','Never') then count else 0 end) / sum(count) as not_meeting


from wifi_lookup

where parent_wifi is not null
and parent_wifi != 'Not Applicable'

group by 1
order by 1