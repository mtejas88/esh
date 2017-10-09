select d.esh_id as district_esh_id,
        case
          when eim.entity_id is null then 'Unknown'
            else eim.entity_id::varchar
        end as school_esh_id,
        sc141a."LEAID" as nces_cd,
        sc141a."NCESSCH" as school_nces_code,
        d.include_in_universe_of_districts as district_include_in_universe_of_districts,
        f.name as name,
        f.street__c as address,
        f.city__c as city,
        d.postal_cd as postal_cd,
        left(f.zip_code__c, 5) as zip,
        f.num_students__c::integer as num_students,
        
        case 
          when f.locale__c is null
            then 'Unknown'
          when f.locale__c = 'Small Town'
            then 'Town'
          else f.locale__c
        end as locale,

        case
          when f.charter__c = true then 'Charter'
          when d.district_type = 'Other Agency'
            then 'Other School'
          else 'Traditional'
        end as school_type,
        

        case
          when "TOTFRL"::numeric>0
            then "TOTFRL"::numeric
        end as frl_percentage_numerator,

        case
          when "TOTFRL"::numeric>0 and sc141a."MEMBER"::numeric > 0
            then sc141a."MEMBER"::numeric
        end as frl_percentage_denomenator,
        
        f.campus__c as campus_id

from salesforce.facilities__c f

left join ( select distinct entity_id, nces_code
            from public.entity_nces_codes) eim
on f.esh_id__c = eim.entity_id::varchar

left join public.sc141a
on sc141a."NCESSCH" = eim.nces_code

left join salesforce.account a
on a.sfid = f.account__c

join (select *
      from public.fy2017_districts_demog_matr) d
on d.esh_id = a.esh_id__c::varchar

