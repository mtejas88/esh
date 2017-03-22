#make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
CODE_DIR = $(PROJ_DIR)/src
FIGURES_DIR = $(PROJ_DIR)/figures

## list R files
RFILES := $(wildcard $(CODE_DIR)/*.R)


## define variables without any commands
.PHONY: data sample all

data: $(CODE_DIR)/out_files/query_data.Rout
sample: data $(CODE_DIR)/out_files/munge_data.Rout
explore: sample $(CODE_DIR)/out_files/exploratory.Rout
all: data sample explore

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/munge_data.Rout: $(CODE_DIR)/munge_data.R
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout

$(CODE_DIR)/out_files/exploratory.Rout: $(CODE_DIR)/exploratory.R
	@echo "exploring data"
	@R CMD BATCH --no-restore $(CODE_DIR)/exploratory.R $(CODE_DIR)/out_files/exploratory.Rout

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
	@rm -rf $(FIGURES_DIR)/*
	@touch $(FIGURES_DIR)/.gitkeep



