#!make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
FIG_DIR = $(PROJ_DIR)/figures
CODE_DIR = $(PROJ_DIR)/src

## list R files
RFILES := $(wildcard $(CODE_DIR)/*.R)


## define variables without any commands
.PHONY: data sample cluster figures all

data: $(CODE_DIR)/out_files/query_data.Rout
sample: data $(CODE_DIR)/out_files/munge_data.Rout
cluster: sample $(CODE_DIR)/out_files/cluster_data.Rout
figures: cluster $(CODE_DIR)/out_files/figures.Rout
## run entire project
all: data sample cluster figures

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/munge_data.Rout: $(CODE_DIR)/munge_data.R
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout

$(CODE_DIR)/out_files/cluster_data.Rout: $(CODE_DIR)/cluster_data.R
	@echo "clustering data"
	@R CMD BATCH --no-restore $(CODE_DIR)/cluster_data.R $(CODE_DIR)/out_files/cluster_data.Rout

$(CODE_DIR)/out_files/figures.Rout: $(CODE_DIR)/figures.R
	@echo "creating figures"
	@R CMD BATCH --no-restore $(CODE_DIR)/figures.R $(CODE_DIR)/out_files/figures.Rout


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
	@rm -rf $(FIG_DIR)/*
	@touch $(FIG_DIR)/.gitkeep

