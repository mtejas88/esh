#make

## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
CODE_DIR = $(PROJ_DIR)/src
FIG_DIR = $(PROJ_DIR)/figures

## define variables without any commands
.PHONY: data logic all

data: $(CODE_DIR)/out_files/query_data.Rout
logic: data $(CODE_DIR)/out_files/create_logic.Rout
## run entire project
all: data logic

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/out_files/create_logic.Rout: $(CODE_DIR)/create_logic.R
	@echo "creating logic"
	@R CMD BATCH --no-restore $(CODE_DIR)/create_logic.R $(CODE_DIR)/out_files/create_logic.Rout

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

