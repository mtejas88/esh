#!make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
FIG_DIR = $(PROJ_DIR)/figures
CODE_DIR = $(PROJ_DIR)/src

## define variables without any commands
.PHONY: external_data data sample distances campuses checks all

external_data: $(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv
data: external_data $(CODE_DIR)/out_files/query_data.Rout
sample: data $(CODE_DIR)/out_files/munge_data.Rout
distances: sample $(CODE_DIR)/out_files/calculate_school_distances.Rout
campuses: distances $(CODE_DIR)/out_files/create_campuses.Rout
checks: campuses $(CODE_DIR)/out_files/checks_and_final_formatting.Rout
## run entire project
all: external_data data sample distances campuses checks

$(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL_csv.zip:
	@curl -o $(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL_csv.zip "https://nces.ed.gov/ccd/Data/zip/EDGE_GEOIDS_201415_PUBLIC_SCHOOL_csv.zip"

$(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv: $(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL_csv.zip
	@unzip $(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL_csv.zip -d temp_for_extract
	@scp -r temp_for_extract/* $(DATA_DIR)/external/.
	@rm -rf temp_for_extract
	@touch $(DATA_DIR)/external/EDGE_GEOIDS_201415_PUBLIC_SCHOOL.csv

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/munge_data.Rout: $(CODE_DIR)/munge_data.R
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout

$(CODE_DIR)/out_files/calculate_school_distances.Rout: $(CODE_DIR)/calculate_school_distances.R
	@echo "calculating school distances (will take ~20-25 min to run)"
	@R CMD BATCH --no-restore $(CODE_DIR)/calculate_school_distances.R $(CODE_DIR)/out_files/calculate_school_distances.Rout

$(CODE_DIR)/out_files/create_campuses.Rout: $(CODE_DIR)/create_campuses.R
	@echo "creating campuses (will take ~10 min to run)"
	@R CMD BATCH --no-restore $(CODE_DIR)/create_campuses.R $(CODE_DIR)/out_files/create_campuses.Rout

$(CODE_DIR)/out_files/checks_and_final_formatting.Rout: $(CODE_DIR)/checks_and_final_formatting.R
	@echo "checking campuses"
	@R CMD BATCH --no-restore $(CODE_DIR)/checks_and_final_formatting.R $(CODE_DIR)/out_files/checks_and_final_formatting.Rout
clean:
	@echo "Cleaning up project files and data"	
	@rm -rf $(CODE_DIR)/out_files/*
	@touch $(CODE_DIR)/out_files/.gitkeep
	@touch $(DATA_DIR)/.gitkeep
	@rm -rf $(DATA_DIR)/external/*
	@touch $(DATA_DIR)/external/.gitkeep
	@rm -rf $(DATA_DIR)/raw/*
	@touch $(DATA_DIR)/raw/.gitkeep
	@rm -rf $(DATA_DIR)/interim/*
	@touch $(DATA_DIR)/interim/.gitkeep
	@rm -rf $(DATA_DIR)/processed/*
	@touch $(DATA_DIR)/processed/.gitkeep

