### PRELIMINARY AND UNCHECKED ###

# Clear the console
cat("\014")


# Remove every object in the environment
rm(list = ls())

#install and load packages
lib <- c("dplyr", "ggplot2", "RColorBrewer", "raster", "maps", "mapproj", "gridExtra", "reshape2", "scales")
#sapply(lib, function(x) install.packages(x))
sapply(lib, function(x) require(x, character.only = TRUE))

# set working directory
setwd("~/Google Drive/R/Illinois CR/data/export/for_graphing")

###

# load csv files
 # try to avoid using basic table if possible
basic <- read.csv("~/Google Drive/R/Illinois CR/data/mode/basic_districts_20160105.csv", as.is = TRUE)
deluxe <- read.csv("~/Google Drive/R/Illinois CR/data/mode/deluxe_districts_20160105.csv", as.is = TRUE)
rep <- read.csv("~/Google Drive/R/Illinois CR/data/intermediate/rep_sample_20160105.csv", as.is = TRUE)
counties <- read.csv("~/Google Drive/R/Illinois CR/data/mode/il_county_names.csv", as.is = TRUE)
services <- read.csv("~/Google Drive/R/Illinois CR/data/mode/services_received_20160105.csv", as.is = TRUE)

# districts leveraging e-rate
basic$erate <- ifelse(basic$esh_id %in% services$district_esh_id, 1, 0)

# Create additional columns needed for analyses!
# order the locale/district_size factor in a logical way
deluxe$locale <- factor(deluxe$locale, levels = c("Urban", "Suburban", "Small Town", "Rural"))
deluxe$district_size <- factor(deluxe$district_size, levels = c("Tiny", "Small", "Medium", "Large", "Mega"))

# rep: column which indicates rep sample status
 # this will make iteration easier!
deluxe$rep_sample <- ifelse(deluxe$nces_cd %in% rep$nces_cd, 1, 0)
#sum(deluxe$rep_sample)

# adj_ia_bandwidth_per_student: internet bandwidth per student adjusted by concurrency factor
deluxe$adj_ia_bandwidth_per_student <- deluxe$ia_bandwidth_per_student * deluxe$ia_oversub_ratio

# icn: column which shows which district has coverage through ICN
 # ICN + two local affiliates
to_match <- c("Illinois Century Network", "Illimois Central College", "Northern Illinois University")
matches <- unique(grep(paste(to_match, collapse="|"), deluxe$internet_sp, value=TRUE))
deluxe$icn <- ifelse(deluxe$internet_sp %in% matches, 1, 0)

# il_region: column which indicates whether district is Chicago, Chicago Suburbs, or Other
 # City of Chicago nces_cd: 1709930
 # Chicago Suburbs = Rest of Cook NOT Chicago + Collar Counties(DuPage, Kane, Lake, McHenry, and Will)
 # Other: the rest

 # merge county name data to deluxe table
deluxe <- merge(deluxe, counties, all.x = TRUE, all.y = FALSE, by = c("nces_cd"))
basic <- merge(basic, counties, all.x = TRUE, all.y = FALSE, by = c("nces_cd"))

 # simplify county names
deluxe$county <- tolower(gsub(" .*$", "", deluxe$CONAME))
deluxe$CONAME <- NULL

basic$county <- tolower(gsub(" .*$", "", basic$CONAME))
basic$CONAME <- NULL


# City of Chicago nces_cd: 1709930
# Chicago Suburban = Rest of Cook NOT Chicago + Collar Counties(DuPage, Kane, Lake, McHenry, and Will)
# The rest: Not either
deluxe$il_region <- ifelse(deluxe$nces_cd == "1709930", "Chicago", ifelse(deluxe$county %in% c("cook", "dupage", "kane", "lake", "mchenry", "will"), "Chicago Suburbs", "The Rest"))
deluxe$il_region <- factor(deluxe$il_region, levels = c("Chicago", "Chicago Suburbs", "The Rest"))

