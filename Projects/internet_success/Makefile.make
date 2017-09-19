#make

## source the environment variables
include ~/.env 
export

## set the other directories in relation to the main project directory 
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
EXT_DATA_DIR = $(DATA_DIR)/external
CODE_DIR = $(PROJ_DIR)/src 

## define variables without any commands
####come back to this


$(EXT_DATA_DIR)/acgr-release2-lea-sy2014-15.csv:
	@curl -o $(EXT_DATA_DIR)/acgr-release2-lea-sy2014-15.csv "https://www2.ed.gov/about/inits/ed/edfacts/data-files/acgr-release2-lea-sy2014-15.csv"

$(EXT_DATA_DIR)/acgr-lea-sy2013-14.csv:
	@curl - o $(EXT_DATA_DIR)/acgr-lea-sy2013-14.csv "https://www2.ed.gov/about/inits/ed/edfacts/data-files/acgr-lea-sy2013-14.csv"

$(EXT_DATA_DIR)/acgr-lea-sy2012-13.csv:
	@curl - o $(EXT_DATA_DIR)/acgr-lea-sy2012-13.csv "https://www2.ed.gov/about/inits/ed/edfacts/data-files/acgr-lea-sy2012-13.csv"

$(CODE_DIR)/out_files/query_data.Rout: $(CODE_DIR)/query_data.R 
	@echo "query_data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/outfiles/query_data.Rout 

	