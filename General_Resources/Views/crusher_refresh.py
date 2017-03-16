#!/usr/bin/python

#BLUE credentials
hostname = 'ec2-34-192-206-210.compute-1.amazonaws.com'
username = 'ud1bnbevrqe2q'
password = 'p412da0cf141f10788be82e8a3d0dc8e24698205ec718e9db75cd86aabd6b67c4'
database = 'dai3g95tesvtj9'

# Simple routine to run a query on a database and print the results:
def doQuery( conn ) :
    cur = conn.cursor()
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_demog_matr;" )
    print("fy2016_districts_demog_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_schools_demog_matr;" )
    print("fy2016_schools_demog_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_district_lookup_matr;" )
    print("fy2016_district_lookup_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_lines_to_district_by_line_item_matr;" )
    print("fy2016_lines_to_district_by_line_item_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_aggregation_matr;" )
    print("fy2016_districts_aggregation_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_metrics_matr;" )
    print("fy2016_districts_metrics_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_wifi_connectivity_informations_matr;" )
    print("fy2016_wifi_connectivity_informations_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_c2_funding_matr;" )
    print("fy2016_districts_c2_funding_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_predeluxe_matr;" )
    print("fy2016_districts_predeluxe_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_services_received_matr;" )
    print("fy2016_services_received_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_service_provider_assignments_matr;" )
    print("fy2016_districts_service_provider_assignments_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW district_lookup_2015_m;" )
    print("district_lookup_2015_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW lines_to_district_by_line_item_2015_m;" )
    print("lines_to_district_by_line_item_2015_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_districts_aggregation_fy2016_methods_m;" )
    print("fy2015_districts_aggregation_fy2016_methods_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_districts_metrics_fy2016_methods_m;" )
    print("fy2015_districts_metrics_fy2016_methods_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_services_received_m;" )
    print("fy2015_services_received_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW district_lookup_nifs_2015_m;" )
    print("district_lookup_nifs_2015_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW line_item_district_association_2015_m;" )
    print("line_item_district_association_2015_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_districts_deluxe_m;" )
    print("fy2015_districts_deluxe_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_fy2016_districts_upgrades_m;" )
    print("fy2015_fy2016_districts_upgrades_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_campus_w_fiber_nonfiber_matr;" )
    print("fy2016_campus_w_fiber_nonfiber_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_stage_indicator_matr;" )
    print("fy2016_stage_indicator_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_bw_indicator_matr;" )
    print("fy2016_bw_indicator_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_fiber_bw_target_status_matr;" )
    print("fy2016_fiber_bw_target_status_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_districts_deluxe_matr;" )
    print("fy2016_districts_deluxe_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_campuses_for_ftg_matr;" )
    print("fy2016_campuses_for_ftg_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_lines_to_school_by_line_item_matr;" )
    print("fy2016_lines_to_school_by_line_item_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_schools_aggregation_matr;" )
    print("fy2016_schools_aggregation_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2016_schools_metrics_matr;" )
    print("fy2016_schools_metrics_matr refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_lines_to_school_by_line_item_m;" )
    print("fy2015_lines_to_school_by_line_item_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_schools_aggregation_m;" )
    print("fy2015_schools_aggregation_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_schools_metrics_m;" )
    print("fy2015_schools_metrics_m refreshed")
    cur.execute( "REFRESH MATERIALIZED VIEW fy2015_schools_deluxe_m;" )
    print("fy2015_schools_deluxe_m refreshed")


print("Begin refresh...")
import psycopg2
myConnection = psycopg2.connect(
    host=hostname,
    user=username,
    password=password,
    dbname=database
)
doQuery( myConnection )
print("Refresh complete")
myConnection.close()