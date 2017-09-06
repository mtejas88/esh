with form_470_lookup as (

select distinct "BEN" as applicant_ben,
case  when "BEN" = '17012451' then '126483'
      when "BEN" = '17012902' then '122050'
      when "BEN" = '17013763' then '126440'
      when "BEN" = '17013790' then '145571'
      else "BEN" end as adj_applicant_ben, 
--"Billed Entity Name",
"Applicant Type"

from fy2017.form470s f

where "470 Number" in (
170074690,
170058737,
170051761,
170074827,
170070536,
170077247,
170066322,
170078938,
170059729,
170054771,
170077152,
170077155,
170080767,
170082332,
170075539,
170075261,
170058003,
170059639,
170062794,
170058333,
170072022,
170059380,
170082190,
170062430,
170048238,
170073943,
170067711,
170056094,
170055757,
170060934,
170065667,
170060614,
170070943,
170079202,
170067492,
170079917,
170071634,
170071680,
170080026,
170065885,
170054760,
170063435,
170077791,
170076609,
170070793,
170068705,
170068705,
170068705,
170068705,
170068705,
170068705,
170057295,
170048934,
170051028,
170047188,
170059732,
170053436,
170067646,
170047145,
170059701,
170048660,
170049337,
170046725,
170047258,
170055408,
170066802,
170063513,
170052150,
170066664,
170068203,
170052561,
170052575,
170065300,
170051672,
170080054,
170061268,
170061211,
170068665,
170077881,
170056406,
170050964,
170081581,
170066938,
170065634,
170067135,
170074380,
170071537,
170078423,
170069586,
170073674,
170072967,
170068704,
170076860,
170070285,
170071810,
170075472,
170073265,
170067366,
170049649,
170079010,
170079343,
170057079,
170060642,
170064662,
170067674,
170072302,
170080768,
170078982,
170072169,
170067058,
170066639,
170072786,
170076993,
170077496,
170076219,
170068453,
170076222,
170076935,
170073666,
170065990,
170073981,
170067458,
170070211,
170070458,
170070314,
170080542,
170073040,
170077069,
170082189,
170073145,
170063141,
170082527,
170080564,
170077742,
170057047,
170077030,
170079911,
170069061,
170076683,
170069716,
170074748,
170076975,
170075073,
170080647,
170068990,
170068439,
170071332,
170062891,
170066828,
170069697,
170081447,
170069288,
170081682,
170079432,
170069400,
170071915,
170078989,
170069942,
170075811,
170069446,
170076548,
170082530,
170074289,
170071980,
170068691,
170082440,
170070131,
170065774,
170080135,
170080855,
170076454,
170078643,
170069857,
170069211,
170079414,
170068028,
170066229,
170067156,
170077362,
170075787,
170069561,
170073074,
170070296,
170073049,
170047220,
170073794,
170081167,
170069699,
170072023,
170073342,
170072606,
170082860,
170067015,
170073227,
170075494,
170067414,
170067154,
170082697,
170072347,
170069278,
170066736,
170072569,
170062803,
170076312,
170075532,
170076146,
170079244,
170076417,
170079095,
170068753,
170078679,
170070883,
170056491,
170069683,
170069803,
170075020,
170065615,
170068821,
170069324,
170068561,
170063700,
170073183,
170070858,
170058391,
170082531,
170069557,
170070508,
170072460,
170074063,
170076165,
170078357,
170081910,
170076720,
170071913,
170072932,
170064915,
170073577,
170079507,
170062979,
170070109,
170079193,
170077767,
170067911,
170079521,
170072820,
170074685,
170082863,
170079597,
170080205,
170079504,
170074915,
170081536,
170077713,
170078418,
170077535,
170072410,
170080234,
170076221,
170075417,
170074017,
170079268,
170080650,
170073123,
170073683,
170075285,
170073131,
170073859,
170075929,
170079844,
170079348,
170079402,
170071212,
170071962,
170074971,
170070085,
170074994,
170067808,
170082112,
170077600,
170072264,
170070513,
170079786,
170073742,
170071043,
170081839,
170074951,
170068811,
170074277,
170076018,
170074828,
170081602,
170071878,
170069601,
170072178,
170082876,
170069864,
170072165,
170047086,
170073425,
170065853,
170047081,
170077992,
170061515,
170079559,
170070231,
170080754,
170071919,
170078078,
170080969,
170073897,
170077514,
170070838,
170068640,
170070327,
170075496,
170079298,
170080744,
170079228,
170074099,
170082542,
170073455,
170073603,
170073604,
170073116,
170072590,
170073506,
170080213,
170076090,
170077232,
170075697,
170080860,
170071968,
170078073,
170075260,
170048978,
170071669,
170076853,
170078680,
170071800,
170080212,
170076638,
170080653,
170069607,
170070674,
170071082,
170074231,
170074696,
170052132,
170082205,
170073267,
170066405,
170072880,
170073903,
170074159,
170073644,
170076497,
170082077,
170074806,
170066873,
170079810,
170082160,
170074208,
170070851,
170065470,
170079081,
170070248,
170077763,
170072375,
170077399,
170070631,
170072504,
170074837,
170061988,
170069174,
170074018,
170080056,
170072154,
170070563,
170070575,
170068501,
170066248,
170081354,
170066530,
170073143,
170068290,
170075835,
170072414,
170078666,
170067993,
170080095,
170073771,
170074879,
170069950,
170071903,
170074555,
170075666,
170079271,
170081870,
170078843,
170070848,
170076603,
170075168,
170080433,
170070405,
170080856,
170079243,
170080854,
170070992,
170082589,
170079174,
170082429,
170076313,
170076163,
170077360,
170079014,
170073406,
170077968,
170082337,
170079372,
170069738,
170078942,
170081221,
170082264,
170076707,
170070247,
170075247,
170082628,
170073273,
170076047,
170072691,
170075673,
170079862,
170063628,
170081811,
170067087,
170062312,
170066292,
170056368,
170059808,
170052628,
170070419,
170047028,
170058640,
170062733,
170053324,
170062768,
170063533,
170068107,
170058841,
170066037,
170061694,
170060995,
170069602,
170057042,
170052843,
170055900,
170048317,
170049524,
170061091,
170057282,
170061340,
170058996,
170059826,
170052332,
170048328,
170054947,
170059750,
170052281,
170059275,
170062149,
170048974,
170058135,
170059936,
170067078,
170052193,
170048798,
170058283,
170050250,
170049409,
170061982,
170062075,
170049087,
170054974,
170059596,
170068926,
170051427,
170047997,
170058965, 170058998,
170051947,
170053695,
170065889,
170060288,
170062366,
170053212,
170063782,
170060619,
170060598,
170056590,
170056480,
170054903,
170062264,
170062880,
170056934,
170058358,
170058366,
170065407,
170068504,
170057375,
170055377,
170064464,
170060552,
170062026,
170062495,
170060829,
170063074,
170062303,
170066320,
170057974,
170064251,
170062868,
170062566,
170056051,
170069705,
170079920,
170073603,
170069579,
170055397,
170061395,
170062932,
170053058,
170053965,
170053948,
170054389,
170055872,
170057714,
170064614,
170065581,
170060061,
170052837,
170059447,
170060955,
170060174,
170049310,
170051904,
170061230,
170058102,
170061451,
170048169,
170051534,
170056678,
170063097,
170055767,
170056322,
170057020,
170065936,
170052801,
170054141,
170070384,
170069667,
170056123,
170067465,
170077858,
170061928,
170057539,
170072822,
170057781,
170057789,
170047057,
170056508,
170067070,
170050783,
170065674,
170055162,
170068356,
170063415,
170066517,
170061957,
170050576,
170063335,
170060057,
170057772,
170067483,
170062203,
170062799,
170061949,
170062800,
170062788,
170069388,
170057075,
170062798,
170062801,
170049654,
170050650,
170064123,
170065830,
170056948,
170064080,
170065994,
170058973,
170073398,
170064079,
170065613,
170058849,
170061953,
170054629,
170055710,
170053328,
170054864,
170051317,
170051279,
170074860,
170074878,
170053340,
170056205,
170055375,
170059874,
170057277,
170058402,
170059903,
170057940,
170058086,
170082761,
170053814,
170058067,
170058421,
170058340,
170058413,
170058346,
170057343,
170057048,
170058425,
170048806,
170057319,
170051502,
170058422,
170060741,
170058342,
170071799,
170071818,
170069269,
170060333,
170063223,
170061868,
170051619,
170049875,
170058944,
170057864,
170069848,
170059640,
170059271,
170047020,
170063738,
170060719,
170047180,
170051623,
170052598,
170050609,
170063222,
170067665,
170048745, 170048756,
170056081,
170049488,
170065579,
170060528,
170056045,
170061113,
170055036,
170054192,
170055738,
170056207,
170049063,
170049653,
170050411,
170052441,
170058717,
170051624,
170075458,
170071646,
170070097,
170067887,
170079905,
170062108,
170060118,
170070250,
170052650,
170063526,
170065104,
170061750,
170064157,
170057603,
170062262,
170064824,
170052096,
170056195,
170053688,
170052986,
-- ,
170071769,
170051100,
170051199,
170062396,
170049852,
170051057,
170051221,
170048291,
170060570,
170060420,
170072221,
170047043,
170048623,
170059872,
170065605,
170058252,
170057881,
170056422,
170057439,
170050813,
170046681,
170063991,
170047255,
170061250,
170075767,
170064324,
170048679,
170058361,
170064564,
170059207,
170064228,
170070365,
170063970,
170062512,
170049647,
170064936,
170064081,
170061433,
170054459,
170055203,
170053841,
170063886,
170059946,
170058751,
170058407,
170063822,
170062899,
170062055,
170059175,
170054476,
170058057,
170060084,
170064188,
170058934,
170059326,
170049677,
170049477,
170080487,
170055152,
170050188,
170057429,
170047727,
170061415,
170052634,
170049277,
170052165,
170066598,
170061193,
170054481,
170075544,
170049241,
170070325,
170062675,
170065069,
170068617,
170069069,
170049136,
170055144,
170066964,
170066203,
170069914,
170054777,
170054778,
170066403,
170069387,
170064071,
170054201,
170052914,
170049582,
170054787,
170063001,
170060050,
170053072,
170065350,
170048673,
170068270,
170057067,
170072779,
170065609,
170067807,
170059256,
170065008,
170066689,
170063915,
170060295
)
and f."BEN" not in ('17005813') --library
and f."BEN" not in ('17011474') --oklahoma statewide contract
and f."BEN" not in ('17014177', '57232') --private schools
and f."BEN" not in ('17013877') --no eligible entities

),

