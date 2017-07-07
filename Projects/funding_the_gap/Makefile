## source the environment variables
include ~/.env
export

## set the other directories in relation to the main project directory
PROJ_DIR = .
DATA_DIR = $(PROJ_DIR)/data
FIG_DIR = $(PROJ_DIR)/figures
CODE_DIR = $(PROJ_DIR)/src/models

## define variables without any commands -- list of commands that are phony
.PHONY: distance_calculator unscalable_campuses unscalable_districts build_cost_calculator_apop build_cost_calculator_az build_cost_calculator_zpop build_cost_calculator_ia build_cost_per_mile_wan build_cost_distributor_wan build_cost_distributor_ia aggregator_state aggregator_state_tableau all

## phony variables -- arrays of files (scipts, csvs, etc) -- which will be used in actual commands below
# this is important because if the outputs are already there then it won't run
## EDIT: these commands should rely only on the output they create, also should add the steps before that they rely on
distance_calculator: $(DATA_DIR)/interim/campuses_distances.csv
unscalable_campuses: distance_calculator $(DATA_DIR)/interim/unscalable_campuses.csv
unscalable_districts: unscalable_campuses $(DATA_DIR)/interim/districts.csv $(DATA_DIR)/interim/unscalable_districts.csv
build_cost_calculator_apop: unscalable_districts $(DATA_DIR)/interim/campus_costs_apop.csv
build_cost_calculator_az: build_cost_calculator_apop $(DATA_DIR)/interim/campus_costs_az.csv
build_cost_calculator_zpop: build_cost_calculator_az $(DATA_DIR)/interim/campus_costs_zpop.csv
build_cost_calculator_ia: build_cost_calculator_zpop $(DATA_DIR)/interim/district_costs.csv
build_cost_per_mile_wan: build_cost_calculator_ia $(DATA_DIR)/interim/state_cost_per_mile.csv
build_cost_distributor_wan: build_cost_per_mile_wan $(DATA_DIR)/interim/campus_build_costs.csv
build_cost_distributor_ia: build_cost_distributor_wan $(DATA_DIR)/interim/district_build_costs.csv
aggregator_state: build_cost_distributor_ia $(DATA_DIR)/processed/state_metrics.csv
aggregator_state_tableau: aggregator_state_tableau $(DATA_DIR)/processed/state_metrics_tableau.csv
## run entire project
all: distance_calculator unscalable_campuses unscalable_districts build_cost_calculator_apop build_cost_calculator_az build_cost_calculator_zpop build_cost_calculator_ia build_cost_per_mile_wan build_cost_distributor_wan build_cost_distributor_ia aggregator_state aggregator_state_tableau

## actual commands -- connect using the same list as in the phony variable. the commands must be tabbed.
## EDIT: "R CMD BATCH" is the command to run .R scripts in batch mode, so you should just use "python [python file]"
## ALSO, the order is out_file (or what is created) : code that creates it. so reversing the .csv and .py files.
$(DATA_DIR)/interim/campuses_distances.csv: $(CODE_DIR)/distance_calculator.py
	@echo "calculating distances"
	@python $(CODE_DIR)/distance_calculator.py

$(DATA_DIR)/interim/unscalable_campuses.csv: $(CODE_DIR)/unscalable_campuses.py
	@echo "determining unscalable campuses"
	@python $(CODE_DIR)/unscalable_campuses.py

$(DATA_DIR)/interim/districts.csv $(DATA_DIR)/interim/unscalable_districts.csv: $(CODE_DIR)/unscalable_districts.py
	@echo "determining unscalable districts"
	@python $(CODE_DIR)/unscalable_districts.py

$(DATA_DIR)/interim/campus_costs_apop.csv: $(CODE_DIR)/build_cost_calculator_apop.py
	@echo "calculating a-pop costs"
	@python $(CODE_DIR)/build_cost_calculator_apop.py

$(DATA_DIR)/interim/campus_costs_az.csv: $(CODE_DIR)/build_cost_calculator_az.py
	@echo "calculating a-z costs"
	@python $(CODE_DIR)/build_cost_calculator_az.py

$(DATA_DIR)/interim/campus_costs_zpop.csv: $(CODE_DIR)/build_cost_calculator_zpop.py
	@echo "calculating z-pop costs"
	@python $(CODE_DIR)/build_cost_calculator_zpop.py

$(DATA_DIR)/interim/district_build_costs.csv: $(CODE_DIR)/build_cost_calculator_ia.py
	@echo "calculating ia costs"
	@python $(CODE_DIR)/build_cost_calculator_ia.py

$(DATA_DIR)/interim/state_cost_per_mile.csv: $(CODE_DIR)/build_cost_per_mile_wan.py
	@echo "calculating state average cost per mile"
	@python $(CODE_DIR)/build_cost_per_mile_wan.py

$(DATA_DIR)/interim/campus_build_costs.csv: $(CODE_DIR)/build_cost_distributor_wan.py
	@echo "distributing WAN build costs by funding source"
	@python $(CODE_DIR)/build_cost_distributor_wan.py

$(DATA_DIR)/interim/district_build_costs.csv: $(CODE_DIR)/build_cost_distributor_ia.py
	@echo "distributing IA build costs by funding source"
	@python $(CODE_DIR)/build_cost_distributor_ia.py

$(DATA_DIR)/processed/state_metrics.csv: $(CODE_DIR)/aggregator_state.py
	@echo "aggregating costs by state"
	@python $(CODE_DIR)/aggregator_state.py

$(DATA_DIR)/processed/state_metrics_tableau.csv: $(CODE_DIR)/aggregator_state_tableau.py
	@echo "formatting tableau export"
	@python $(CODE_DIR)/aggregator_state_tableau.py


## clean up all generated files -- this is common if you want to remove all interim data files for example
## EDIT: added a command to touch the .gitkeep file when everything in the directories are deleted.
clean:
	@echo "Cleaning up project files and data"
	@touch $(DATA_DIR)/.gitkeep
	@rm -rf $(DATA_DIR)/raw/*
	@touch $(DATA_DIR)/raw/.gitkeep
	@rm -rf $(DATA_DIR)/interim/*
	@touch $(DATA_DIR)/interim/.gitkeep
	@rm -rf $(DATA_DIR)/processed/*
	@touch $(DATA_DIR)/processed/.gitkeep
	@rm -rf $(FIG_DIR)/*
	@touch $(FIG_DIR)/.gitkeep



# what to type in terminal:
# 	make [command_name]
# how to define command:
#	[command_name]:
#		[command 1 that you want to be done in terminal language and you want it printed]
#		@[command 2 that you want to be done in terminal language but you don't want printed]
# how to define variable:
# 	[current_directory_name] = .
# 	[new_directory_name] = $([current_directory_name])/[subfolder]
