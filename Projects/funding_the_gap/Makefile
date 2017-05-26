## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
FIG_DIR = $(PROJ_DIR)/figures
CODE_DIR = $(PROJ_DIR)/src/models

## define variables without any commands -- list of commands that are phony
.PHONY: distance_calculator unscalable_campuses unscalable_districts build_cost_calculator_apop build_cost_calculator_az build_cost_calculator_zpop build_cost_calculator_ia build_cost_per_mile_wan build_cost_distributor_wan build_cost_distributor_ia aggregator_state aggregator_state_tableau

## phony variables -- arrays of files (scipts, csvs, etc) -- which will be used in actual commands below
# this is important because if the outputs are already there then it won't run
distance_calculator: $(CODE_DIR)/distance_calculator.py $(DATA_DIR)/interim/campuses_distances.csv
unscalable_campuses: $(CODE_DIR)/unscalable_campuses.py $(DATA_DIR)/interim/unscalable_campuses.csv
unscalable_districts: $(CODE_DIR)/unscalable_districts.py $(DATA_DIR)/interim/districts.csv $(DATA_DIR)/interim/unscalable_districts.csv
build_cost_calculator_apop: $(CODE_DIR)/build_cost_calculator_apop.py $(DATA_DIR)/interim/campus_costs_apop.csv
build_cost_calculator_az: $(CODE_DIR)/build_cost_calculator_az.py $(DATA_DIR)/interim/campus_costs_az.csv
build_cost_calculator_zpop: $(CODE_DIR)/build_cost_calculator_zpop.py $(DATA_DIR)/interim/campus_costs_zpop.csv
build_cost_calculator_ia: $(CODE_DIR)/build_cost_calculator_ia.py $(DATA_DIR)/interim/district_costs.csv
build_cost_per_mile_wan: $(CODE_DIR)/build_cost_per_mile_wan.py $(DATA_DIR)/interim/state_cost_per_mile.csv
build_cost_distributor_wan: $(CODE_DIR)/build_cost_distributor_wan.py $(DATA_DIR)/interim/campus_build_costs.csv
build_cost_distributor_ia: $(CODE_DIR)/build_cost_distributor_ia.py $(DATA_DIR)/interim/district_build_costs.csv
aggregator_state: $(CODE_DIR)/aggregator_state.py $(DATA_DIR)/processed/state_metrics.csv
aggregator_state_tableau: $(CODE_DIR)/aggregator_state_tableau.py $(DATA_DIR)/processed/state_metrics_tableau.csv

## run entire project
all: distance_calculator unscalable_campuses unscalable_districts build_cost_calculator_apop build_cost_calculator_az build_cost_calculator_zpop build_cost_calculator_ia build_cost_per_mile_wan build_cost_distributor_wan build_cost_distributor_ia aggregator_state aggregator_state_tableau

## actual commands -- connect using the same list as in the phony variable. the commands must be tabbed.
$(CODE_DIR)/distance_calculator.py $(DATA_DIR)/interim/campuses_distances.csv:
	@echo "calculating distances"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/distance_calculator.py

$(CODE_DIR)/unscalable_campuses.py $(DATA_DIR)/interim/unscalable_campuses.csv:
	@echo "determining unscalable campuses"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/unscalable_campuses.py

$(CODE_DIR)/unscalable_districts.py $(DATA_DIR)/interim/districts.csv $(DATA_DIR)/interim/unscalable_districts.csv:
	@echo "determining unscalable districts"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/unscalable_districts.py

$(CODE_DIR)/build_cost_calculator_apop.py $(DATA_DIR)/interim/campus_costs_apop.csv:
	@echo "calculating a-pop costs"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_calculator_apop.py

$(CODE_DIR)/build_cost_calculator_az.py $(DATA_DIR)/interim/campus_costs_az.csv:
	@echo "calculating a-z costs"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_calculator_az.py

$(CODE_DIR)/build_cost_calculator_zpop.py $(DATA_DIR)/interim/campus_costs_zpop.csv:
	@echo "calculating z-pop costs"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_calculator_zpop.py

$(CODE_DIR)/build_cost_calculator_ia.py $(DATA_DIR)/interim/district_build_costs.csv:
	@echo "calculating ia costs"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_calculator_ia.py

$(CODE_DIR)/build_cost_per_mile_wan.py $(DATA_DIR)/interim/state_cost_per_mile.csv:
	@echo "calculating state average cost per mile"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_per_mile_wan.py

$(CODE_DIR)/build_cost_distributor_wan.py $(DATA_DIR)/interim/campus_build_costs.csv:
	@echo "distributing WAN build costs by funding source"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_distributor_wan.py

$(CODE_DIR)/build_cost_distributor_ia.py $(DATA_DIR)/interim/district_build_costs.csv:
	@echo "distributing IA build costs by funding source"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/build_cost_distributor_ia.py

$(CODE_DIR)/aggregator_state.py $(DATA_DIR)/processed/state_metrics.csv:
	@echo "aggregating costs by state"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/aggregator_state.py

$(CODE_DIR)/aggregator_state_tableau.py $(DATA_DIR)/processed/state_metrics_tableau.csv:
	@echo "formatting tableau export"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/aggregator_state_tableau.py


## clean up all generated files -- this is common if you want to remove all interim data files for example
clean:
	@echo "Cleaning up project files and data"
	@rm -rf $(DATA_DIR)/raw/*
	@rm -rf $(DATA_DIR)/interim/*
	@rm -rf $(DATA_DIR)/processed/*
	@rm -rf $(FIG_DIR)/*



# what to type in terminal:
# 	make [command_name]
# how to define command:
#	[command_name]:
#		[command 1 that you want to be done in terminal language and you want it printed]
#		@[command 2 that you want to be done in terminal language but you don't want printed]
# how to define variable:
# 	[current_directory_name] = .
# 	[new_directory_name] = $([current_directory_name])/[subfolder]
