#WIP DOES NOT WORK!!

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


## define variables without any commands -- list of commands that are phony
.PHONY: data sample cluster figures all

## phony variables -- arrays of files (scipts, csvs, etc) -- which will be used in actual commands below
# this is important because if the outputs are already there then it won't run
data: $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout $(DATA_DIR)/raw/deluxe_districts_2016.csv $(DATA_DIR)/raw/form_470.csv $(DATA_DIR)/raw/bens.csv
sample: $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout $(DATA_DIR)/interim/all_districts.csv $(DATA_DIR)/interim/mega_large_districts.csv $(FIG_DIR)/visualize_raw.pdf
cluster: $(CODE_DIR)/cluster_data.R $(CODE_DIR)/out_files/cluster_data.Rout $(DATA_DIR)/interim/clustered_all_districts.csv $(DATA_DIR)/processed/final_clustered_districts.csv $(DATA_DIR)/processed/aggregated_means_clusters_all_districts.csv $(DATA_DIR)/processed/aggregated_means_clusters_mega_and_large_districts.csv
figures:$(CODE_DIR)/figures.R $(CODE_DIR)/out_files/figures.Rout $(FIG_DIR)/visualize_clusters.pdf $(FIG_DIR)/visualize_clusters_mega_large.pdf $(FIG_DIR)/distribution_of_cluster_id.pdf $(FIG_DIR)/distribution_of_cluster_id_mega_large.pdf
## run entire project
all: data sample cluster figures

## actual commands -- connect using the same list as in the phony variable. the commands must be tabbed.
$(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout $(DATA_DIR)/raw/deluxe_districts_2016.csv $(DATA_DIR)/raw/form_470.csv $(DATA_DIR)/raw/bens.csv:
	@echo "querying data"
	@R CMD BATCH --no-restore '--args $(GITHUB)' $(CODE_DIR)/query_data.R $(CODE_DIR)/out_files/query_data.Rout

$(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout $(DATA_DIR)/interim/all_districts.csv $(DATA_DIR)/interim/mega_large_districts.csv $(FIG_DIR)/visualize_raw.pdf:
	@echo "munging data"
	@R CMD BATCH --no-restore $(CODE_DIR)/munge_data.R $(CODE_DIR)/out_files/munge_data.Rout

$(CODE_DIR)/cluster_data.R $(CODE_DIR)/out_files/cluster_data.Rout $(DATA_DIR)/interim/clustered_all_districts.csv $(DATA_DIR)/processed/final_clustered_districts.csv $(DATA_DIR)/processed/aggregated_means_clusters_all_districts.csv $(DATA_DIR)/processed/aggregated_means_clusters_mega_and_large_districts.csv:
	@echo "clustering data"
	@R CMD BATCH --no-restore $(CODE_DIR)/cluster_data.R $(CODE_DIR)/out_files/cluster_data.Rout

$(CODE_DIR)/figures.R $(CODE_DIR)/out_files/figures.Rout $(FIG_DIR)/visualize_clusters.pdf $(FIG_DIR)/visualize_clusters_mega_large.pdf $(FIG_DIR)/distribution_of_cluster_id.pdf $(FIG_DIR)/distribution_of_cluster_id_mega_large.pdf:
	@echo "creating figures"
	@R CMD BATCH --no-restore $(CODE_DIR)/figures.R $(CODE_DIR)/out_files/figures.Rout


## clean up all generated files -- this is common if you want to remove all interim data files for example
clean:
	@echo "Cleaning up project files and data"
	@rm -rf $(CODE_DIR)/out_files/*
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
