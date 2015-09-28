### Load packages ###
require(ggplot2)
require(ggmap)

setwd("~/Desktop/R Projects/States Maps")

### Load districts data ###
districts <- read.csv("districts_sept_28.csv")

### Add variables to plot ###
districts$is_dirty <- ifelse(districts$num_open_dirty_flags > 0, "Data not clean", "Data clean")
districts$is_consortium <- ifelse(districts$consortium_member == "true", "Consortium", "Not Consortium")
table(districts$is_dirty)
table(districts$is_consortium)

### Make a vector of state abbreviations for subsetting ###
all_states <- unique(districts$postal_cd)
territories <- c("AS", "GU", "MP", "PR","VI", "UM", "DC")
states <- all_states[!all_states %in% territories]
length(states) # Should equal 50

### Colors and shapes ###
map_colors_binary <- c("darkgreen", "firebrick3")
map_colors_fiber <- c("darkgreen", "gray50", "black", "firebrick3", "gold")
map_shapes <- c(21, 4)

### Function to make maps and save to working directory ###
request_map <- function(state) {
  districts_state <- districts[which(districts$postal_cd == state), ]
  mapgilbert <- get_map(location = c(lon = mean(districts_state$longitude), lat = mean(districts_state$latitude)), zoom = 7,
                        source="stamen", maptype="toner-lite", scale = 1)
  map_name <- paste0("raw_", state,"_map", ".rda")
  save(mapgilbert, file=map_name)
}

### Function plot all maps. Needs map created from request map function ###
make_map <- function(state) {
  districts_state <- districts[which(districts$postal_cd == state), ]
  image_name <- paste0("image_",state,"_consortium_clean.png")
  load(paste0("raw_", state, "_map.rda"))
  ggmap(mapgilbert) +
    geom_point(data = districts_state, aes(x = longitude, y = latitude, fill=as.factor(percentage_fiber), 
                                           colour = as.factor(percentage_fiber), shape=as.factor(is_dirty)),size = 3)+
    scale_fill_manual("", values=c(map_colors_fiber))+
    scale_colour_manual("", values=c(map_colors_fiber))+
    scale_shape_manual("", values=c(map_shapes)) +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.line = element_line(colour = "black"), axis.text.x=element_blank(),
          axis.text.y=element_blank(),axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank())
  ggsave(image_name, width = 7.31, height = 8.07)
}

### Test on one state ###
setwd("~/Desktop/R Projects/States Maps/images")
make_map("CA")

### Request maps and save to WD ###
### This sends 50 requests to Google maps API, which can cause it to lock you out (error 503) ###
### May sometimes be necessary to run in batches of 5 or 10 at a time ###
sapply(states[1:5], function(x) request_map(x))

### Plot all maps. Need all maps in WD ###
sapply(states[1:5], function(x) make_map(x))

## Function for creating national saving to working directory ###
make_nat_map<- function() {
  districts_state <- districts
  mapgilbert <- get_map(location = c(lon = mean(districts_state$longitude)- 7, lat = mean(districts_state$latitude)), zoom = 4,
                        source="stamen", maptype="toner-lite", scale = 1)
  # create name to save image as
  image_name <- paste0("image_","US","_consortium_clean.png")
  ggmap(mapgilbert) +
    geom_point(data = districts_state, aes(x = longitude, y = latitude, fill=as.factor(is_dirty), 
                                           shape = as.factor(is_consortium), colour = as.factor(is_dirty)), size = 1)+    
    scale_fill_manual("", values=c(map_colors))+
    scale_colour_manual("", values=c(map_colors))+
    scale_shape_manual("", values=c(map_shapes))+
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
          panel.background = element_blank(), axis.line = element_line(colour = "black"), axis.text.x=element_blank(),
          axis.text.y=element_blank(),axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank())
  ggsave(image_name, width = 7.31, height = 8.07)
}

## Make national map ###
ggmap(mapgilbert)
