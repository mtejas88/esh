#!/bin/bash

echo "$(date)"
cd "~/Documents/ESH_Code/ficher/Projects_SotS_2017/spmd_2017/"
echo "Generating Service Provider Metrics and Deploying Tool..."
echo "Querying Data"
R CMD BATCH src/query_data.R out_files/query_data.Rout
echo "Deploying Tool"
R CMD BATCH src/deploy_tool.R out_files/deploy_tool.Rout
echo "Done!"