basic$il_region <- ifelse(basic$nces_cd == "1709930", "Chicago", ifelse(basic$county %in% c("cook", "dupage", "kane", "lake", "mchenry", "will"), "Chicago Suburbs", "The Rest"))
basic$il_region <- factor(basic$il_region, levels = c("Chicago", "Chicago Suburbs", "The Rest"))


# add them in for basic table as well

# goals
 # goal_2014: 1 if the district is meeting 2014 goal (100 kbps per student) or 0 otherwise; no contingency factor
 # goal_2018: 1 if the district is meeting 2018 goal (1000 kbps per student) or 0 otherwise; use contingency factor

deluxe$goal_2014 <- ifelse(deluxe$ia_bandwidth_per_student >= 100, 1, 0)
deluxe$goal_2018 <- ifelse(deluxe$adj_ia_bandwidth_per_student >= 1000, 1, 0)

 # checked that these columns are respectively identical to meeting_2014_goal_no_oversub and meeting_2018_goal_oversub

 # for mapping -- import Illinois map by county
usa <- getData('GADM', country="USA", level=2)
il_map <- usa[usa$NAME_1 == "Illinois",] 
il_map@data$id <- rownames(il_map@data)
il_df <- merge(il_map@data, fortify(il_map), by = "id", all.y = TRUE)
il_df <- il_df[,c("NAME_2", "long", "lat", "group")]
names(il_df) <- c("county", "long", "lat", "group")
il_df$county <- tolower(il_df$county)

 # wan
deluxe$has_wan <- ifelse(deluxe$gt_1g_wan_lines + deluxe$lt_1g_fiber_wan_lines +deluxe$lt_1g_nonfiber_wan_lines > 0, 1, 0)

# scalability
 # has_fiber: 1 if the district has fiber, 0 otherwise
deluxe$has_fiber <- ifelse(grepl("Fiber", deluxe$all_ia_connectcat), 1, 0)

 # requires_wan -- shows which district requires WAN?
  # districts that have at least 3 campuses 
  # districts that do not have enough internet lines to cover the number of campuses
 
deluxe$requires_wan <- ifelse (deluxe$num_campuses >= 3 & 
                                 ((deluxe$fiber_internet_upstream_lines + deluxe$fixed_wireless_internet_upstream_lines +
                                    deluxe$cable_dsl_internet_upstream_lines + deluxe$copper_internet_upstream_lines)
                               < deluxe$num_campuses), 1, 0)
# who needs WAN?
 # ASSUMPTION 1: districts that have at least 3 num_campuses
 # [51] "fiber_internet_upstream_lines"            "fixed_wireless_internet_upstream_lines"  
 #[53] "cable_dsl_internet_upstream_lines"        "copper_internet_upstream_lines"          
 # sum (campuses)      ( if lines >= num campuses -- they have enough access)
 # ASSUMPTION 2: take out the districts above for direct IA 


 # requested_dark_fiber: 1 if the district has dark fiber, 0 otherwise
deluxe$requested_dark_fiber <- ifelse(grepl("Dark Fiber", deluxe$all_ia_connecttype), 1, 0)

 # some districts to highlight?

 # slightly broader definition
 # scalable: 1 if all_ia_connectcat is Fiber, Fixed Wireless, or Cable for < 100 students, 0 otherwise
scale <- c("Fiber", "Fixed Wireless")
cable <- c("Cable Modem")
scale_match <- unique(grep(paste(scale, collapse="|"), deluxe$all_ia_connectcat, value=TRUE))
cable_match <- unique(grep(paste(cable, collapse="|"), deluxe$all_ia_connecttype, value=TRUE))

deluxe$scalable <- ifelse(deluxe$all_ia_connectcat %in% scale_match |
                       (deluxe$all_ia_connectcat %in% scale_match & deluxe$num_students < 100), 1, 0)
rm(scale, cable, scale_match, cable_match)

# no fiber district
deluxe$no_fiber <- ifelse(deluxe$hierarchy_connect_category != "Fiber", 1, 0)

# limit to rep sample
rep_sample <- filter(deluxe, rep_sample == 1)



