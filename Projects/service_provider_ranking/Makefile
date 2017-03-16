#!make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
CODE_DIR = $(PROJ_DIR)/src

## list R files
RFILES := $(wildcard $(CODE_DIR)/*.R)


## define variables without any commands
.PHONY: data sample all

data: $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout $(DATA_DIR)/raw/deluxe_districts_2016.csv $(DATA_DIR)/raw/districts_sp_assignments_2016.csv
sample: $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout $(DATA_DIR)/interim/service_provider_aggregated_clean_districts.csv
## run entire project
all: data sample

$(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout $(DATA_DIR)/raw/deluxe_districts_2016.csv $(DATA_DIR)/raw/districts_sp_assignments_2016.csv:
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout $(DATA_DIR)/interim/service_provider_aggregated_clean_districts.csv:
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout


## clean up all generated files
clean:
	@echo "Cleaning up project files and data"	
	@rm -rf $(CODE_DIR)/out_files/*
	@rm -rf $(DATA_DIR)/raw/*
	@rm -rf $(DATA_DIR)/interim/*

