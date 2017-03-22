#make

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
.PHONY: data

data: $(CODE_DIR)/out_files/query_data.Rout
## run entire project
all: data

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

## clean up all generated files
clean:
	@echo "Cleaning up project files and data"	
	@rm -rf $(CODE_DIR)/out_files/*
	@touch $(CODE_DIR)/out_files/.gitkeep
	@rm -rf $(DATA_DIR)/*
	@touch $(DATA_DIR)/.gitkeep