### analyses

 # summary table
 # which type districts are meeting goals? 
get_summary <- function(df) { 
  df %>%
    group_by(district_size) %>%
    summarise(n = n(),
              mean_frl = mean(frl_percent),
              mean_fiber = mean(has_fiber),
              mean_icn = mean(icn),
              mean_yearly_cost_per_mbps = mean(ia_cost_per_mbps),
              mean_ia = mean(ia_bandwidth_per_student),
              mean_adj_ia = mean(adj_ia_bandwidth_per_student),
              mean_goal_2014 = mean(goal_2014),
              mean_goal_2018 = mean(goal_2018))
}

 # summary stats for all clean data
#clean_summary <- get_summary(deluxe)
 # summary stats for the 95% rep. sample
rep_summary <- get_summary(rep_sample)

#insights and questions from rep summary
 # what is the urban, tiny district?
 # Urban - Mega: likely Chicago, they seem to be paying way more than other urban districts
 # Small towns: tiny - small bucks the trend of economics of scale in cost

# Urban/Tiny?
#urban_tiny <- filter(deluxe, locale == "Urban" & district_size == "Tiny")
#urban_tiny[, c("name", "nces_cd")]
# this is the Fairview District in Skokie, IL
# NCES confirms that this is a district classified as city, with 1 elemetary school of about 660 students
# WEIRD
# represent the rep. sample by district_size + locale
sum <- table(rep_sample$locale, rep_sample$district_size)
#slide title: "Our data represents the state with 95% confidence"
write.csv(sum, "rep_sample_numbers.csv")

 # meeting 2014 goals by district
goal_14_districts <- sum(rep_sample$goal_2014) / nrow(rep_sample)
# goals by student number; essentially districts weighed by num_students
goal_14_students <- sum(rep_sample$goal_2014 * rep_sample$num_students) / 
                    sum(rep_sample$num_students)
# goals by schools
goal_14_schools <- sum(rep_sample$goal_2014 * rep_sample$num_schools) /
                   sum(rep_sample$num_schools)

# meeting 2018 goals by district
goal_18_districts <- sum(rep_sample$goal_2018) / nrow(rep_sample)
# goals by student number; essentially districts weighed by num_students
goal_18_students <- sum(rep_sample$goal_2018 * rep_sample$num_students) / 
  sum(rep_sample$num_students)
# goals by schools
goal_18_schools <- sum(rep_sample$goal_2018 * rep_sample$num_schools) /
  sum(rep_sample$num_schools)

goal_2014_percents <- data.frame(goal_14_districts, goal_14_students, goal_14_schools)
goal_2018_percents <- data.frame(goal_18_districts, goal_18_students, goal_18_schools)

# write to csv for excel graphing
write.csv(goal_2014_percents, "goal_2014_percents.csv", row.names = FALSE)
write.csv(goal_2018_percents, "goal_2018_percents.csv", row.names = FALSE)

# meeting goals by the three IL regions/locale/district
# note: in deluxe districts table, ia_cost_per_mbps refers to annual cost, must be divided by 12
goals_by_region <- rep_sample %>%
                   group_by(il_region) %>%
                   summarise(goals = mean(goal_2014))

# goal - geography distribution
table(basic$locale, basic$district_size)

table(rep_sample[rep_sample$goal_2014 == 1, ]$locale, rep_sample[rep_sample$goal_2014 ==1 ,]$district_size)

# meeting the $3/mbps cost target?
rep_sample$meet_ia_cost_target <- ifelse(rep_sample$monthly_ia_cost_per_mbps <= 3, 1, 0)


#rep_sample %>%
 # group_by(goal_2014) %>%
  #summarize(median_cost = median(monthly_ia_cost_per_mbps),
   #         target_percent = mean(meet_ia_cost_target))

rep_sample %>%
 group_by(goal_2014) %>%
 summarize(median_cost = median(monthly_ia_cost_per_mbps),
        target_percent = mean(meet_ia_cost_target))