spek_c as (

select distinct dd.esh_id
from form_470_lookup l
join public.entity_bens eb
on l.adj_applicant_ben = eb.ben
join public.fy2017_district_lookup_matr dl
on eb.entity_id::varchar = dl.district_esh_id
join public.fy2017_districts_deluxe_matr dd
on dl.district_esh_id = dd.esh_id

),

base_pop as(
select * from public.fy2016_districts_deluxe_matr 
where fiber_target_status='Target'
and include_in_universe_of_districts
and district_type = 'Traditional'
and exclude_from_ia_analysis=false),

temp as (
  
    select 
    dd.esh_id,
    sum(frns.num_bids_received::numeric) as num_bids_received,
    sum(case
          when frns.num_bids_received::numeric = 0 or frns.num_bids_received is null
            then 1
          else 0
        end) as num_fiber_470_frns_with_0_bids,
    case
      when sum(frns.num_bids_received::numeric) = 0
        or sum(frns.num_bids_received::numeric) is null
        then 1
      else 0
    end as district_received_0_bids
    from fy2017.form470s 
    left join fy2017.frns 
    on form470s."470 Number" = frns.establishing_fcc_form470::int
    
    left join public.entity_bens eb
    on form470s."BEN" = eb.ben
    
    left join public.fy2017_district_lookup_matr dl
    on dl.district_esh_id = eb.entity_id::varchar
    
    left join public.fy2017_districts_deluxe_matr dd
    on dl.district_esh_id = dd.esh_id
    
    where "Service Type" = 'Internet Access and/or Telecommunications'
    and "Function" not in ( 'Internet Access: ISP Service Only', 'Other', 'Cellular Data Plan/Air Card Service', 
                            'Cellular Voice', 'Voice Service (Analog, Digital, Interconnected VOIP, etc)')
    and ("Function" ilike '%fiber%' 
        or left("Minimum Capacity",length("Minimum Capacity")-5)::numeric >= 200
        or right("Minimum Capacity",4)= 'Gbps')
    --and dd.esh_id = '919990'
    
    group by 1
)

