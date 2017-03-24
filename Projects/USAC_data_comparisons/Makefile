#!make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
CODE_DIR = $(PROJ_DIR)/src
FIGURES_DIR = $(PROJ_DIR)/figures
DOWNLOADS_DIR = $(PROJ_DIR)/downloads

## list R files
RFILES := $(wildcard $(CODE_DIR)/*.R)


## define variables without any commands
.PHONY: test data sample explore all

usac:$(CODE_DIR)/out_files/combining_current.txt
data: $(CODE_DIR)/out_files/query_data.Rout
sample: usac data $(CODE_DIR)/out_files/munge_data.Rout
explore: sample $(CODE_DIR)/out_files/exploratory.Rout
## run entire project
all: data sample

$(CODE_DIR)/out_files/combining_current.txt: $(CODE_DIR)/combining_current.py
	@echo "combining USAC files"
	@python $(CODE_DIR)/combining_current.py > $(CODE_DIR)/out_files/combining_current.txt

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/munge_data.Rout: $(CODE_DIR)/munge_data.R
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout

$(CODE_DIR)/out_files/exploratory.Rout: $(CODE_DIR)/exploratory.R
	@echo "exploring data"
	@R CMD BATCH --no-restore $(CODE_DIR)/out_files/exploratory.Rout


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

