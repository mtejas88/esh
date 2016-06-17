--CRIMSON
select li.id,
--connect_category
li.frn_complete as "frn_complete",
fisc.postal_cd as "raw_postal_cd.x",
fisc."Serv Type" as "raw_service_type.x",
li.service_category as "akira_type_of_service.x",
fisc."Connect Type" as "raw_connect_type.x",
fisc."Purpose" as "raw_purpose.x",
fisc."WAN" as "raw_wan.x",
fisc."No. of Lines" as "raw_num_lines.x",
fisc."Rec Elig Cost" as "raw_rec_elig_cost.x",
fisc."One-time Elig Cost" as "raw_one_time_eligible_cost.x",
case when fisc."Burst Band?" is null and fisc."C1 Burst Band Speed No." is null then 'No' else 'Yes' end as "raw_burstable_bw_entered",
case when fisc."C1 FW Prot Inc?" is null then "FW Prot Inc" else "C1 FW Prot Inc?" end as "raw_firewall",
case when "Last Mile?" is null OR "Last Mile?" not in ('Y', 'N') then fisc."C1 Last mile?" else "Last Mile?" end as "raw_last_mile.x",
case when fisc."Down Speed2"='Gbps'
then "Down Speed1"::numeric*1000.0
else "Down Speed1"::numeric
end as "raw_downspeed_bandwidth.x",

case when fisc."Up Speed1" is null
    then 
        case when "C1 Up Speed Unit"='Gbps'
        then "C1 Up Speed No."::numeric*1000.0
        else "C1 Up Speed No."::numeric end
        
    else 
        case when "Up Speed2"='Gbps'
        then "Up Speed1"::numeric*1000.0
        else "Up Speed1"::numeric end
    end as "raw_upspeed_bandwidth.x",

li.applicant_type as "akira_applicant_type.x",
li.service_provider_name as "akira_service_provider_name",
case when li.service_provider_id in (
6084, 8651, 7869, 7437, 9708, 8632, 8051, 6058, 5813, 9932, 10115, 8823,
9021, 8782, 7497, 10555, 9545, 8447, 9492, 10528, 6399, 10635, 7350, 5379, 6396,
8910, 9784, 8008, 9486, 8510, 6140, 7883, 5848, 8920, 10283, 7543, 5703, 5617)
then 'Yes'
else 'No'
end as "known_isp_only_provider.x",
case when li.service_provider_id in (
10592, 8175, 7003, 9169, 8830, 8825, 10204, 5797, 7636, 6152, 6558, 5951, 7215,
5665, 8039, 7574, 6057, 5562, 9629, 9504, 6724, 5904, 8217, 10565, 7460, 7762,
6705, 10464, 6975, 6120, 8008, 8296, 6881, 5884, 5619, 7521, 9492, 10385, 5640,
5871, 8447, 8482, 7723, 5880, 8437, 9741, 6730, 10440, 8057, 8646, 10272, 5777,
8495, 8366, 7380, 8540, 8020, 10091, 5894, 9326, 8769, 10209, 10406, 10499, 10731,
9228, 9776, 8513, 10541, 5418, 8432, 7501, 10277, 5914, 5877, 8939, 7612, 9166,
7908, 9365, 10232, 8739, 8510, 9633, 10092, 7318, 7124, 7172, 7409, 6708, 9367,
6365, 8678, 10084, 7835, 8855, 8553, 9498, 7962, 8483, 7474, 7664, 6446, 7152,
8841, 6445, 7924, 9876, 8584, 5609, 5587, 8097, 9562, 7333, 9176, 8219, 9145,
7217, 6842, 7911, 5557, 8444, 7010, 10248, 7921, 10694, 9033, 8635, 9444, 7350,
9716, 9299, 8819, 9359, 9921, 5832, 7766, 6698, 10067, 10139, 10096, 5461, 8701,
10035, 5409, 9337, 5466, 7021, 10132, 7548, 7098, 7248)
then 'Yes'
else 'No'
end as "known_fixed_wireless_provider.x",
--GK note: replaced with v7 connect_category logic
case when li.connect_category='Other / Uncategorized'
and li.connect_type not in ('Standalone Internet Access', 'Ethernet', 'Switched Multimegabit Data Service')
then 'Rare Connection'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Ethernet' 
then 'Low-bandwidth Ethernet'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Standalone Internet Access' 
then 'ISP Only'
when li.connect_category='Other / Uncategorized'
and li.connect_type='Switched Multimegabit Data Service' 
then 'Switched Multimegabit' 
when li.connect_category='Cable / DSL'
and li.connect_type='Cable Modem'
then 'Cable'
when li.connect_category='Cable / DSL'
and li.connect_type='Digital Subscriber Line (DSL)'
then 'DSL'
when li.connect_category='Copper'
and (li.connect_type='DS-1 (T-1)'
    OR 
    li.bandwidth_in_mbps::numeric in (1.5, 3, 4.5, 6, 7.5, 9))
then 'T-1'
when li.connect_category='Copper'
and li.connect_type='DS-3 (T-3)'
then 'T-3'
else li.connect_category
end as "connect_category_adjusted",
li.num_recipients as "akira_num_recipients.x",
li.consortium_shared as "akira_consortium_shared.x",
li.connect_category as "akira_connect_category",

--purpose
li.internet_conditions_met,
li.wan_conditions_met,
li.isp_conditions_met,
li.upstream_conditions_met,
li.applicant_type,
li.connect_category,
li.num_lines,
li.bandwidth_in_mbps

from public.line_items li

left join public.fy2015_item21_services_and_costs fisc 
on concat(fisc."FRN", '-', fisc."FRN Line Item No")=li.frn_complete
--GK note: added data plan exclusion
where fisc.postal_cd not in ('AS', 'GU', 'VI', 'DC', 'PR')
and li.broadband=true
and li.erate=true
and li.consortium_shared=false
and li.connect_type!='Data Plan/Air Card Service'