# WAN Connection analyses
wan_1g <- sum(rep_sample$gt_1g_wan_lines)
wan_all <- sum(rep_sample$gt_1g_wan_lines) + 
           sum(rep_sample$lt_1g_fiber_wan_lines) + 
           sum(rep_sample$lt_1g_nonfiber_wan_lines)
il_wan <- wan_1g / wan_all
# SotS Report figure
national <- 0.6
wan_data <- data.frame(il_wan, national, wan_all)
# export
write.csv(wan_data, "wan_greater_than_1g.csv", row.names = FALSE)

# export list of districts that did not fiel e-rate
#write.csv(basic)


# any salient characteristics about districts that did not file e-rate?
no_erate <- basic[basic$erate == 0, c("nces_cd", "name", "city", "zip")]
write.csv(no_erate, "districts_no_erate_1516.csv")

#71
table(basic[basic$erate == 0, ]$locale, basic[basic$erate == 0, ]$district_size)
# 44/71 are in rural districts
# 69/71 are small or tiny

View(basic[basic$erate == 0 & basic$district_size %in% c("Large", "Medium"),])


no_erate_map <-
  ggplot() + 
  geom_polygon(data = il_df, aes(x = long, y = lat, group = group), fill = "white") +
  geom_point(data = basic[basic$erate == 0, ], aes(x = longitude, y = latitude), color = "#fdb913", size = 3, alpha = 0.5) +
  #scale_color_manual(name = "", values = c("#4a4a4a", "#fdb913"), breaks = c(0, 1), labels = c("no e-rate", "e-rate")) +
  theme(panel.background = element_rect(fill = 'white', colour = 'white'),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  borders("county", colour="black", alpha = 0.5, size = 0.1, region = "illinois") +
  ggtitle("Districts that did not request E-Rate") +
  theme(plot.title = element_text(lineheight = .8, face = "bold")) +
  theme(legend.position = "bottom")


# WAN connections by region
wan_region <- rep_sample %>%
              group_by(il_region) %>%
              summarize(wan_totals = sum(gt_1g_wan_lines + 
                                           lt_1g_fiber_wan_lines + 
                                           lt_1g_nonfiber_wan_lines),
                        wan_1g = sum(gt_1g_wan_lines))

# fiber at campus level
# (known_scalable_campuses + assumed_scalable_campuses) / 
# (known_unscalable + assumed_unscalable_campuses + the first two)
scale <- sum(rep_sample$known_scalable_campuses + 
               rep_sample$assumed_scalable_campuses)
all <- scale + sum(rep_sample$known_unscalable_campuses + rep_sample$assumed_unscalable_campuses)

scale_data <- data.frame(scale / all, (all - scale) / all, all)
names(scale_data) <- c("Scalable", "Not Scalable", "Total")

# export
write.csv(scale_data, "schools_scalable.csv", row.names = FALSE)

unscalable_districts <- which(rep_sample$num_campuses == rep_sample$known_unscalable_campuses + rep_sample$assumed_unscalable_campuses)

table(rep_sample[unscalable_districts, ]$il_region)
table(rep_sample[unscalable_districts, ]$district_size)
table(rep_sample[unscalable_districts, ]$locale)
table(rep_sample[unscalable_districts, ]$district_size,
      rep_sample[unscalable_districts, ]$locale)


## fiber needs projection - export and input to Joan's workbok

no_fiber_districts <- rep_sample[rep_sample$hierarchy_connect_category != "Fiber", 
                                 c("esh_id", "num_students", "ia_oversub_ratio", 
                                   "ia_bandwidth_per_student", "goal_2014", 
                                   "hierarchy_connect_category")]

write.csv(no_fiber_districts, "no_fiber_districts.csv", row.names = FALSE)

# who requires WAN?
# districts that require WAN
requires_wan  <- 
  rep_sample%>%
  group_by(requires_wan, has_wan) %>%
  summarize(n = n())

requires_wan$perc <- requires_wan$n / nrow(rep_sample)

write.csv(rep_sample[rep_sample$requires_wan == 1 & rep_sample$has_wan == 0, ], "no_wan_requests.csv", row.names = FALSE)