select count(case when district_received_0_bids = 1 then temp.esh_id end) as districts_0_bids,
  count(temp.esh_id) as total_districts,
  count(case when district_received_0_bids = 0 then temp.esh_id end) as districts_more_than_0_bids,
  count(case 
        when district_received_0_bids = 0
          and spek_c.esh_id is not null
          then temp.esh_id end) as spek_c_districts_more_than_0_bids,
  count(case 
        when district_received_0_bids = 1
          and spek_c.esh_id is null
          then temp.esh_id end) as not_spek_c_districts_0_bids,
  count(case when spek_c.esh_id is null then temp.esh_id end) as total_districts_no_spik_c_req,
  count(temp.esh_id) *
    count(case when district_received_0_bids = 0
                and spek_c.esh_id is null
                and d17.exclude_from_ia_analysis = false
                and d17.fiber_internet_upstream_lines_w_dirty + d17.fiber_wan_lines_w_dirty = 0 then temp.esh_id end) / 
          count(case when d17.exclude_from_ia_analysis = false then d17.esh_id end) as no_fiber
  
from temp 

join base_pop
on temp.esh_id = base_pop.esh_id

left join spek_c
on temp.esh_id = spek_c.esh_id

left join public.fy2017_districts_deluxe_matr d17
on temp.esh_id = d17.esh_id