where eim.entity_id is not null /* JAMIE-TEMP-EDIT this removes the 'Unknown' entities, if we want to add them back in we can remove this line */ 
  and a.recordtypeid = '012E0000000NE6DIAW'
  and a.out_of_business__c = false
  and f.recordtypeid = '01244000000DHd0AAG'
  and f.out_of_business__c = false
  and a.type in ('Charter' ,'Bureau of Indian Education' ,'Tribal', 'Public')
  --exclude charter schools within traditional districts
  and (f.charter__c = false or a.type = 'Charter'
    or f.esh_id__c::numeric in (884369,884383,884385,884416,884438,884459,884468,884472,884473,884479,884485,884498,884513,884515,884524,884660,884704,884834,884865,884987,884998,885122,885148,885298,885301,885325,885342,885348,885376,885644,885655,885665,885667,886551,886583,886613,886664,886674,886686,886709,886716,886763,886878,886893,887017,887420,887440,887446,887515,887529,887627,887630,887755,887827,887913,887918,887929,887937,888009,888026,888122,888126,888127,888132,888134,888139,888142,888143,888280,888333,888339,888345,888412,888480,888532,888561,888745,888747,888821,888831,888923,889190,889244,889315,889374,889467,889473,889475,889480,889483,889487,889494,889497,889500,889504,889521,889533,889603,889612,889622,890344,890472,890708,890841,891022,891142,891240,891269,891281,891324,891343,891460,891466,891475,891498,891509,891594,891611,891874,891889,892116,892139,892151,892159,892178,892190,892200,892240,892371,892655,892671,892683,892687,892688,892698,892813,892826,892848,892891,892951,893167,893410,893541,893545,893818,893991,894075,894076,894086,894089,894096,894107,894117,894605,894607,894613,894622,894625,894630,894640,894646,894647,894657,894665,894739,894816,895016,895029,895068,895093,895156,895170,895520,895528,895580,895692,895740,895763,895935,895940,896146,896213,896344,896350,896491,896506,896732,896864,896947,896949,897077,897107,897137,897146,897157,897159,897191,897249,897280,897285,897318,897372,897684,897825,897863,898041,898102,898236,898283,898322,898332,898390,898401,898580,898616,898640,898643,898688,899001,899084,899144,899154,899176,899211,899212,899232,899330,899333,899353,899481,899704,899719,899730,899738,899742,899748,899749,899823,899869,899895,900038,900073,900167,900223,900242,902374,902375,902433,902555,902591,902782,902895,903202,903208,903228,903337,903340,904035,904059,904349,904567,904681,904770,904815,905105,905207,905208,905211,905250,905253,905286,905341,905456,905465,905468,905472,905478,905501,905512,905519,905542,905559,905574,905590,905601,905617,905629,905644,905652,905659,905753,905863,906009,906060,906220,906234,906285,906292,906376,906383,906640,906837,906857,906974,907017,907058,907086,907126,907127,907188,907196,907217,907238,907261,907276,907571,907584,907593,907602,907616,907633,907723,907804,907807,907829,907906,908210,908417,908478,908561,908694,909017,909098,909218,909463,909509,909589,909837,909914,910299,910335,910491,910654,911684,911968,912219,912683,912703,912741,912744,912824,912846,912881,913125,913320,913464,913552,913859,913943,914228,914361,914406,914872,914887,915199,915309,915631,915678,915698,915709,915985,916002,916004,916026,916048,916050,916052,916161,916220,916241,916279,916288,916419,916444,916564,916714,916716,916717,916733,916736,916757,916760,916805,916843,916958,916961,917148,917179,917211,917223,917229,917246,917278,917293,917578,917663,917673,917689,917694,917718,917730,917739,917747,917761,917769,917817,917830,917843,917879,917881,917889,917935,917945,917956,917985,917996,918018,918029,918038,918046,918056,918060,918062,918208,918493,918495,918791,920212,920537,920665,920689,920691,920810,923162,923817,924815,925015,925400,925496,925646,926252,927169,927337,927345,927363,927834,928866,929749,929859,929864,930306,930344,930359,931316,931571,931618,931750,932180,932417,932575,933309,933438,934273,935092,935421,935426,937127,938020,938055,938158,938214,938557,938778,938799,939420,941236,942355,942685,942694,942707,942788,942997,943123,943158,943223,943301,943357,943422,943549,943574,943613,943765,943819,943828,943839,944251,944332,944432,944447,944460,944461,944466,944551,944552,944582,944615,944881,944898,944940,945134,945372,945498,945698,945817,947032,947082,947209,947248,947388,947438,947703,947778,948038,948085,948222,948235,948387,948651,948749,948774,948886,948923,949341,950639,950719,950774,950840,950848,950852,951571,952107,952186,952336,952517,952521,952667,952675,952696,952719,952754,952781,952792,952896,952912,952933,952985,953032,953124,953127,953133,953255,953302,953322,953416,953642,953669,954020,954088,954165,954369,954387,954433,954457,954486,954509,954520,954586,954623,954658,954666,954762,954793,954813,954860,955069,955170,955270,955283,955293,955295,955372,955375,955390,955400,955501,955681,955992,956209,956481,956867,957119,957183,957218,957234,957590,958357,958359,959489,959521,959675,960004,960012,960049,960308,960340,960351,960359,961137,961425,961676,961772,961836,961852,961860,961881,962551,962631,962648,962724,962730,962739,962770,962873,962929,963012,963097,963231,963316,963449,963508,963519,963528,963577,963659,963757,963983,963992,964011,964175,964187,964198,964284,964508,965186,965238,965305,965337,965399,965544,965642,966230,966324,966490,966544,966565,966615,966750,967341,967487,967497,967507,967509,967834,967937,967939,967954,967973,968090,968182,968336,968452,968491,969375,969858,969902,969988,970023,970067,970417,970426,970474,970487,970503,970530,970693,971157,971722,971867,972362,972520,972617,972703,972756,972782,972810,972925,972988,973005,973019,973039,973603,973922,973979,974340,974585,974588,974683,975306,975315,975871,975910,976143,976216,976324,977426,977554,977573,977584,977601,977622,977974,978461,978674,978980,979320,979365,979381,979447,979465,979494,979524,979991,980001,980009,980191,981704,982117,982124,982175,982814,983616,983840,984375,984454,984481,984563,984600,984601,984610,984633,984965,984998,985009,985018,985055,985064,985074,985112,985129,985130,985151,985152,985162,985169,985185,985196,985224,985238,985265,985284,985288,985294,985295,985304,985312,985316,985317,985326,985349,985409,985530,985705,985972,985977,986132,986133,986167,986172,986449,986472,986508,986653,986776,987098,987219,987562,987573,987662,987738,987817,987962,987972,988015,988498,988528,988969,989395,989404,989629,989636,989637,989673,989812,990076,990110,990112,990160,990177,990186,990227,990264,990274,990502,990561,990603,990604,990683,990712,990832,990833,990834,990837,990904,991071,991109,991131,991209,991559,991574,991632,991636,991648,991655,991674,991756,991851,991993,992194,992262,992288,992293,992329,992644,992715,992798,992824,993110,993202,993229,993236,993310,993334,993335,993375,993379,993414,993422,993497,993505,993531,993536,993538,993539,993620,993624,993733,993773,993901,993915,994004,994150,994223,994246,994247,994254,994298,994301,994312,994321,994440,994449,994452,994454,994649,994671,994704,994707,994859,994893,994991,995015,995054,995117,995121,995125,995145,995153,995214,995273,995336,995338,995380,995384,995385,995386,995391,995392,995394,995430,995523,995526,995531,995536,995539,995559,995570,995575,995576,995614,995617,995633,995646,995655,995692,995713,995794,995821,995836,995853,995856,995859,995871,995956,995966,995989,996003,996008,996013,996053,996096,996099,996111,996113,996116,996117,996129,996174,996289,996368,996416,996432,996447,996517,996640,996867,996878,996925,996972,997082,997086,997087,997089,997090,998048,998121,998159,998198,998245,998253,998271,998286,998300,998313,998314,998327,998328,998329,998339,999179,1001364,1001367,1001388,1001389,1001392,1001398,1001416,1001422,1001434,1001446,1001448,1001449,1001888,1001897,1073314,1073317,1073322,1073334,1073405,1073481,1073506,1073517,1073574,1073598,1073602,1073741,1073756,1073831,1073838,1073916,1073960,1073981,1073998,1074020,1074122,1074202,1074294,1074322,1074442,1074480,1074510,1074671,1074794,1074826,1074914,1074949,1074954,1075030,1075077,1075184,1075221,1075247,1075253,1075317,1075368,1075399,1075409,1075436,1075454,1075489,1075539,1075571,1084635,1084650,1084652,1084663,1084690,1084699,1084701,1084712,1084725,1084736,1084749,1084757,1084772,1084775,1084782,1084783,1084806,1084807,1084854,1084857,1084919,1084923,1085149,1085160,1085180,1085184,1085218,1085219,1085414,1085915,1086006,1086147,1086254,1086455,1086461,1086481,1086484,1086487)
    )
/*
Author: Justine Schott
Created On Date: 6/20/2016
Modified Date: 7/7/2017
Name of Modifier: Jeremy - changing num students to integer, fixed MT, condensed all logic
Name of QAing Analyst(s):
Purpose: Refactoring tables for 2017 data
Methodology: Using updated tables names for 2017 underline tables, as per discussion with engineering. Utilizing the same architecture currently for this exercise
usage of public.flags with funding year
*/