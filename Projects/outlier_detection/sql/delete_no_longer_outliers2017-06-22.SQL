delete from outliers 
    where ref_id not in(
    (select ref_id, case when use_case_name ='Cost per Circuit' then 'LineItem' else 'District' end as type
    from outliers out join outlier_use_case_details oucd on out.outlier_use_case_detail_id=oucd.outlier_use_case_detail_id) a
    join
    (select ref_id, case when use_case_name ='Cost per Circuit' then 'LineItem' else 'District' end as type
    from temp_outlier_candidates) b on a.ref_id=b.ref_id and a.type=b.type
    );
    
