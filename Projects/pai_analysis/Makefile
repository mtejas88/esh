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
.PHONY: data models service_providers all

data: $(CODE_DIR)/out_files/query_data.Rout
models: data $(CODE_DIR)/out_files/model_summaries_by_locale.Rout
service_providers: data models $(CODE_DIR)/out_files/model_summaries_by_sp.Rout
## run entire project
all: data models service_providers

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/model_summaries_by_locale.Rout: $(CODE_DIR)/creating_districts_display.R $(CODE_DIR)/creating_models.R $(CODE_DIR)/model_summaries_by_locale.R
	@echo "creating districts display"
	@R CMD BATCH --no-restore $(CODE_DIR)/creating_districts_display.R $(CODE_DIR)/out_files/creating_districts_display.Rout
	@echo "creating models"
	@R CMD BATCH --no-restore $(CODE_DIR)/creating_models.R $(CODE_DIR)/out_files/creating_models.Rout
	@echo "creating model summaries by locale"
	@R CMD BATCH --no-restore $(CODE_DIR)/model_summaries_by_locale.R $(CODE_DIR)/out_files/model_summaries_by_locale.Rout

$(CODE_DIR)/out_files/model_summaries_by_sp.Rout: $(CODE_DIR)/model_summaries_by_sp.R
	@echo "creating model summaries by SP"
	@R CMD BATCH --no-restore $(CODE_DIR)/model_summaries_by_sp.R $(CODE_DIR)/out_files/model_summaries_by_sp.Rout


## clean up all generated files
clean:
	@echo "Cleaning up project files and data"	
	@rm -rf $(CODE_DIR)/out_files/*
	@touch $(CODE_DIR)/out_files/.gitkeep
	@touch $(DATA_DIR)/.gitkeep
	@rm -rf $(DATA_DIR)/raw/*
	@touch $(DATA_DIR)/raw/.gitkeep
	@rm -rf $(DATA_DIR)/interim/*
	@touch $(DATA_DIR)/interim/.gitkeep
	@rm -rf $(DATA_DIR)/processed/*
	@touch $(DATA_DIR)/processed/.gitkeep

